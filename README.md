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

There is a bug when you load a VRM model and the arm slider moves some random bone instead of the arms. If you restart the program it should fix itself.

If you use VRM, springbones will work as you configure them.

## How to run the latest
Easiest way to run the latest.
1. Download [Godot engine](https://godotengine.org/). (I try develop in the latest version always)
2. Download repo/files from this page using code button at the top. Extract if you download zip.
3. Open Godot and import project folder.
4. In menu you can now click "Run" to start it.

Right now I have no scroll for the menu so you just have to make the window taller to see all options if they are hidden.

## Good to know
Because I developed this for my own models, all ARKit blendshape names use lowercase first letter. If your model has uppercase first letters it will not work. To fix this you can remove line 108 in trackers/vtube-studio.gd. If you use mediapipe-vt, lowercase is the default. To fix that you can instead add that line after line 105 in trackers/mediapipe-vt.gd.

I will fix this at some point to make it work regardless of uppercase or lowercase.

## Future plans
- Automatically add spring bones on any bone named "hair", "tail", "skirt". (not for VRM)
- OSF support.
- Supply OSF and mediapipe-vt directly in the program without external setup.
- Native transparency instead of greenscreen. (This may already work in Windows. I have not tested it.)
