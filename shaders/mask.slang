#version 450

layout(push_constant) uniform Push {
	vec4 OutputSize;
	vec4 OriginalSize;
	vec4 SourceSize;
	uint FrameCount;
    float PIXEL_WIDTH;
    float WIRE_WIDTH;
    float GRILLE_FOCUS;

    float MASK_TYPE;
} param;

#pragma parameter PIXEL_WIDTH "PIXEL_WIDTH: Distance between successive pixels." 4.0 4.0 50.0 0.5
#pragma parameter WIRE_WIDTH "WIRE_WIDTH: Width of the grille wire, rendered as black." 1.0 0.0 20.0 0.05
#pragma parameter GRILLE_FOCUS "GRILLE_FOCUS: Sharpness of lines at the phosphor level." 2.0 0.0 2.0 0.05

#pragma parameter MASK_TYPE "mask type" 0.0 0.0 24.0 1.0

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

#include "subpixel_masks.h"

void main() {
    FragColor = texture(Source, vTexCoord);
    float alpha;
    FragColor.rgb *= mask_weights_alpha(vTexCoord * param.OutputSize.xy, 1.0, int(param.MASK_TYPE), alpha);
    // FragColor.rgb /= alpha;
}

/*
float power_gauss(float dx, float radius_x, float hardness) {
    return exp(-pow(dx * dx / (radius_x * radius_x + 1.e-8f), hardness));
}

void main() {
    const float channel_width = (param.PIXEL_WIDTH - param.WIRE_WIDTH) / 3.0f;

    // Where the center of the phosphor of each color is.
    // This is also used as the sampling location.
    const vec3 channel_offsets = vec3(channel_width * 0.5f,
                                      channel_width * 1.5f,
                                      channel_width * 2.5f);
    const float effective_hardness = param.GRILLE_FOCUS * param.GRILLE_FOCUS * 10.0f + 1.0f;

    const int pixel_x = int(vTexCoord.x * param.SourceSize.x);
    const int coord_grille_index = int(pixel_x / param.PIXEL_WIDTH);

    // Sample 3 nearest slots per channel, so 3 * 3 = 9 samples total
    for(int c = 0; c < 3; ++c) {
        FragColor[c] = 0.0f;
        for(int i = -1; i <= 1; ++i) {
            const float phosphor_center = float(coord_grille_index + i) * param.PIXEL_WIDTH + channel_offsets[c];
            const vec4 s = texture(Source, vec2(phosphor_center * param.SourceSize.z, vTexCoord.y));
            const float w = power_gauss(pixel_x + 0.5f - phosphor_center, channel_width * 0.8, effective_hardness);
            FragColor[c] += s[c] * w;
        }
    }

    FragColor[3] = 1.0f;
}
*/
