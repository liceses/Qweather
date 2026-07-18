#version 450

// [CloudLayer] — Volumetric cloud using fBM + emptiness/sharpness + raymarching
// 基于 fBM + 空值/锐度映射 + 光线步进的体积云
//
// Technique based on Inigo Quilez's 2D dynamic cloud approach:
//   http://www.iquilezles.org/www/articles/dynclouds/dynclouds.htm
// 技术参考：Inigo Quilez 的 2D 动态云方法
//
// Pipeline:
//   1) 3-layer fBM noise + domain warping produces raw cloud density
//      3 层 fBM 噪声 + 域扭曲生成原始云密度
//   2) emptiness/sharpness remap controls coverage (how much sky fills)
//      and edge hardness (how crisp cloud boundaries are)
//      空值/锐度重映射控制覆盖率和边缘硬度
//   3) 4-step raymarching: subtract increasing height thresholds and average,
//      simulating light absorption through cloud volume -> volumetric clumpy look
//      4 步光线步进：减去递增的高度阈值并平均，模拟云体积光吸收 → 体积感团状效果
//   4) height weight + exposure dim for final compositing
//      高度权重 + 曝光衰减用于最终合成

layout(std140, binding=0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;

    float time;
    float cloudCoverage;
    float cloudOpacity;
    int variant;
    float windSpeed;
    float transitionProgress;
    float exposure;
};

layout(location=0) in vec2 qt_TexCoord0;
layout(location=0) out vec4 fragColor;

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

// [fBM: sum of noise octaves with halving amplitude, doubling frequency]
// fBM：叠加噪声倍频程，振幅减半、频率加倍
// Each octave adds finer detail to the cloud shape / 每层倍频程为云形状增加更精细的细节
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

    // [Transition: tp slides clouds in from the right] / 过渡：tp 使云从右侧滑入
    float tp = clamp(transitionProgress, 0.0, 1.0);
    float offsetX = (1.0 - tp) * 0.6;
    uv.x += offsetX;

    // [Drift speed scaled from windSpeed for visible motion] / 根据风速缩放的漂移速度，确保可见运动
    float drift = time * windSpeed * 0.08;

    // [densityScale per variant] / 每种变体的密度缩放
    //   0 (sparse/少云):   multiply cloudCoverage by 0.1 → very few clouds
    //   1 (moderate/多云): multiply by 0.5 → visible patches
    //   2 (overcast/阴):   multiply by 2.0 → fills entire sky, clamped by emptiness
    float densityScale = 1.0;
    if (variant == 0) densityScale = 0.3;
    else if (variant == 1) densityScale = 0.7;
    else densityScale = 2.0;

    // [Domain warping: distort sampling coords with noise for organic movement] / 域扭曲：用噪声扭曲采样坐标，实现有机运动
    vec2 warpUV = uv * 2.0 + vec2(drift * 0.3, drift * 0.15);
    vec2 warp = vec2(
        fbm2D(warpUV, 2),
        fbm2D(warpUV + 10.0, 2)
    ) * 0.25;

    // [3-layer fBM with different scales + Y-drift for depth] / 3 层不同尺度的 fBM + Y 漂移实现深度感
    // layer 1: large shape (low frequency) / 第一层：大形状（低频）
    // layer 2: mid details (medium frequency) / 第二层：中等细节（中频）
    // layer 3: fine texture (high frequency) / 第三层：精细纹理（高频）
    vec2 cloudUV  = uv * 3.0 + warp + vec2(drift, drift * 0.15);
    float cloud1  = fbm2D(cloudUV, 3);

    vec2 cloudUV2 = uv * 1.5 + warp * 0.7 + vec2(drift * 0.7, drift * 0.3);
    float cloud2  = fbm2D(cloudUV2, 2) * 0.6;

    vec2 cloudUV3 = uv * 6.0 + warp * 1.2 + vec2(drift * 1.2, drift * 0.5);
    float cloud3  = fbm2D(cloudUV3, 2) * 0.3;

    // [Raw cloud density from combined noise] / 组合噪声产生的原始云密度
    float raw = (cloud1 + cloud2 + cloud3) * 0.7;

    // [Step 2: emptiness/sharpness remap (Inigo Quilez)] / 步骤 2：空值/锐度重映射
    // emptiness:  noise threshold below which no cloud forms
    //             high = less coverage, low = more coverage
    //             噪声阈值，低于此值不形成云；高→少覆盖，低→多覆盖
    // sharpness:  mapping ceiling for full cloud
    //             high = gradual edge falloff, low = sharp edges
    //             全云映射上限；高→渐变边缘，低→锐利边缘
    // fill:       effective coverage = cloudCoverage * densityScale
    //             有效覆盖率 = cloudCoverage * densityScale
    //             variant 0: fill=0.015  → emptiness=0.345, almost no cloud / 几乎无云
    //             variant 1: fill=0.15   → emptiness=0.300, moderate / 中等
    //             variant 2: fill=1.0    → emptiness=0.018, full coverage / 全覆盖
    float fill = cloudCoverage * densityScale;
    float emptiness = 0.30 * (1.0 - fill * 0.90);
    float sharpness = 0.95 - fill * 0.55;
    float cloud = clamp((raw - emptiness) / (sharpness - emptiness), 0.0, 1.0);

    // [Step 3: volumetric raymarching — simulates light absorption through cloud volume] / 步骤 3：体积光线步进——模拟光在云体积中的吸收
    float rmBase = 0.02 + 0.03 * min(fill, 1.0);
    cloud = dot(max(cloud - vec4(rmBase, rmBase + 0.12, rmBase + 0.28, rmBase + 0.5), 0.0), vec4(0.25));
    cloud = pow(cloud, 1.0);
    cloud = smoothstep(0.15, 0.85, cloud);
    cloud *= tp;

    // [Height weight per variant] / 每种变体的高度权重
    //   variant 0 (sparse/少云): no restriction / 无限制
    //   variant 1 (moderate/多云): concentrated in upper sky / 集中于天空上部
    //   variant 2 (overcast/阴): no restriction, full coverage / 无限制，全覆盖
    float hFade = 1.0;
    if (variant == 1) hFade = smoothstep(0.7, 0.0, uv.y);
    cloud *= 0.5 + 0.5 * hFade;

    // [Cloud color: white to gray, using raw noise for texture variation] / 云颜色：白到灰，使用原始噪声产生纹理变化
    float colorT = cloud * 0.5 + raw * 0.3;
    vec3 cloudColor = mix(vec3(0.9, 0.9, 0.95), vec3(0.5, 0.5, 0.55), colorT * 0.5);
    // [Night dim: reduce cloud brightness with low exposure] / 夜晚变暗：低曝光时降低云亮度
    float nightDim = clamp(exposure * 0.8, 0.05, 1.0);
    cloudColor *= nightDim;

    float alpha = cloud * cloudOpacity;
    fragColor = vec4(cloudColor * alpha, alpha) * qt_Opacity;
}
