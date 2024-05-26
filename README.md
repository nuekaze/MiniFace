# MiniFace
A VTuber tracker that focus on minimalism and simplicity.

[Send a drink if you liked it!](https://www.buymeacoffee.com/nuemedia)

The idea is that you prepare your model in either Blender or Unity. This includes bones, blendshapes and shaders.

So far I have only tested with my own models. Your model may not work.  
The tracker use hardcoded names for bones and blendshapes so if they not match it will not track.  
There are some "intelligence" to figure out the correct bones but it may not work.  
Your bones may also behave differently and look strange if they are rotated differently on your model.

## Tracking methods
The tracker currently only supports external ARKit trackers.
- VTube Studio (iPhone)
- MeowFace (Android) (Use VTube Studio option in tracker)
- [mediapipe-vt](https://github.com/nuekaze/mediapipe-vt) (webcam)

There are plans to make webcam trackers built in instead of being external.  
OpenSeeFace will not be implemented unless someone gives me code to convert the OSF format to vowels.

## Model preperation
This tracker supports the following formats.
- vrm
- glb
- gltf
- fbx
- blend