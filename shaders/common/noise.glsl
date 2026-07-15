// noise.glsl — fBM 噪声函数
#ifndef NOISE_GLSL
#define NOISE_GLSL

// fBM 2D — 用于云层
float fbm2D(vec2 p, int octaves) {
    float value = 0.0;
    float amplitude = 0.5;
    float frequency = 1.0;
    for (int i = 0; i < octaves; i++) {
        value += amplitude * noise2D(p * frequency);
        frequency *= 2.0;
        amplitude *= 0.5;
    }
    return value;
}

// fBM 3D — 用于动态云漂移
float fbm3D(vec3 p, int octaves) {
    float value = 0.0;
    float amplitude = 0.5;
    float frequency = 1.0;
    for (int i = 0; i < octaves; i++) {
        value += amplitude * noise3D(p * frequency);
        frequency *= 2.0;
        amplitude *= 0.5;
    }
    return value;
}

// Domain warping — 更自然的云形状
float fbmWarp(vec2 p, int octaves) {
    vec2 q = vec2(fbm2D(p, octaves), fbm2D(p + vec2(5.2, 1.3), octaves));
    return fbm2D(p + 4.0 * q, octaves);
}

#endif
