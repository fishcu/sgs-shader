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
| _Shader disabled_  | Input images.                        |
![](assets/settings/orig_crono.jpg?raw=true " ")
![](assets/settings/orig_link.jpg?raw=true " ")
![](assets/settings/orig_ness.jpg?raw=true " ")
![](assets/settings/orig_sonic.jpg?raw=true " ") |                 |
| Hardness           | How hard the contour of the spot is. | soft           | hard            |
| Min. thickness     | How thick dark parts are rendered.   | minthin        | minthick        |
| Max. thickness     | How thick bright parts are rendered. | mthin          | mthick          |
| Wideness           | Aspect ratio of the beam.            | narrow         | wide            |
| Blur width         | Strength of horizontal blur.         | sharp          | blurry          |
| Overshoot strength | Overshoot & sharpening strength.     | nons           | sharpened       |
| Erode width        | Extends darker areas.                | nerod          | eroded          |
