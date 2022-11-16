// More samples means fewer artifacts but decreased performance.
// The upper limit that does not crash RetroArch is 64.
#define _BLUR_KERNEL_SIZE 64

float gauss(float t, float sigma) {
    return exp(-t * t / (sigma * sigma + 1.e-8f));
}

float gauss_with_overshoot(float x, float main_sigma, float overshoot_strength) {
    return gauss(x, main_sigma) - gauss(x - main_sigma*0.8, main_sigma * 0.5) * overshoot_strength;
}

void compute_blur_kernel(out vec4 blur_kernel[_BLUR_KERNEL_SIZE / 4], float blur_width, float overshoot_strength) {
    // Calculate kernel.
    // Sensible iteration radius is about 1.6 sigmas from the center.
    const float iteration_radius = 1.6f * blur_width;

    float kernel_sum = 0.0f;
    for(int i = 0; i < _BLUR_KERNEL_SIZE; ++i) {
        const float x = iteration_radius * (float(i) / (_BLUR_KERNEL_SIZE - 1) * 2.0f - 1.0f);
        // Invert the output index to have a simpler convolution iteration in the fragment shader.
        const int outer = (_BLUR_KERNEL_SIZE - i - 1) / 4;
        const int inner = (_BLUR_KERNEL_SIZE - i - 1) % 4;
        blur_kernel[outer][inner] = gauss_with_overshoot(x, blur_width, overshoot_strength);
        kernel_sum += blur_kernel[outer][inner];
    }

    if (kernel_sum > 1.e-8f) {
        for(int i = 0; i < _BLUR_KERNEL_SIZE; ++i) {
            const int outer = i / 4;
            const int inner = i % 4;
            blur_kernel[outer][inner] /= kernel_sum;
        }
    } else {
        // If kernel sum is near zero, set kernel to impulse (identity convolution)
        for(int i = 0; i < _BLUR_KERNEL_SIZE; ++i) {
            const int outer = i / 4;
            const int inner = i % 4;
            blur_kernel[outer][inner] = 0.0f;
        }
        const int idx = _BLUR_KERNEL_SIZE / 2;
        const int outer = idx / 4;
        const int inner = idx % 4;
        blur_kernel[outer][inner]  = 1.0f;
    }
}
