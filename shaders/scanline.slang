#version 450

#include "parameters.inc"
#include "signal_to_thickness.inc"

layout(push_constant) uniform Push {
    vec4 OutputSize;
    vec4 OriginalSize;
    vec4 SourceSize;
    vec4 ScanlineSignalSize;
    uint FrameCount;
    float SCANLINE_CENTER;
    float MIN_THICKNESS;
    float MAX_THICKNESS;
    float HARDNESS;
    float WIDENESS;
    float SPOT_GAMMA;
    float BLEEDING;
}
param;

layout(std140, set = 0, binding = 0) uniform UBO {
    mat4 MVP;
}
global;

#pragma stage vertex
layout(location = 0) in vec4 Position;
layout(location = 1) in vec2 TexCoord;
layout(location = 0) out vec2 vTexCoord;

void main() {
    gl_Position = global.MVP * Position;
    vTexCoord = TexCoord;
}

#pragma stage fragment
layout(location = 0) in vec2 vTexCoord;
layout(location = 0) out vec4 FragColor;
layout(set = 0, binding = 1) uniform sampler2D Source;

float power_gauss(float dx, float dy, float radius_x, float radius_y, float hardness) {
    return exp(
        -pow(dx * dx / (radius_x * radius_x + 1.e-8f) + dy * dy / (radius_y * radius_y + 1.e-8f),
             hardness));
}

// Inverts power_gauss to find dx at which output vanishes, i.e., falls below epsilon.
float iteration_limit(float dy, float radius_x, float radius_y, float hardness, float epsilon) {
    return radius_x * sqrt(pow(-log(epsilon), 1.0f / hardness) -
                               dy * dy / (radius_y * radius_y + 1.e-8f));
}

void sample_scanline(in vec2 unit_sample, in float unit_dy, in float min_thickness,
                     in float max_thickness, in float unit_sample_radius_x,
                     in float effective_hardness, in float gamma_exp, in sampler2D source,
                     inout vec3 res) {
    // Sub-pixel location within the scanline signal pass where the last sample was.
    // If the offset is above 1, we need to fetch another texture sample.
    // Add 1 to the initial value to trigger the first sample immediately.
    float signal_offset =
        fract((unit_sample.x - unit_sample_radius_x) * param.ScanlineSignalSize.x) + 1.0f;
    vec3 sample_color;
    vec3 spot_size;
    for (float unit_dx = -unit_sample_radius_x; unit_dx <= unit_sample_radius_x;
         unit_dx += param.OutputSize.z,
               signal_offset += param.ScanlineSignalSize.x * param.OutputSize.z) {
        if (signal_offset >= 1.0f) {
            sample_color = texture(source, vec2(unit_sample.x + unit_dx, unit_sample.y)).rgb;
            for (int c = 0; c < 3; ++c) {
                spot_size[c] =
                    signal_to_thickness(sample_color[c], min_thickness, max_thickness, gamma_exp);
            }
            signal_offset -= 1.0f;
        }
        for (int c = 0; c < 3; ++c) {
            const float w = power_gauss(unit_dx, unit_dy, spot_size[c] * param.WIDENESS,
                                        spot_size[c], effective_hardness);
            res[c] = max(res[c], mix(res[c], sample_color[c], w));
        }
    }
}

void main() {
    // Given as radius in unit pixel scaling, i.e., fraction of viewport size.
    const float min_thickness = param.MIN_THICKNESS * param.ScanlineSignalSize.w * 0.5f;
    const float max_thickness = param.MAX_THICKNESS * param.ScanlineSignalSize.w * 0.5f;
    // Use original size instead of scanline signal to avoid squeezing of beam shape.
    const float unit_radius_x = param.MAX_THICKNESS * param.OriginalSize.z * 0.5f * param.WIDENESS;
    const float effective_hardness = param.HARDNESS * param.HARDNESS * 10.0f + 1.0f;
    const float gamma_exp = exp(param.SPOT_GAMMA);

    vec3 res = vec3(0.0f, 0.0f, 0.0f);

    // Pass 1: Sample nearest scanline.  May be in a different one!
    // Pixel y coordinate in input pixel space, e.g., 13.0 for
    // vTexCoord.y * param.ScanlineSignalSize.y == 13.57.
    float scanline_tex_y_int;
    // Offset to scanline center in input pixel space, e.g., 0.07 for
    // vTexCoord.y * param.ScanlineSignalSize.y == 13.57 and scanline center == 0.5.
    const float offset_to_center =
        modf(vTexCoord.y * param.ScanlineSignalSize.y, scanline_tex_y_int) - param.SCANLINE_CENTER;
    // Integer offset to scanline y coordinate in input pixel space, e.g., -1, 0, or 1.
    const int nearest_scanline_offset = int(2.0f * offset_to_center);
    {
        // The scanline that will be sampled from.
        const float scanline_sample_y_int = scanline_tex_y_int + nearest_scanline_offset;
        // The distance between the current texel coordinate and the scanline center in unit
        // coordinates.
        const float unit_dy = vTexCoord.y - (scanline_sample_y_int + param.SCANLINE_CENTER) *
                                                param.ScanlineSignalSize.w;
        const float unit_sample_radius_x = iteration_limit(unit_dy, unit_radius_x, max_thickness,
                                                           effective_hardness, 1.0f / 256.0f);
        sample_scanline(
            vec2(vTexCoord.x, vTexCoord.y + nearest_scanline_offset * param.ScanlineSignalSize.w),
            unit_dy, min_thickness, max_thickness, unit_sample_radius_x, effective_hardness,
            gamma_exp, Source, res);
    }

    // Pass 2: Sample 2nd-nearest scanline.
    if (bool(param.BLEEDING)) {
        // The 2nd scanline that will be sampled. Relative to the direction from the current
        // coordinate to the nearest scanline, this goes into the opposite direction.
        const float scanline_sample_y_f =
            vTexCoord.y * param.ScanlineSignalSize.y +
            float(!bool(nearest_scanline_offset % 2)) * (offset_to_center >= 0.0f ? 1.0f : -1.0f);
        const float unit_dy = vTexCoord.y - (floor(scanline_sample_y_f) + param.SCANLINE_CENTER) *
                                                param.ScanlineSignalSize.w;
        const float unit_sample_radius_x = iteration_limit(unit_dy, unit_radius_x, max_thickness,
                                                           effective_hardness, 1.0f / 256.0f);
        sample_scanline(vec2(vTexCoord.x, scanline_sample_y_f * param.ScanlineSignalSize.w),
                        unit_dy, min_thickness, max_thickness, unit_sample_radius_x,
                        effective_hardness, gamma_exp, Source, res);
    }

    FragColor = vec4(res.r, res.g, res.b, 1.0f);
}
