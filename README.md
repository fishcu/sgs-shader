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
Download or clone this repository. 

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
| Erode width        | Extends darker areas.                | ![](assets/settings/nerod_crono.jpg?raw=true " ")![](assets/settings/nerod_link.jpg?raw=true " ")![](assets/settings/nerod_ness.jpg?raw=true " ")![](assets/settings/nerod_sonic.jpg?raw=true " ")          | ![](assets/settings/eroded_crono.jpg?raw=true " ")![](assets/settings/eroded_link.jpg?raw=true " ")![](assets/settings/eroded_ness.jpg?raw=true " ")![](assets/settings/eroded_sonic.jpg?raw=true " ")          |
