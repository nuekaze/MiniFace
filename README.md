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
- iFacialMocap (iPhone)

There are plans to make webcam trackers built in instead of being external.

## Model preperation
This tracker supports the following formats.
- vrm
- glb
- gltf
- fbx (maybe works)
- blend (maybe works)

If you use VRM, springbones will work as you configure them.

### Secondary model
You can a secondary model that will track just as the main model. This can be useful if you have multiple clothes you want switch between.

## How to run the latest
Easiest way to run the latest.
1. Download [Godot engine](https://godotengine.org/). (I try develop in the latest version always)
2. Download repo/files from this page using code button at the top. Extract if you download zip.
3. Open Godot and import project folder.
4. In menu you can now click "Run" to start it.

Right now I have no scroll for the menu so you just have to make the window taller to see all options if they are hidden.

## Future plans
- Automatically add spring bones on any bone named "hair", "tail", "skirt". (not for VRM)
- Supply mediapipe-vt directly in the program without external setup.
- Native transparency instead of greenscreen. (Already works in Windows. Changing project settings makes it work on Linux as well.)

OSF is scrapped. Instead I will try implement an ARKit to vowels conversion method. For webcam you can use mediapipe-vt for this.
