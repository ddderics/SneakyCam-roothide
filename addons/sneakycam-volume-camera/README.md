# SneakyCam Volume Camera

This RootHide addon uses the existing SneakyCam recorder and its preferences. Install SneakyCam first.

## Buttons

- Double Volume Up starts front-camera video when idle.
- Double Volume Up stops a current recording.
- Double Volume Down starts rear-camera video when idle.
- Double Volume Down does nothing while recording.

Each start sets Video Quality to 4K (3840x2160) and Frame Rate to 60 FPS. The addon disables SneakyCam's built-in volume-button actions so its original double-down photo action cannot conflict. Other SneakyCam settings and activators are left in place.

Enable tweak injection for SpringBoard in the RootHide Bootstrap app. Install the addon package, then respring.

The addon depends on SneakyCam because the camera recorder is provided by that package. The CameraDevice, VideoQuality, FrameRate, and UseVolumeButtons preference keys are used by SneakyCam 2.0.7.
