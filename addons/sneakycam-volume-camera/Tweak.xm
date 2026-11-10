#import <UIKit/UIKit.h>
#import <CoreFoundation/CoreFoundation.h>
#import <objc/message.h>
#import <objc/runtime.h>

@interface SpringBoard : UIApplication
@end

static CFStringRef const kSneakyCamDomain = CFSTR("com.spark.SneakyCam");
static CFStringRef const kSneakyCamChanged = CFSTR("com.spark.SneakyCam");
static CFTimeInterval sLastVolumeUpPress = 0;
static CFTimeInterval sLastVolumeDownPress = 0;
static BOOL sActionPending = NO;

static void QSSetPreference(CFStringRef key, CFPropertyListRef value) {
    CFPreferencesSetAppValue(key, value, kSneakyCamDomain);
}

static void QSApplyCaptureDefaults(void) {
    QSSetPreference(CFSTR("VideoEnabled"), kCFBooleanTrue);
    QSSetPreference(CFSTR("VideoQuality"), CFSTR("AVCaptureSessionPreset3840x2160"));
    QSSetPreference(CFSTR("FrameRate"), CFSTR("60"));
    QSSetPreference(CFSTR("UseVolumeButtons"), kCFBooleanFalse);
    CFPreferencesAppSynchronize(kSneakyCamDomain);
    CFNotificationCenterPostNotification(
        CFNotificationCenterGetDarwinNotifyCenter(),
        kSneakyCamChanged,
        NULL,
        NULL,
        true
    );
}

static id QSRecorder(void) {
    Class recorderClass = objc_getClass("SparkRecorder");
    SEL sharedInstance = sel_registerName("sharedInstance");
    if (!recorderClass || ![recorderClass respondsToSelector:sharedInstance]) {
        return nil;
    }
    return ((id (*)(id, SEL))objc_msgSend)(recorderClass, sharedInstance);
}

static BOOL QSRecorderFlag(id recorder, const char *selectorName) {
    SEL selector = sel_registerName(selectorName);
    if (!recorder || ![recorder respondsToSelector:selector]) {
        return NO;
    }
    return ((BOOL (*)(id, SEL))objc_msgSend)(recorder, selector);
}

static void QSToggleRecorder(id recorder) {
    SEL selector = sel_registerName("toggleRecording");
    if (recorder && [recorder respondsToSelector:selector]) {
        ((void (*)(id, SEL))objc_msgSend)(recorder, selector);
    }
}

static void QSHandleDoublePress(BOOL volumeUp) {
    if (!NSThread.isMainThread) {
        dispatch_async(dispatch_get_main_queue(), ^{
            QSHandleDoublePress(volumeUp);
        });
        return;
    }

    if (sActionPending) {
        return;
    }

    id recorder = QSRecorder();
    if (!recorder) {
        NSLog(@"[SneakyCamVolumeCamera] SparkRecorder is not loaded; install and enable SneakyCam injection in SpringBoard.");
        return;
    }

    BOOL recording = QSRecorderFlag(recorder, "isRecording");
    BOOL starting = QSRecorderFlag(recorder, "isStarting");
    if (starting) {
        return;
    }

    if (recording) {
        if (volumeUp) {
            sActionPending = YES;
            QSToggleRecorder(recorder);
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.35 * NSEC_PER_SEC)),
                           dispatch_get_main_queue(), ^{
                sActionPending = NO;
            });
        }
        return;
    }

    QSSetPreference(CFSTR("CameraDevice"),
                    volumeUp ? CFSTR("AVCaptureDevicePositionFront")
                             : CFSTR("AVCaptureDevicePositionBack"));
    QSApplyCaptureDefaults();
    sActionPending = YES;

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.15 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        id currentRecorder = QSRecorder();
        if (currentRecorder &&
            !QSRecorderFlag(currentRecorder, "isRecording") &&
            !QSRecorderFlag(currentRecorder, "isStarting")) {
            QSToggleRecorder(currentRecorder);
        }
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.35 * NSEC_PER_SEC)),
                       dispatch_get_main_queue(), ^{
            sActionPending = NO;
        });
    });
}

static void QSHandleHardwarePress(UIPressesEvent *event) {
    CFTimeInterval now = CFAbsoluteTimeGetCurrent();
    for (UIPress *press in event.allPresses) {
        if (press.force <= 0) {
            continue;
        }

        NSInteger type = (NSInteger)press.type;
        if (type == 102) {
            if (sLastVolumeUpPress > 0 && now - sLastVolumeUpPress <= 0.40) {
                sLastVolumeUpPress = 0;
                QSHandleDoublePress(YES);
            } else {
                sLastVolumeUpPress = now;
            }
        } else if (type == 103) {
            if (sLastVolumeDownPress > 0 && now - sLastVolumeDownPress <= 0.40) {
                sLastVolumeDownPress = 0;
                QSHandleDoublePress(NO);
            } else {
                sLastVolumeDownPress = now;
            }
        }
    }
}

%hook SpringBoard
- (BOOL)_handlePhysicalButtonEvent:(UIPressesEvent *)event {
    QSHandleHardwarePress(event);
    return %orig;
}
%end

%ctor {
    @autoreleasepool {
        %init;
        QSApplyCaptureDefaults();
    }
}
