#version 450

#include "parameters.inc"
#include "signal_to_thickness.inc"

#define _GAUSS_LUT_SIZE 64
#define LUT_AT(lut, idx) (lut[(idx) / 4][(idx) % 4])

layout(push_constant) uniform Push {
    vec4 OutputSize;
    vec4 OriginalSize;
    vec4 SourceSize;
    uint FrameCount;
    float SCANLINE_CENTER;
    float MIN_THICKNESS;
    float MAX_THICKNESS;
    float HARDNESS;
    float WIDENESS;
    float SPOT_GAMMA;
    float BLEEDING;
} param;

layout(std140, set = 0, binding = 0) uniform UBO {
    mat4 MVP;
} global;

#pragma stage vertex
layout(location = 0) in vec4 Position;
layout(location = 1) in vec2 TexCoord;
layout(location = 0) out vec2 vTexCoord;
layout(location = 2) out vec2 lut_extrema;
layout(location = 4) out vec4 gauss_lut[_GAUSS_LUT_SIZE / 4];

void main() {
    gl_Position = global.MVP * Position;
    vTexCoord = TexCoord;
    lut_extrema[0] = 0.0f;
    lut_extrema[1] = 4.0f;
    for(int i = 0; i < _GAUSS_LUT_SIZE; ++i) {
        const float x = float(i) / (_GAUSS_LUT_SIZE - 1) * (lut_extrema[1] - lut_extrema[0]) + lut_extrema[0];
        LUT_AT(gauss_lut, i) = exp(-pow(x, 5.225f));
    }
}

#pragma stage fragment
layout(location = 0) in vec2 vTexCoord;
layout(location = 2) in vec2 lut_extrema;
layout(location = 4) flat in vec4 gauss_lut[_GAUSS_LUT_SIZE / 4];
layout(location = 0) out vec4 FragColor;
layout(set = 0, binding = 1) uniform sampler2D Source;

#define _OVERSHOOT_MAX_SIZE 1.3f

float power_gauss(float dx, float dy, float radius_x, float radius_y, float hardness) {
    return exp(-pow(dx * dx / (radius_x * radius_x + 1.e-8f) + dy * dy / (radius_y * radius_y + 1.e-8f), hardness));
    // return dx * dx / (radius_x * radius_x + 1.e-8f) + dy * dy / (radius_y * radius_y + 1.e-8f) > 1.0f ? 0.0f : 1.0f;
}

// Inverts power_gauss to find dx at which output vanishes
float iteration_limit(float dy, float radius_x, float radius_y, float hardness, float epsilon) {
    return radius_x * sqrt(pow(-log(epsilon), 1.0f / hardness) - dy * dy / (radius_y * radius_y + 1.e-8f));
}

void sample_scanline(
        float sample_y_coord,
        float min_thickness,
        float max_thickness,
        float dy_px,
        int x_sample_radius,
        sampler2D source,
        float x_coord,
        float x_px_to_norm_scale,
        float effective_hardness,
        float gamma_exp,
        inout vec3 res,
        in vec2 lut_extrema,
        in vec4 gauss_lut[_GAUSS_LUT_SIZE / 4]) {
    for(int sample_x_offset_px = -x_sample_radius; sample_x_offset_px <= x_sample_radius; ++sample_x_offset_px) {
        const float dx_px = sample_x_offset_px;
        const vec3 sample_color = texture(source,
            vec2(x_coord + dx_px * x_px_to_norm_scale, sample_y_coord)).rgb;
        for(int c = 0; c < 3; ++c) {
            const float spot_size = signal_to_thickness(sample_color[c], min_thickness, max_thickness, gamma_exp);
            
            const float x = clamp(dx_px * dx_px / (spot_size * param.WIDENESS * spot_size * param.WIDENESS + 1.e-8f)
                                    + dy_px * dy_px / (spot_size * spot_size + 1.e-8f),
                                  lut_extrema[0], lut_extrema[1]);
            const float idx = mix(0, _GAUSS_LUT_SIZE - 2, (x - lut_extrema[0]) / (lut_extrema[1] - lut_extrema[0]));
            const float w = mix(LUT_AT(gauss_lut, int(idx)), LUT_AT(gauss_lut, int(idx) + 1), fract(idx));
            
            // const float w = power_gauss(dx_px, dy_px, spot_size * param.WIDENESS, spot_size, effective_hardness);

            res[c] = max(res[c], mix(res[c], sample_color[c], w));
        }
    }
}

void main() {
    const vec2 source_to_output_scale = param.OutputSize.xy * param.SourceSize.zw;
    const float min_thickness = param.MIN_THICKNESS * source_to_output_scale.y * 0.5f;
    const float max_thickness = param.MAX_THICKNESS * source_to_output_scale.y * 0.5f;
    const float effective_hardness = param.HARDNESS * param.HARDNESS * 10.0f + 1.0f;
    const float gamma_exp = exp(param.SPOT_GAMMA);

    vec3 res = vec3(0.0f, 0.0f, 0.0f);

    // Pass 1: Sample nearest scanline.  May be in a different one!
    const float current_scanline = vTexCoord.y * param.SourceSize.y;
    const float offset_to_center = fract(current_scanline) - param.SCANLINE_CENTER;
    const int nearest_scanline_offset = int(2.0f * offset_to_center);
    {
        const float sample_scanline_px = current_scanline + nearest_scanline_offset;
        const float dy_px = vTexCoord.y * param.OutputSize.y
            - (int(sample_scanline_px) + param.SCANLINE_CENTER) * source_to_output_scale.y;
        const int x_sample_radius = int(iteration_limit(dy_px,
                                                        max_thickness * param.WIDENESS * _OVERSHOOT_MAX_SIZE,
                                                        max_thickness * _OVERSHOOT_MAX_SIZE,
                                                        effective_hardness,
                                                        1.0f / 64.0f));
        sample_scanline(vTexCoord.y + nearest_scanline_offset * param.SourceSize.w, min_thickness, max_thickness, dy_px,
                        x_sample_radius, Source, vTexCoord.x, param.SourceSize.z, effective_hardness, gamma_exp, res,
                        lut_extrema, gauss_lut);
    }

    // Pass 2: Sample 2nd-nearest scanline.
    if(param.BLEEDING > 0.5f) {
        const float sample_scanline_px = current_scanline
            + float(!bool(nearest_scanline_offset % 2)) * (offset_to_center >= 0.0f ? 1.0f : -1.0f);
        const float dy_px = vTexCoord.y * param.OutputSize.y
            - (int(sample_scanline_px) + param.SCANLINE_CENTER) * source_to_output_scale.y;
        const int x_sample_radius = int(iteration_limit(dy_px,
                                                        max_thickness * param.WIDENESS * _OVERSHOOT_MAX_SIZE,
                                                        max_thickness * _OVERSHOOT_MAX_SIZE,
                                                        effective_hardness,
                                                        1.0f / 64.0f));
        sample_scanline(sample_scanline_px * param.SourceSize.w, min_thickness, max_thickness, dy_px,
                        x_sample_radius, Source, vTexCoord.x, param.SourceSize.z, effective_hardness, gamma_exp, res,
                        lut_extrema, gauss_lut);
    }

    FragColor = vec4(res.r, res.g, res.b, 1.0f);
}
