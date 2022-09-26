#version 450

layout(push_constant) uniform Push {
	vec4 OutputSize;
	vec4 OriginalSize;
	vec4 SourceSize;
	uint FrameCount;
    float ERODE_WIDTH;
} param;

layout(std140, set = 0, binding = 0) uniform UBO {
   mat4 MVP;
} global;

#pragma parameter ERODE_WIDTH "ERODE_WIDTH: Erosion width in pixels" 0.5 0.0 2.0 0.05

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

void main() {
    const vec2 source_to_output_scale = param.OutputSize.xy * param.SourceSize.zw;
    const float erosion_radius_f = param.ERODE_WIDTH * source_to_output_scale.x * 0.5f;
    const int erosion_radius = int(erosion_radius_f);

    vec4 res = texture(Source, vTexCoord);
    for(int i = -erosion_radius; i < erosion_radius + int(fract(erosion_radius_f) > 0.5f); ++i) {
        res = min(res, texture(Source, vTexCoord + vec2((i) * param.OutputSize.z, 0.0f)));
    }

    FragColor = res;
}
