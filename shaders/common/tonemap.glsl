// tonemap.glsl — 色调映射
#ifndef TONEMAP_GLSL
#define TONEMAP_GLSL

// Uncharted 2 色调映射
vec3 uncharted2Tonemap(vec3 color) {
    float A = 0.15;
    float B = 0.50;
    float C = 0.10;
    float D = 0.20;
    float E = 0.02;
    float F = 0.30;
    return ((color * (A * color + C * B) + D * E) / (color * (A * color + B) + D * F)) - E / F;
}

vec3 acesTonemap(vec3 color) {
    float a = 2.51;
    float b = 0.03;
    float c = 2.43;
    float d = 0.59;
    float e = 0.14;
    return clamp((color * (a * color + b)) / (color * (c * color + d) + e), 0.0, 1.0);
}

// 简单曝光 + 色调映射
vec3 applyExposure(vec3 color, float exposure) {
    return acesTonemap(color * exposure);
}

#endif
