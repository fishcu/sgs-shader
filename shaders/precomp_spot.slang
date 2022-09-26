#version 450

layout(push_constant) uniform Push {
	vec4 OutputSize;
	vec4 OriginalSize;
	vec4 SourceSize;
	uint FrameCount;
    float HARDNESS;
    float WIDENESS;
} param;

layout(std140, set = 0, binding = 0) uniform UBO {
   mat4 MVP;
} global;

#pragma parameter HARDNESS "Hardness of the spot" 0.7 0.0 1.0 0.1
#pragma parameter WIDENESS "Shape wideness of the spot. 1 is a circle." 0.9 0.0 3.0 0.1

#pragma stage vertex
layout(location = 0) in vec4 Position;
layout(location = 1) in vec2 TexCoord;
layout(location = 0) out vec2 vTexCoord;

void main() {
    gl_Position = global.MVP * Position;
    vTexCoord = TexCoord;
}

#pragma stage fragment
#pragma format R32_SFLOAT
layout(location = 0) in vec2 vTexCoord;
layout(location = 0) out float FragColor;
layout(set = 0, binding = 1) uniform sampler2D Source;

float power_gauss(float dx, float dy, float radius_x, float radius_y, float hardness) {
    return exp(-(pow(dx * dx / (radius_x * radius_x + 1.e-8f) + dy * dy / (radius_y * radius_y + 1.e-8f), hardness)));
}

void main() {
    const float x_scale = 2.0f * max(1.0f, param.WIDENESS);
    const float y_scale = x_scale * param.OutputSize.y * param.OutputSize.z;
    const float effective_hardness = param.HARDNESS * param.HARDNESS * 10.0f + 1.0f;
    FragColor = power_gauss(vTexCoord.x * x_scale, vTexCoord.y * y_scale, param.WIDENESS, 1.0f, effective_hardness);
}
