#version 450

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

#pragma parameter SCANLINE_CENTER "SCANLINE_CENTER: Scanline vertical position within the pixel." 0.55 0.0 1.0 0.01
#pragma parameter MIN_THICKNESS "MIN_THICKNESS: Scanline thickness of dark pixels." 0.1 0.0 1.4 0.01
#pragma parameter MAX_THICKNESS "MAX_THICKNESS: Scanline thickness of bright pixels." 0.9 0.0 1.4 0.01
#pragma parameter HARDNESS "HARDNESS: Hardness of the spot." 0.5 0.0 2.0 0.05
#pragma parameter WIDENESS "WIDENESS: Shape wideness of the spot. 1 is a circle." 0.95 0.0 3.0 0.05
#pragma parameter SPOT_GAMMA "SPOT_GAMMA: Shape spot size curve. Affects brightness." 0.0 -3.0 3.0 0.1
#pragma parameter BLEEDING "BLEEDING: Allow scanlines to bleed into each other." 1.0 0.0 1.0 1.0

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

#define _OVERSHOOT_MAX_SIZE 1.3f

float power_gauss(float dx, float dy, float radius_x, float radius_y, float hardness) {
    return exp(-pow(dx * dx / (radius_x * radius_x + 1.e-8f) + dy * dy / (radius_y * radius_y + 1.e-8f), hardness));
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
        inout vec4 res) {
    const float d_thickness = max_thickness - min_thickness;
    for(int sample_x_offset_px = -x_sample_radius; sample_x_offset_px <= x_sample_radius; ++sample_x_offset_px) {
        const float dx_px = sample_x_offset_px;
        const vec4 sample_color = vec4(texture(source,
            vec2(x_coord + dx_px * x_px_to_norm_scale, sample_y_coord)).rgb, 1.0f);
        for(int c = 0; c < 3; ++c) {
            const float spot_size = min_thickness + d_thickness * (sample_color[c] > 1.0 ? sample_color[c] : pow(sample_color[c], gamma_exp));
            const float w = power_gauss(dx_px, dy_px, spot_size * param.WIDENESS, spot_size, effective_hardness);
            res[c] = max(res[c], res[c] * (1.0f - w) + sample_color[c] * w);
        }
    }
}

void main() {
    const vec2 source_to_output_scale = param.OutputSize.xy * param.SourceSize.zw;
    const float min_thickness = param.MIN_THICKNESS * source_to_output_scale.y * 0.5f;
    const float max_thickness = param.MAX_THICKNESS * source_to_output_scale.y * 0.5f;
    const float scanline_offset = param.SCANLINE_CENTER * param.SourceSize.w;
    const float effective_hardness = param.HARDNESS * param.HARDNESS * 10.0f + 1.0f;
    const float gamma_exp = exp(param.SPOT_GAMMA);

    vec4 res = vec4(0.0f, 0.0f, 0.0f, 1.0f);

    // Scales for going from number of pixels in output space to normalized coordinates in
    // the lookup table (source space + undo vertical stretching).
    const float x_scale = 1.0f / (2.0f * max(1.0f, param.WIDENESS));
    const float y_scale = x_scale;

    // Pass 1: Sample nearest scanline.  May be in a different one!
    const float current_scanline = vTexCoord.y * param.SourceSize.y;
    const float offset_to_center = fract(current_scanline) - param.SCANLINE_CENTER;
    const int nearest_scanline_offset = int(2.0f * offset_to_center);
    {
        const float sample_scanline_px = current_scanline + nearest_scanline_offset;
        const float dy_px = vTexCoord.y * param.OutputSize.y
            - (int(sample_scanline_px) + param.SCANLINE_CENTER)* source_to_output_scale.y;
        const int x_sample_radius = int(iteration_limit(dy_px,
                                                        max_thickness * param.WIDENESS * _OVERSHOOT_MAX_SIZE,
                                                        max_thickness * _OVERSHOOT_MAX_SIZE,
                                                        effective_hardness,
                                                        1.0f / 64.0f));
        sample_scanline(sample_scanline_px * param.SourceSize.w, min_thickness, max_thickness, dy_px,
                        x_sample_radius, Source, vTexCoord.x, param.SourceSize.z, effective_hardness, gamma_exp, res);
    }

    // Pass 2: Sample 2nd-nearest scanline.
    if(bool(param.BLEEDING)) {
        const float sample_scanline_px = current_scanline
            + float(!bool(nearest_scanline_offset % 2)) * (offset_to_center >= 0.0f ? 1.0f : -1.0f);
        const float dy_px = vTexCoord.y * param.OutputSize.y
            - (int(sample_scanline_px) + param.SCANLINE_CENTER)* source_to_output_scale.y;
        const int x_sample_radius = int(iteration_limit(dy_px,
                                                        max_thickness * param.WIDENESS * _OVERSHOOT_MAX_SIZE,
                                                        max_thickness * _OVERSHOOT_MAX_SIZE,
                                                        effective_hardness,
                                                        1.0f / 64.0f));
        sample_scanline(sample_scanline_px * param.SourceSize.w, min_thickness, max_thickness, dy_px,
                        x_sample_radius, Source, vTexCoord.x, param.SourceSize.z, effective_hardness, gamma_exp, res);
    }

    FragColor = res;
}
