// random.glsl — 哈希与随机函数
#ifndef RANDOM_GLSL
#define RANDOM_GLSL

// 1D → 1D hash
float hash1(float p) {
    p = fract(p * 0.1031);
    p *= p + 33.33;
    p *= p + p;
    return fract(p);
}

// 2D → 1D hash
float hash1(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

// 2D → 2D hash
vec2 hash2(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * vec3(0.1031, 0.1030, 0.0973));
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.xx + p3.yz) * p3.zy);
}

// 3D → 1D hash
float hash1(vec3 p) {
    p = fract(p * 0.1031);
    p += dot(p, p.zyx + 31.32);
    return fract((p.x + p.y) * p.z);
}

// Simplex 2D 噪声辅助
float noise2D(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    float a = hash1(i);
    float b = hash1(i + vec2(1.0, 0.0));
    float c = hash1(i + vec2(0.0, 1.0));
    float d = hash1(i + vec2(1.0, 1.0));
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

// 3D 噪声
float noise3D(vec3 p) {
    vec3 i = floor(p);
    vec3 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    float a = hash1(i);
    float b = hash1(i + vec3(1.0, 0.0, 0.0));
    float c = hash1(i + vec3(0.0, 1.0, 0.0));
    float d = hash1(i + vec3(1.0, 1.0, 0.0));
    float e = hash1(i + vec3(0.0, 0.0, 1.0));
    float f_ = hash1(i + vec3(1.0, 0.0, 1.0));
    float g = hash1(i + vec3(0.0, 1.0, 1.0));
    float h = hash1(i + vec3(1.0, 1.0, 1.0));
    float mix1 = mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
    float mix2 = mix(mix(e, f_, f.x), mix(g, h, f.x), f.y);
    return mix(mix1, mix2, f.z);
}

#endif
