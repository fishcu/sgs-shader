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
int iteration_limit(float dy, float radius_x, float radius_y, float hardness, float epsilon) {
    return int(radius_x * sqrt(pow(-log(epsilon), 1.0f / hardness) -
                               dy * dy / (radius_y * radius_y + 1.e-8f)));
}

void sample_scanline(in vec2 viewport_sample, in float viewport_dy, in float min_thickness,
                     in float max_thickness, in float viewport_sample_x_radius,
                     in float effective_hardness, in float gamma_exp, in sampler2D source,
                     inout vec3 res) {
    for (float viewport_dx = -viewport_sample_x_radius; viewport_dx <= viewport_sample_x_radius;
         viewport_dx += 1.0) {
        const vec3 sample_color =
            texture(source,
                    vec2(viewport_sample.x + viewport_dx * param.OutputSize.z, viewport_sample.y))
                .rgb;
        for (int c = 0; c < 3; ++c) {
            const float spot_size =
                signal_to_thickness(sample_color[c], min_thickness, max_thickness, gamma_exp);
            const float w = power_gauss(viewport_dx, viewport_dy, spot_size * param.WIDENESS,
                                        spot_size, effective_hardness);
            res[c] = max(res[c], mix(res[c], sample_color[c], w));
        }
    }
    /*
// Sample at the current pixel -- closest dx is simply zero.
{
const vec3 sample_color = texture(source, vec2(viewport_sample.x, viewport_sample.y)).rgb;
const float viewport_dx = 0.0f;
for (int c = 0; c < 3; ++c) {
const float spot_size =
signal_to_thickness(sample_color[c], min_thickness, max_thickness, gamma_exp);
const float w = power_gauss(viewport_dx, viewport_dy, spot_size * param.WIDENESS,
                    spot_size, effective_hardness);
res[c] = max(res[c], mix(res[c], sample_color[c], w));
// res[c] = max(res[c], sample_color[c] * w);
}
}

// Samples to the left of this pixel are sampled as far right as possible for maximum effect.
const float step = param.ScanlineSignalSize.z;
for (float dx = -viewport_sample_x_radius * param.OutputSize.z; dx < 0.0f; dx += step) {
const float sample_x = viewport_sample.x + dx;
const vec3 sample_color = texture(source, vec2(sample_x, viewport_sample.y)).rgb;
const float viewport_dx =
param.OutputSize.x * (viewport_sample.x - ceil(sample_x * param.ScanlineSignalSize.x) *
                                      param.ScanlineSignalSize.z);
for (int c = 0; c < 3; ++c) {
const float spot_size =
signal_to_thickness(sample_color[c], min_thickness, max_thickness, gamma_exp);
const float w = power_gauss(viewport_dx, viewport_dy, spot_size * param.WIDENESS,
                    spot_size, effective_hardness);
res[c] = max(res[c], mix(res[c], sample_color[c], w));
// res[c] = max(res[c], sample_color[c] * w);
}
}
// Samples to the right of this pixel are sampled as far left as possible.
for (float dx = viewport_sample_x_radius * param.OutputSize.z; dx > 0.0f; dx -= step) {
const float sample_x = viewport_sample.x + dx;
const vec3 sample_color = texture(source, vec2(sample_x, viewport_sample.y)).rgb;
const float viewport_dx =
param.OutputSize.x *
(floor(sample_x * param.ScanlineSignalSize.x) * param.ScanlineSignalSize.z -
viewport_sample.x);
for (int c = 0; c < 3; ++c) {
const float spot_size =
signal_to_thickness(sample_color[c], min_thickness, max_thickness, gamma_exp);
const float w = power_gauss(viewport_dx, viewport_dy, spot_size * param.WIDENESS,
                    spot_size, effective_hardness);
res[c] = max(res[c], mix(res[c], sample_color[c], w));
// res[c] = max(res[c], sample_color[c] * w);
}
}
*/
}

void main() {
    // How many pixels there are in the output per pixels in the input.
    const vec2 orig_to_viewport_scale = param.OutputSize.xy * param.OriginalSize.zw;
    // Gives as radius in viewport pixel scaling.
    const float min_thickness = param.MIN_THICKNESS * orig_to_viewport_scale.y * 0.5f;
    const float max_thickness = param.MAX_THICKNESS * orig_to_viewport_scale.y * 0.5f;
    const float effective_hardness = param.HARDNESS * param.HARDNESS * 10.0f + 1.0f;
    const float gamma_exp = exp(param.SPOT_GAMMA);

    vec3 res = vec3(0.0f, 0.0f, 0.0f);

    // Pass 1: Sample nearest scanline.  May be in a different one!
    // Pixel y coordinate in input pixel space, e.g., 13.0 for
    // vTexCoord.y * param.OriginalSize.y == 13.57.
    float scanline_tex_y_int;
    // Offset to scanline center in input pixel space, e.g., 0.07 for
    // vTexCoord.y * param.OriginalSize.y == 13.57 and scanline center == 0.5.
    const float offset_to_center =
        modf(vTexCoord.y * param.OriginalSize.y, scanline_tex_y_int) - param.SCANLINE_CENTER;
    // Integer offset to scanline y coordinate in input pixel space, e.g., -1, 0, or 1.
    const int nearest_scanline_offset = int(2.0f * offset_to_center);
    {
        // The scanline that will be sampled from.
        const float scanline_sample_y_int = scanline_tex_y_int + nearest_scanline_offset;
        // The distance between the current texel coordinate and the scanline center in viewport
        // coordinates.
        const float viewport_dy =
            vTexCoord.y * param.OutputSize.y -
            (scanline_sample_y_int + param.SCANLINE_CENTER) * orig_to_viewport_scale.y;
        const float viewport_sample_x_radius = iteration_limit(
            viewport_dy, param.MAX_THICKNESS * orig_to_viewport_scale.x * 0.5f * param.WIDENESS,
            max_thickness, effective_hardness, 1.0f / 256.0f);
        sample_scanline(
            vec2(vTexCoord.x, vTexCoord.y + nearest_scanline_offset * param.OriginalSize.w),
            viewport_dy, min_thickness, max_thickness, viewport_sample_x_radius, effective_hardness,
            gamma_exp, Source, res);
    }

    // Pass 2: Sample 2nd-nearest scanline.
    if (bool(param.BLEEDING)) {
        // The 2nd scanline that will be sampled. Relative to the direction from the current
        // coordinate to the nearest scanline, this goes into the opposite direction.
        const float scanline_sample_y_f =
            vTexCoord.y * param.SourceSize.y +
            float(!bool(nearest_scanline_offset % 2)) * (offset_to_center >= 0.0f ? 1.0f : -1.0f);
        const float viewport_dy =
            vTexCoord.y * param.OutputSize.y -
            (floor(scanline_sample_y_f) + param.SCANLINE_CENTER) * orig_to_viewport_scale.y;
        const float viewport_sample_x_radius = iteration_limit(
            viewport_dy, param.MAX_THICKNESS * orig_to_viewport_scale.x * 0.5f * param.WIDENESS,
            max_thickness, effective_hardness, 1.0f / 256.0f);
        sample_scanline(vec2(vTexCoord.x, scanline_sample_y_f * param.OriginalSize.w),
                        viewport_dy, min_thickness, max_thickness, viewport_sample_x_radius,
                        effective_hardness, gamma_exp, Source, res);
    }

    FragColor = vec4(res.r, res.g, res.b, 1.0f);
}
