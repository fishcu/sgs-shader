// clang-format off
#pragma parameter SGS_SETTINGS "=== Simply Good Scanlines v1.3 settings ===" 0.0 0.0 1.0 1.0

#pragma parameter SCANLINE_SETTINGS "= Scanline settings =" 0.0 0.0 1.0 1.0
#pragma parameter MIN_THICKNESS "  MIN_THICKNESS: Scanline thickness of dark pixels." 0.3 0.0 1.4 0.01
#pragma parameter MAX_THICKNESS "  MAX_THICKNESS: Scanline thickness of bright pixels." 0.8 0.0 1.4 0.01
#pragma parameter HARDNESS "  HARDNESS: Hardness of the spot." 0.5 0.0 2.0 0.05
#pragma parameter SPOT_GAMMA "  SPOT_GAMMA: Shape spot size curve. Affects brightness." -0.6 -3.0 3.0 0.1
#pragma parameter WIDENESS "  WIDENESS: Shape wideness of the spot. 1 is a circle." 1.2 0.00000001 3.0 0.05
#pragma parameter SCANLINE_CENTER "  SCANLINE_CENTER: Vertical position within the pixel." 0.6 0.0 1.0 0.01
#pragma parameter BLEEDING "  BLEEDING: Allow scanlines to bleed into each other." 1.0 0.0 1.0 1.0

#pragma parameter MASK_SETTINGS "= Mask settings =" 0.0 0.0 1.0 1.0
#pragma parameter MASK_STRENGTH "  MASK_STRENGTH: Controls opaqueness of mask." 0.0 0.0 1.0 0.01
#pragma parameter MASK_FINENESS "  MASK_FINENESS: From coarse to fine." 0.5 0.0 1.0 0.01
#pragma parameter MASK_BRIGHTNESS "  MASK_BRIGHTNESS: Controls percentage of lit pixels." 0.5 0.0 1.0 0.05
#pragma parameter MASK_BLUR "  MASK_BLUR: Mask blur width. Relative to mask fineness." 0.0 0.0 1.0 0.05
#pragma parameter MASK_PATTERN_SIZE "  MASK_PATTERN_SIZE: Cycle length of mask pattern." 48.0 2.0 64.0 1.0
#pragma parameter MASK_ENABLE_SUBPIXELS "  MASK_ENABLE_SUBPIXELS: Apply at the subpixel level." 0.0 0.0 1.0 1.0

#pragma parameter IMAGE_SETTINGS "= Image Processing settings =" 0.0 0.0 1.0 1.0
#pragma parameter EROSION_WIDTH "  EROSION_WIDTH: Erosion width in pixels." 0.5 0.0 2.0 0.05
#pragma parameter BLUR_WIDTH "  BLUR_WIDTH: Input horizontal blur width in pixels." 0.14 0.0 2.0 0.02
#pragma parameter OVERSHOOT_STRENGTH "  OVERSHOOT_STRENGTH: Overshooting & sharpening strength." 0.8 0.0 1.0 0.05

#pragma parameter COLOR_SETTINGS "= Color settings =" 0.0 0.0 1.0 1.0
#pragma parameter BLACK_POINT "  BLACK_POINT: Output brightness of black input" 0.01 0.0 1.0 0.01
#pragma parameter OUTPUT_GAMMA "  OUTPUT_GAMMA: Output gamma correction." 2.8 1.0 5.0 0.1

#pragma parameter RCAS_SETTINGS "= RCA Sharpening settings =" 0.0 0.0 1.0 1.0
#pragma parameter RCAS_STRENGTH "  RCAS_STRENGTH: Strength of RCA sharpening." 0.0 0.0 1.1 0.05
#pragma parameter RCAS_DENOISE "  RCAS_DENOISE: Suppress luma oversharpening." 1.0 0.0 1.0 1.0
// clang-format on
