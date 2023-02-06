#version 450

#include "parameters.slang"
#include "signal_to_thickness.slang"

layout(push_constant) uniform Push {
    vec4 OutputSize;
    vec4 OriginalSize;
    vec4 SourceSize;
    uint FrameCount;
    float MIN_THICKNESS;
    float MAX_THICKNESS;
    float SPOT_GAMMA;
    float SCANLINE_CENTER;
    float MASK_PATTERN_SIZE;
    float MASK_FINENESS;
    float MASK_BRIGHTNESS;
    float MASK_STRENGTH;
    float MASK_ENABLE_SUBPIXELS;
}
param;

#define MAX_MASK_PATTERN_SIZE 64

layout(std140, set = 0, binding = 0) uniform UBO {
    mat4 MVP;
}
global;

#pragma stage vertex
layout(location = 0) in vec4 Position;
layout(location = 1) in vec2 TexCoord;
layout(location = 0) out vec2 vTexCoord;
layout(location = 1) out vec4[MAX_MASK_PATTERN_SIZE / 4] mask;

void generate_mask_pattern(out vec4[MAX_MASK_PATTERN_SIZE / 4] mask, int length, float fineness,
                           float brightness) {
    // Number of groups is in [1, length / 2]
    const int num_groups = int(mix(1, length / 2, fineness));
    // const int num_groups = int(fineness);
    // Num active pixels is between 1 per group,
    // and filling all pixels except gaps between groups
    const int tot_num_active = int(mix(num_groups, length - num_groups, brightness));

    // Bresenham-style algorithm
    int accum_error = -length;
    int active_accum_error = -tot_num_active;
    for (int i = 0; i < length; ++i) {
        if (accum_error >= 0) {
            accum_error -= length;
            active_accum_error -= tot_num_active;
        }
        accum_error += num_groups;
        if (active_accum_error < 0 && accum_error < 0) {
            mask[i / 4][i % 4] = 1.0;
            active_accum_error += num_groups;
        } else {
            mask[i / 4][i % 4] = 0.05 * (1.0 - param.MASK_STRENGTH);
        }
    }
}

void main() {
    gl_Position = global.MVP * Position;
    vTexCoord = TexCoord;
    generate_mask_pattern(mask, int(param.MASK_PATTERN_SIZE), param.MASK_FINENESS,
                          param.MASK_BRIGHTNESS);
}

#pragma stage fragment
layout(location = 0) in vec2 vTexCoord;
layout(location = 1) in vec4[MAX_MASK_PATTERN_SIZE / 4] mask;
layout(location = 0) out vec4 FragColor;
layout(set = 0, binding = 1) uniform sampler2D Source;

float attenuate(float val, float offset_to_center, float radius) {
    return pow(val, param.MASK_STRENGTH * (0.8 + param.MASK_STRENGTH * offset_to_center *
                                                     offset_to_center * 80.0 * radius));
}

void main() {
    FragColor = texture(Source, vTexCoord);
    if (param.MASK_STRENGTH < 1.0e-3f) {
        return;
    }

    const vec2 orig_to_viewport_scale = param.OutputSize.xy * param.OriginalSize.zw;
    // Pixel y coordinate in input pixel space, e.g., 13.0 for
    // vTexCoord.y * param.OriginalSize.y == 13.57.
    float scanline_tex_y_int;
    // Offset to scanline center in input pixel space, e.g., 0.07 for
    // vTexCoord.y * param.OriginalSize.y == 13.57 and scanline center == 0.5.
    float offset_to_center =
        abs(modf(vTexCoord.y * param.OriginalSize.y, scanline_tex_y_int) - param.SCANLINE_CENTER);
    if (offset_to_center > 0.5) {
        offset_to_center = abs(offset_to_center - 1.0);
    }
    const vec3 scanline_signal =
        texture(Source, vec2(vTexCoord.x,
                             (floor(vTexCoord.y * param.OriginalSize.y) + param.SCANLINE_CENTER) *
                                 orig_to_viewport_scale.y))
            .rgb;

    const int coord_x = int(vTexCoord.x * param.OutputSize.x);
    const int pattern_size = int(param.MASK_PATTERN_SIZE);

    const float min_radius = param.MIN_THICKNESS * 0.5;
    const float max_radius = param.MAX_THICKNESS * 0.5;
    const float gamma_exp = exp(param.SPOT_GAMMA);
    if (bool(param.MASK_ENABLE_SUBPIXELS)) {
        const int idx[3] = { (coord_x * 3 + 0) % pattern_size, (coord_x * 3 + 1) % pattern_size,
                             (coord_x * 3 + 2) % pattern_size };
        for (int c = 0; c < 3; ++c) {
            FragColor[c] *= attenuate(
                mask[idx[c] / 4][idx[c] % 4], offset_to_center,
                signal_to_thickness(scanline_signal[c], min_radius, max_radius, gamma_exp));
        }
    } else {
        const int idx = coord_x % pattern_size;
        for (int c = 0; c < 3; ++c) {
            FragColor[c] *= attenuate(
                mask[idx / 4][idx % 4], offset_to_center,
                signal_to_thickness(scanline_signal[c], min_radius, max_radius, gamma_exp));
        }
    }
}
