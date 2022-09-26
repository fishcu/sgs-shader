![Logo](assets/logo.png?raw=true "Logo")

Scanline shader for RetroArch.

# Motivation
The motivation for this shader comes from when I tried a native 240p @ 120 Hz resolution on my PC CRT.
The black gaps were way too thick!

Instead of showing a native resolution, I wanted to send high-quality and configurable scanlines to the CRT monitor.
This would give me all other effects like blooming, shadow masks, etc., for free!

# Goals
The purpose of this shader is to render painterly, high-resolution scanlines.

It should be intuitive and easy to configure while still allowing reasonable control over the final look.

The implementation follows what is aesthetically pleasing, not what is physically accurate.

## What it won't do
The goal of this shader is not to replace shaders that fully simulate CRT displays like CRT-royale or other similar shaders.

As such, there are no plans to add curvature, vignetting, halation, etc., effects.

# How to install and use
Download or clone this repository. For example, have a look at the [releases](https://github.com/fishcu/sgs-shader/releases) page.

In RetroArch, when a core is running, go to the Quick Menu (standard hotkey: F1), Shaders -> Load Shader Preset.
Load any of the available presets.

If you like to run the shader by default when opening the core, you can set it permanently by going to the Quick Menu -> Overrides -> Save Core Overrides.

## What to do if performance is slow
Despite some optimization efforts, the shader is quite heavy for higher-resolution content. It runs well for 480p and lower resolution content on a laptop GTX 1060.
However, it might still be too heavy in certain scenarios. You can do the following to increase performance, in decreasing order of impact:

- Choose a lower-resolution preset. The default of 9x9 outputs a 4k vertical resolution image for 240p input.
- TODO: Implement! Turn off scanline bleeding. This reduces the number of samples for each pixel dramatically.
- Any setting that decreases the spot size will increase the performance: Increase hardness, decrease thicknesses, or decrease wideness.
- TODO: Add! Switch to a preset that operates in sRGB space directly instead of linear space, marked with "nolin_". This decreases the quality of blending somewhat and gains some minimal performance.

# Settings overview
These settings can be changed in the menu at Shaders -> Shader Parameters after loading a preset.

The table below shows each setting's effect when set to a low and when set to a high setting.

| **Setting name**   | Description                          | **Set to low** | **Set to high** |
|--------------------|--------------------------------------|----------------|-----------------|
| _Shader disabled_  | Input images.                        |![](assets/settings/orig_crono.jpg?raw=true " ")![](assets/settings/orig_link.jpg?raw=true " ")![](assets/settings/orig_ness.jpg?raw=true " ")![](assets/settings/orig_sonic.jpg?raw=true " ") |                 |
| Hardness           | How hard the contour of the spot is. | ![](assets/settings/soft_crono.jpg?raw=true " ")![](assets/settings/soft_link.jpg?raw=true " ")![](assets/settings/soft_ness.jpg?raw=true " ")![](assets/settings/soft_sonic.jpg?raw=true " ")           | ![](assets/settings/hard_crono.jpg?raw=true " ")![](assets/settings/hard_link.jpg?raw=true " ")![](assets/settings/hard_ness.jpg?raw=true " ")![](assets/settings/hard_sonic.jpg?raw=true " ")            |
| Min. thickness     | How thick dark parts are rendered.   | ![](assets/settings/minthin_crono.jpg?raw=true " ")![](assets/settings/minthin_link.jpg?raw=true " ")![](assets/settings/minthin_ness.jpg?raw=true " ")![](assets/settings/minthin_sonic.jpg?raw=true " ")        | ![](assets/settings/minthick_crono.jpg?raw=true " ")![](assets/settings/minthick_link.jpg?raw=true " ")![](assets/settings/minthick_ness.jpg?raw=true " ")![](assets/settings/minthick_sonic.jpg?raw=true " ")        |
| Max. thickness     | How thick bright parts are rendered. | ![](assets/settings/mthin_crono.jpg?raw=true " ")![](assets/settings/mthin_link.jpg?raw=true " ")![](assets/settings/mthin_ness.jpg?raw=true " ")![](assets/settings/mthin_sonic.jpg?raw=true " ")          | ![](assets/settings/mthick_crono.jpg?raw=true " ")![](assets/settings/mthick_link.jpg?raw=true " ")![](assets/settings/mthick_ness.jpg?raw=true " ")![](assets/settings/mthick_sonic.jpg?raw=true " ")          |
| Wideness           | Aspect ratio of the beam.            | ![](assets/settings/narrow_crono.jpg?raw=true " ")![](assets/settings/narrow_link.jpg?raw=true " ")![](assets/settings/narrow_ness.jpg?raw=true " ")![](assets/settings/narrow_sonic.jpg?raw=true " ")         | ![](assets/settings/wide_crono.jpg?raw=true " ")![](assets/settings/wide_link.jpg?raw=true " ")![](assets/settings/wide_ness.jpg?raw=true " ")![](assets/settings/wide_sonic.jpg?raw=true " ")            |
| Blur width         | Strength of horizontal blur.         | ![](assets/settings/sharp_crono.jpg?raw=true " ")![](assets/settings/sharp_link.jpg?raw=true " ")![](assets/settings/sharp_ness.jpg?raw=true " ")![](assets/settings/sharp_sonic.jpg?raw=true " ")          | ![](assets/settings/blurry_crono.jpg?raw=true " ")![](assets/settings/blurry_link.jpg?raw=true " ")![](assets/settings/blurry_ness.jpg?raw=true " ")![](assets/settings/blurry_sonic.jpg?raw=true " ")          |
| Overshoot strength | Overshoot & sharpening strength.     | ![](assets/settings/nons_crono.jpg?raw=true " ")![](assets/settings/nons_link.jpg?raw=true " ")![](assets/settings/nons_ness.jpg?raw=true " ")![](assets/settings/nons_sonic.jpg?raw=true " ")           | ![](assets/settings/sharpened_crono.jpg?raw=true " ")![](assets/settings/sharpened_link.jpg?raw=true " ")![](assets/settings/sharpened_ness.jpg?raw=true " ")![](assets/settings/sharpened_sonic.jpg?raw=true " ")       |
| Erode width        | Horizontally widens darker areas.                | ![](assets/settings/nerod_crono.jpg?raw=true " ")![](assets/settings/nerod_link.jpg?raw=true " ")![](assets/settings/nerod_ness.jpg?raw=true " ")![](assets/settings/nerod_sonic.jpg?raw=true " ")          | ![](assets/settings/erod_crono.jpg?raw=true " ")![](assets/settings/erod_link.jpg?raw=true " ")![](assets/settings/erod_ness.jpg?raw=true " ")![](assets/settings/erod_sonic.jpg?raw=true " ")          |

# Full-size screenshots
All of these screenshots use default shader parameters.

![](assets/screenshots/alttp.jpg?raw=true " ")
![](assets/screenshots/alttp_2.jpg?raw=true " ")
![](assets/screenshots/chrono_trigger.jpg?raw=true " ")
![](assets/screenshots/dkc.jpg?raw=true " ")
![](assets/screenshots/sf2.jpg?raw=true " ")
![](assets/screenshots/sm.jpg?raw=true " ")
![](assets/screenshots/starfox.jpg?raw=true " ")
![](assets/screenshots/yoshis_island.jpg?raw=true " ")
