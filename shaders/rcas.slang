#version 450

#include "parameters.slang"

layout(push_constant) uniform Push {
    vec4 OutputSize;
    vec4 OriginalSize;
    vec4 SourceSize;
    uint FrameCount;
    float RCAS_STRENGTH;
    float RCAS_DENOISE;
} param;

layout(std140, set = 0, binding = 0) uniform UBO {
    mat4 MVP;
} global;

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

// Implementation and documentation largely follows:
// - https://github.com/GPUOpen-Effects/FidelityFX-FSR/blob/master/ffx-fsr/ffx_fsr1.h#L602
// - https://www.shadertoy.com/view/7tfSWH

// RCAS is based on the following logic.
// RCAS uses a 5 tap filter in a cross pattern (same as CAS),
//    w                n
//  w 1 w  for taps  w m e 
//    w                s
// Where 'w' is the negative lobe weight.
//  output = (w*(n+e+w+s)+m)/(4*w+1)
// RCAS solves for 'w' by seeing where the signal might clip out of the {0 to 1} input range,
//  0 == (w*(n+e+w+s)+m)/(4*w+1) -> w = -m/(n+e+w+s)
//  1 == (w*(n+e+w+s)+m)/(4*w+1) -> w = (1-m)/(n+e+w+s-4*1)
// Then chooses the 'w' which results in no clipping, limits 'w', and multiplies by the 'sharp' amount.
// This solution above has issues with MSAA input as the steps along the gradient cause edge detection issues.
// So RCAS uses 4x the maximum and 4x the minimum (depending on equation)in place of the individual taps.
// As well as switching from 'm' to either the minimum or maximum (depending on side), to help in energy conservation.
// This stabilizes RCAS.
// RCAS does a simple highpass which is normalized against the local contrast then shaped,
//       0.25
//  0.25  -1  0.25
//       0.25
// This is used as a noise detection filter, to reduce the effect of RCAS on grain, and focus on real edges.

// This is set at the limit of providing unnatural results for sharpening.
#define RCAS_LIMIT (0.25f - (1.0f / 16.0f))

void main() {
    const vec4 offset = vec4(1, 0, 1, -1) * param.SourceSize.zzww;
    const vec3 sample_n = texture(Source, vTexCoord + offset.yz).rgb;
    const vec3 sample_w = texture(Source, vTexCoord - offset.xy).rgb;
    const vec3 sample_m = texture(Source, vTexCoord).rgb;
    const vec3 sample_e = texture(Source, vTexCoord + offset.xy).rgb;
    const vec3 sample_s = texture(Source, vTexCoord + offset.yw).rgb;

    const vec3 max_edges = max(max(sample_n, sample_s), max(sample_e, sample_w));
    const vec3 min_edges = min(min(sample_n, sample_s), min(sample_e, sample_w));
    const vec3 sum_edges = sample_n + sample_e + sample_s + sample_w;
    const vec3 edge = -0.25f * min(min_edges / max_edges, (1.0f - max_edges) / (1.0f - min_edges));
    const float edges = clamp(max(edge.r, max(edge.g, edge.b)), -RCAS_LIMIT, 0.0f);
    float w = edges * param.RCAS_STRENGTH;
    
    if(param.RCAS_DENOISE > 0.5f) {
        // Luma times 2.
        const float luma_n = 0.5f * (sample_n.b + sample_n.r) + sample_n.g;
        const float luma_w = 0.5f * (sample_w.b + sample_w.r) + sample_w.g;
        const float luma_m = 0.5f * (sample_m.b + sample_m.r) + sample_m.g;
        const float luma_e = 0.5f * (sample_e.b + sample_e.r) + sample_e.g;
        const float luma_s = 0.5f * (sample_s.b + sample_s.r) + sample_s.g;
        // Noise detection.
        float nz = 0.25f * (luma_n + luma_w + luma_e + luma_s) - luma_m;
        nz = clamp(abs(nz) / (max(max(max(max(luma_n, luma_w), luma_m), luma_e), luma_s)
                            - min(min(min(min(luma_n, luma_w), luma_m), luma_e), luma_s)), 0.0f, 1.0f);
        nz = 1.0 - 0.5 * nz;
        // Apply noise removal.
        w *= nz;
    }

    vec3 col = (sample_m + sum_edges * w) / (w * 4.0f + 1.0f);
    col = clamp(col, vec3(0.0f, 0.0f, 0.0f), vec3(1.0f, 1.0f, 1.0f));

    FragColor = vec4(col, 1.0f);
}
