#version 450

// CloudLayer - volumetric cloud using fBM + emptiness/sharpness + raymarching
//
// Technique based on Inigo Quilez's 2D dynamic cloud approach:
//   http://www.iquilezles.org/www/articles/dynclouds/dynclouds.htm
//
// Pipeline:
//   1) 3-layer fBM noise + domain warping produces raw cloud density
//   2) emptiness/sharpness remap controls coverage (how much sky fills)
//      and edge hardness (how crisp cloud boundaries are)
//   3) 4-step raymarching: subtract increasing height thresholds and average,
//      simulating light absorption through cloud volume -> volumetric clumpy look
//   4) height weight + exposure dim for final compositing

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

// fBM: sum of noise octaves with halving amplitude, doubling frequency
// each octave adds finer detail to the cloud shape
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

    // transition: tp slides clouds in from the right
    float tp = clamp(transitionProgress, 0.0, 1.0);
    float offsetX = (1.0 - tp) * 0.6;
    uv.x += offsetX;

    // drift speed x4 relative to windSpeed for visible motion
    float drift = time * windSpeed * 0.08;

    // densityScale per variant:
    //   0 (sparse):  multiply cloudCoverage by 0.1 -> very few clouds
    //   1 (moderate): multiply by 0.5 -> visible patches
    //   2 (overcast): multiply by 2.0 -> fills entire sky, clamped by emptiness
    float densityScale = 1.0;
    if (variant == 0) densityScale = 0.3;
    else if (variant == 1) densityScale = 0.7;
    else densityScale = 2.0;

    // domain warping: distort sampling coords with noise for organic movement
    vec2 warpUV = uv * 2.0 + vec2(drift * 0.3, drift * 0.15);
    vec2 warp = vec2(
        fbm2D(warpUV, 2),
        fbm2D(warpUV + 10.0, 2)
    ) * 0.25;

    // 3-layer fBM with different scales + Y-drift for depth
    // layer 1: large shape (low frequency)
    // layer 2: mid details (medium frequency)
    // layer 3: fine texture (high frequency)
    vec2 cloudUV  = uv * 3.0 + warp + vec2(drift, drift * 0.15);
    float cloud1  = fbm2D(cloudUV, 3);

    vec2 cloudUV2 = uv * 1.5 + warp * 0.7 + vec2(drift * 0.7, drift * 0.3);
    float cloud2  = fbm2D(cloudUV2, 2) * 0.6;

    vec2 cloudUV3 = uv * 6.0 + warp * 1.2 + vec2(drift * 1.2, drift * 0.5);
    float cloud3  = fbm2D(cloudUV3, 2) * 0.3;

    // raw cloud density from combined noise
    float raw = (cloud1 + cloud2 + cloud3) * 0.7;

    // --- Step 2: emptiness/sharpness remap (Inigo Quilez) ---
    // emptiness:  noise threshold below which no cloud forms
    //             high = less coverage, low = more coverage
    // sharpness:  mapping ceiling for full cloud
    //             high = gradual edge falloff, low = sharp edges
    // fill:       effective coverage = cloudCoverage * densityScale
    //             variant 0: fill=0.015  -> emptiness=0.345, almost no cloud
    //             variant 1: fill=0.15   -> emptiness=0.300, moderate
    //             variant 2: fill=1.0    -> emptiness=0.018, full coverage
    float fill = cloudCoverage * densityScale;
    float emptiness = 0.30 * (1.0 - fill * 0.90);
    float sharpness = 0.95 - fill * 0.55;
    float cloud = clamp((raw - emptiness) / (sharpness - emptiness), 0.0, 1.0);

    // --- Step 3: volumetric raymarching ---
    float rmBase = 0.02 + 0.03 * min(fill, 1.0);
    cloud = dot(max(cloud - vec4(rmBase, rmBase + 0.12, rmBase + 0.28, rmBase + 0.5), 0.0), vec4(0.25));
    cloud = pow(cloud, 1.0);
    cloud = smoothstep(0.15, 0.85, cloud);
    cloud *= tp;

    // height weight per variant:
    //   variant 0 (sparse): no restriction
    //   variant 1 (moderate): concentrated in upper sky
    //   variant 2 (overcast): no restriction, full coverage
    float hFade = 1.0;
    if (variant == 1) hFade = smoothstep(0.7, 0.0, uv.y);
    cloud *= 0.5 + 0.5 * hFade;

    // cloud color: white to gray, use raw noise for texture variation
    float colorT = cloud * 0.5 + raw * 0.3;
    vec3 cloudColor = mix(vec3(0.9, 0.9, 0.95), vec3(0.5, 0.5, 0.55), colorT * 0.5);
    // night dim: reduce cloud brightness with low exposure
    float nightDim = clamp(exposure * 0.8, 0.05, 1.0);
    cloudColor *= nightDim;

    float alpha = cloud * cloudOpacity;
    fragColor = vec4(cloudColor * alpha, alpha) * qt_Opacity;
}
