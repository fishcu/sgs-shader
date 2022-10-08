![Logo](assets/logo.png?raw=true "Logo")

Scanline shader for RetroArch.

# Motivation
The motivation for this shader comes from when I tried a native 240p @ 120 Hz resolution on my PC CRT.
The black gaps were way too thick!

Instead of showing the native resolution 240p picture, I wanted to send high-quality and configurable scanlines to the CRT monitor.
This would give me all other effects like blooming, shadow masks, etc., for free!

![](assets/photos/native.jpg?raw=true " ")![](assets/photos/shader.jpg?raw=true " ")

# Goals
The purpose of this shader is to render painterly, high-resolution scanlines, as if drawn with a perfectly uniform airbrush.

![](assets/scanlines.png?raw=true " ")

It should be intuitive and easy to configure while still allowing reasonable control over the final look.

The implementation follows what is aesthetically pleasing, not what is physically accurate.

## What it won't do
The goal of this shader is not to replace shaders that fully simulate CRT displays like CRT-royale or other similar shaders.

As such, there are no plans to add curvature, vignetting, halation, etc., effects.

# How to install and use
Download or clone this repository. The latest stable release can be downloaded on the [releases](https://github.com/fishcu/sgs-shader/releases) page.

In RetroArch, when a core is running, go to the Quick Menu (standard hotkey: F1), Shaders -> Load Shader Preset.
Load any of the available presets.

**Note**: Slang shaders such as this one will only show up with the `vulkan`, `glcore`, and `d3d12` video drivers.
If you are using the `gl` driver, which is the default on Linux distributions, make sure to switch to the `vulkan` or `glcore` drivers!

If you like to run the shader by default when opening the core, you can set it permanently by going to the Quick Menu -> Shaders -> Save Core Preset.

## Presets explained
The following presets are available:
- sgs_DEFAULT: The default preset. Optimized for 240p resolution content on 4k displays. However, it will also work for other input and output resolutions ("freescale" behavior).
- sgs_force_320x240: This samples the input at a fixed resolution of 320 x 240 pixels. Can be used with higher resolution content to achieve a 240p look.
- sgs_potato_pc: Same as the default preset, but renders at a lower internal resolution. This should be used if the default preset runs too slow on your computer.
- sgs_super_high_res: Same as the default preset, but renders at a much higher resolution. Ideal for running on beefy computers or 8k resolution displays, or for rendering small sprites. May crash on older GPUs that do not support large textures.

## Ensuring sharp scaling
Make sure to have the following parameters set in the video settings for the best video quality:
- Settings -> Video -> Scaling -> Integer Scale ON
- Settings -> Video -> Scaling -> Aspect Ratio Custom. Then, scale up the "Custom Aspect Ratio (Height)" to fill your screen (e.g., 9x for 240p content on a 4k display). Then, scale up the "Custom Aspect Ratio (Width)" to match the height and to achieve a proper aspect ratio. For example, the SNES has an aspect ratio of 8:7. If choosing a 9x vertical resolution of 2016 for SNES content, the horizontal resolution should be 2016 * 8 / 7 = 2304.

## What to do if performance is slow
Despite some optimization efforts, the shader is quite heavy for higher-resolution content. It runs well for 480p and lower resolution content on a laptop GTX 1060.
However, it might still be too heavy in certain scenarios. You can do the following to increase performance, in decreasing order of impact:

- Switch to the "potato PC" preset. This will render at 5x5 the input resolution instead of the default 9x9. This runs at several thousand FPS even for higher-resolution cores on my laptop GTX 1060.
- Turn off scanline bleeding. This reduces the number of samples for each pixel dramatically.
- Any setting that decreases the spot size will increase the performance: Increase hardness, decrease thicknesses, or decrease wideness.

# Settings overview
These settings can be changed in the menu at Shaders -> Shader Parameters after loading a preset.

The table below shows each setting's effect when set to a low and when set to a high setting.

| **Setting name**   | Description                          | **Set to low** | **Set to high** |
|--------------------|--------------------------------------|----------------|-----------------|
| _Shader disabled_  | Input images.                        |![](assets/settings/orig_crono.jpg?raw=true " ")![](assets/settings/orig_link.jpg?raw=true " ")![](assets/settings/orig_ness.jpg?raw=true " ")![](assets/settings/orig_sonic.jpg?raw=true " ") |                 |
| Hardness           | How hard the contour of the spot is. | ![](assets/settings/soft_crono.jpg?raw=true " ")![](assets/settings/soft_link.jpg?raw=true " ")![](assets/settings/soft_ness.jpg?raw=true " ")![](assets/settings/soft_sonic.jpg?raw=true " ")           | ![](assets/settings/hard_crono.jpg?raw=true " ")![](assets/settings/hard_link.jpg?raw=true " ")![](assets/settings/hard_ness.jpg?raw=true " ")![](assets/settings/hard_sonic.jpg?raw=true " ")            |
| Min. thickness     | How thick dark parts are rendered.   | ![](assets/settings/minthin_crono.jpg?raw=true " ")![](assets/settings/minthin_link.jpg?raw=true " ")![](assets/settings/minthin_ness.jpg?raw=true " ")![](assets/settings/minthin_sonic.jpg?raw=true " ")        | ![](assets/settings/minthick_crono.jpg?raw=true " ")![](assets/settings/minthick_link.jpg?raw=true " ")![](assets/settings/minthick_ness.jpg?raw=true " ")![](assets/settings/minthick_sonic.jpg?raw=true " ")        |
| Max. thickness     | How thick bright parts are rendered. | ![](assets/settings/mthin_crono.jpg?raw=true " ")![](assets/settings/mthin_link.jpg?raw=true " ")![](assets/settings/mthin_ness.jpg?raw=true " ")![](assets/settings/mthin_sonic.jpg?raw=true " ")          | ![](assets/settings/mthick_crono.jpg?raw=true " ")![](assets/settings/mthick_link.jpg?raw=true " ")![](assets/settings/mthick_ness.jpg?raw=true " ")![](assets/settings/mthick_sonic.jpg?raw=true " ")          |
| Spot gamma     | Controls spot thickness's tendency towards thinner or thicker sizes. | ![](assets/settings/lowg_crono.jpg?raw=true " ")![](assets/settings/lowg_link.jpg?raw=true " ")![](assets/settings/lowg_ness.jpg?raw=true " ")![](assets/settings/lowg_sonic.jpg?raw=true " ")          | ![](assets/settings/highg_crono.jpg?raw=true " ")![](assets/settings/highg_link.jpg?raw=true " ")![](assets/settings/highg_ness.jpg?raw=true " ")![](assets/settings/highg_sonic.jpg?raw=true " ")          |
| Wideness           | Aspect ratio of the beam.            | ![](assets/settings/narrow_crono.jpg?raw=true " ")![](assets/settings/narrow_link.jpg?raw=true " ")![](assets/settings/narrow_ness.jpg?raw=true " ")![](assets/settings/narrow_sonic.jpg?raw=true " ")         | ![](assets/settings/wide_crono.jpg?raw=true " ")![](assets/settings/wide_link.jpg?raw=true " ")![](assets/settings/wide_ness.jpg?raw=true " ")![](assets/settings/wide_sonic.jpg?raw=true " ")            |
| Blur width         | Strength of horizontal blur.         | ![](assets/settings/sharp_crono.jpg?raw=true " ")![](assets/settings/sharp_link.jpg?raw=true " ")![](assets/settings/sharp_ness.jpg?raw=true " ")![](assets/settings/sharp_sonic.jpg?raw=true " ")          | ![](assets/settings/blurry_crono.jpg?raw=true " ")![](assets/settings/blurry_link.jpg?raw=true " ")![](assets/settings/blurry_ness.jpg?raw=true " ")![](assets/settings/blurry_sonic.jpg?raw=true " ")          |
| Overshoot strength | Overshoot & sharpening strength. Allows the spot size to go beyond the maximum thickness momentarily at the start of a bright part of the scanline.    | ![](assets/settings/nons_crono.jpg?raw=true " ")![](assets/settings/nons_link.jpg?raw=true " ")![](assets/settings/nons_ness.jpg?raw=true " ")![](assets/settings/nons_sonic.jpg?raw=true " ")           | ![](assets/settings/sharpened_crono.jpg?raw=true " ")![](assets/settings/sharpened_link.jpg?raw=true " ")![](assets/settings/sharpened_ness.jpg?raw=true " ")![](assets/settings/sharpened_sonic.jpg?raw=true " ")       |
| Erode width        | Horizontally widens darker areas. Can be used to achieve equal width of bright and dark pixels. This is for example important for text readability.                | ![](assets/settings/nerod_crono.jpg?raw=true " ")![](assets/settings/nerod_link.jpg?raw=true " ")![](assets/settings/nerod_ness.jpg?raw=true " ")![](assets/settings/nerod_sonic.jpg?raw=true " ")          | ![](assets/settings/erod_crono.jpg?raw=true " ")![](assets/settings/erod_link.jpg?raw=true " ")![](assets/settings/erod_ness.jpg?raw=true " ")![](assets/settings/erod_sonic.jpg?raw=true " ")          |
| Scanline bleeding        | Allows scanlines to bleed into each other. Necessary for softer spots to be rendered correctly. Turning off provides a big performance boost.          | ![](assets/settings/nobleed_crono.jpg?raw=true " ")![](assets/settings/nobleed_link.jpg?raw=true " ")![](assets/settings/nobleed_ness.jpg?raw=true " ")![](assets/settings/nobleed_sonic.jpg?raw=true " ")          | ![](assets/settings/bleed_crono.jpg?raw=true " ")![](assets/settings/bleed_link.jpg?raw=true " ")![](assets/settings/bleed_ness.jpg?raw=true " ")![](assets/settings/bleed_sonic.jpg?raw=true " ")          |
| Scanline center        | Sub-pixel alignment of the scanline. This can control scanline sharpness when rendering at lower resolutions.          | ![](assets/settings/center1.jpg?raw=true " ")         | ![](assets/settings/center2.jpg?raw=true " ")          |

# Full-size screenshots
All of these screenshots use default shader parameters.

![](assets/screenshots/alttp.png?raw=true " ")
![](assets/screenshots/alttp_2.png?raw=true " ")
![](assets/screenshots/chrono_trigger.png?raw=true " ")
![](assets/screenshots/dkc.png?raw=true " ")
![](assets/screenshots/sf2.png?raw=true " ")
![](assets/screenshots/sm.png?raw=true " ")
![](assets/screenshots/starfox.png?raw=true " ")
![](assets/screenshots/yoshis_island.png?raw=true " ")

# Photos
These have been photographed off of my own CRT. 

![](assets/photos/dkc2.jpg?raw=true " ")
![](assets/photos/dkc1.jpg?raw=true " ")
![](assets/photos/sm1.jpg?raw=true " ")
![](assets/photos/sm2.jpg?raw=true " ")
![](assets/photos/sm3.jpg?raw=true " ")
![](assets/photos/sd2.jpg?raw=true " ")
![](assets/photos/fr1.jpg?raw=true " ")
![](assets/photos/fr2.jpg?raw=true " ")
