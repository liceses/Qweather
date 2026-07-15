// lighting.glsl — 太阳/月亮光晕 + 星星
#ifndef LIGHTING_GLSL
#define LIGHTING_GLSL

#include "math.glsl"
#include "random.glsl"

// 太阳光晕: 位置 + 颜色 + 大小
vec3 sunGlow(vec2 uv, vec2 sunPos, vec3 sunColor, float size) {
    float dist = distance(uv, sunPos);
    float glow = exp(-dist * dist * 2.0 / (size * size));
    return sunColor * glow;
}

// 月亮光晕: 位置 + 大小
vec3 moonGlow(vec2 uv, vec2 moonPos, float size) {
    float dist = distance(uv, moonPos);
    float glow = exp(-dist * dist * 2.0 / (size * size));
    return vec3(0.9, 0.95, 1.0) * glow * 0.6;
}

// 月相 SDF: 基于 phase (0=新, 4=满, 8=残)
float moonPhaseSDF(vec2 uv, vec2 moonPos, float moonRadius, float phase) {
    vec2 p = uv - moonPos;
    float base = length(p) - moonRadius;
    if (base > 0.0) return base; // 在月亮外

    // 月相裁剪: phase 0~8, 0=全暗, 4=全亮, 8=全暗
    float angle = phase * PI / 4.0;
    float cosAngle = cos(angle);
    // 水平裁剪
    float clipDist = p.x * cosAngle + moonRadius * (1.0 - abs(cosAngle)) * 0.5;
    return max(base, cosAngle > 0.0 ? clipDist : -clipDist);
}

// 星星: 固定位置 + 闪烁 (starVisibility 控制亮度)
vec3 starField(vec2 uv, float time, float starVisibility, float density) {
    if (starVisibility < 0.01) return vec3(0.0);
    vec3 stars = vec3(0.0);
    float seed = 0.0;
    for (int i = 0; i < 50; i++) {
        seed = hash1(seed + float(i) * 1.7);
        vec2 pos = vec2(hash1(seed + 0.1), hash1(seed + 0.2));
        float twinkle = 0.5 + 0.5 * sin(time * 2.0 + seed * 100.0);
        float size = mix(0.001, 0.003, hash1(seed + 0.3));
        float brightness = smoothstep(size * 3.0, 0.0, distance(uv, pos));
        stars += vec3(twinkle * brightness * starVisibility * density);
    }
    return stars;
}

#endif
