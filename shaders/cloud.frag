#version 450

// CloudLayer — 2~3 层 fBM 云噪声漂移
layout(std140, binding=0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;

    float time;
    float cloudCoverage;
    float cloudOpacity;
    int variant;
    float windSpeed;
    float transitionProgress;
};

layout(location=0) in vec2 qt_TexCoord0;
layout(location=0) out vec4 fragColor;

// ----- 内联公共函数 -----
float hash1(float p) {
    p = fract(p * 0.1031);
    p *= p + 33.33;
    p *= p + p;
    return fract(p);
}

float noise2D(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    float a = hash1(i.x + i.y * 57.0);
    float b = hash1(i.x + 1.0 + i.y * 57.0);
    float c = hash1(i.x + (i.y + 1.0) * 57.0);
    float d = hash1(i.x + 1.0 + (i.y + 1.0) * 57.0);
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float fbm2D(vec2 p, int octaves) {
    float value = 0.0;
    float amp = 0.5;
    float freq = 1.0;
    for (int i = 0; i < octaves; i++) {
        value += amp * noise2D(p * freq);
        freq *= 2.0;
        amp *= 0.5;
    }
    return value;
}

void main() {
    vec2 uv = qt_TexCoord0;

    // transitionProgress: tp=0 时云在右侧外，tp=1 时正常
    float tp = clamp(transitionProgress, 0.0, 1.0);
    float offsetX = (1.0 - tp) * 0.6;
    uv.x += offsetX;

    // 风速漂移
    float drift = time * windSpeed * 0.02;

    // 云密度缩放，根据 variant
    float densityScale = 1.0;
    if (variant == 0) densityScale = 0.5;     // 少云
    else if (variant == 1) densityScale = 0.8; // 多云
    else densityScale = 1.2;                    // 阴

    // 两层 fBM
    vec2 cloudUV  = uv * 3.0 + vec2(drift, 0.0);
    float cloud1  = fbm2D(cloudUV, 3);                     // 低频外形

    vec2 cloudUV2 = uv * 1.5 + vec2(drift * 0.7, drift * 0.3);
    float cloud2  = fbm2D(cloudUV2, 2) * 0.6;              // 中频层叠

    vec2 cloudUV3 = uv * 6.0 + vec2(drift * 1.2, drift * 0.5);
    float cloud3  = fbm2D(cloudUV3, 2) * 0.3;              // 高频细节

    float cloud = (cloud1 + cloud2 + cloud3) * 0.7;

    // 软阈值，保留中间灰度过渡
    cloud = smoothstep(0.25, 1.0, cloud);

    // 覆盖率控制
    cloud *= cloudCoverage * densityScale * tp;

    // 云颜色（白色到灰色渐变）
    vec3 cloudColor = mix(vec3(0.9, 0.9, 0.95), vec3(0.5, 0.5, 0.55), cloud * 0.5);

    // 地平线附近变暗
    float horizonFade = 1.0 - smoothstep(0.0, 0.3, abs(uv.y - 0.5) * 2.0);
    cloud *= mix(1.0, 0.3, horizonFade);

    float alpha = cloud * cloudOpacity;
    fragColor = vec4(cloudColor * alpha, alpha) * qt_Opacity;
}
