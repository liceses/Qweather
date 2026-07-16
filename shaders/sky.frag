#version 450

// SkyLayer - sky gradient + sun glow + moon SDF + stars
layout(std140, binding=0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float time;
    float solarAltitude;
    float solarAzimuth;
    float moonAltitude;
    float moonAzimuth;
    float moonPhase;
    float moonIllum;
    vec4 zenithColor;
    vec4 horizonColor;
    vec4 ambientColor;
    float exposure;
    float twilightFactor;
    float starVisibility;
    float parallaxX;
    float parallaxY;
};

layout(location=0) in vec2 qt_TexCoord0;
layout(location=0) out vec4 fragColor;

// ---- ACES tone mapping (inlined) ----
vec3 acesTonemap(vec3 color) {
    float a = 2.51;
    float b = 0.03;
    float c = 2.43;
    float d = 0.59;
    float e = 0.14;
    return clamp((color * (a * color + b)) / (color * (c * color + d) + e), 0.0, 1.0);
}

// ---- common functions ----
const float PI = 3.14159265359;
const float DEG2RAD = 0.01745329252;

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

vec3 starField(vec2 uv, float t, float vis, float density) {
    if (vis < 0.01) return vec3(0.0);
    vec3 stars = vec3(0.0);
    float seed = 0.0;
    for (int i = 0; i < 50; i++) {
        seed = hash1(seed + float(i) * 1.7);
        vec2 pos = vec2(hash1(seed + 0.1), hash1(seed + 0.2));
        float twinkle = 0.5 + 0.5 * sin(t * 2.0 + seed * 100.0);
        float size = mix(0.001, 0.003, hash1(seed + 0.3));
        float dist = distance(uv, pos);
        float brightness = smoothstep(size * 3.0, 0.0, dist);
        stars += vec3(twinkle * brightness * vis * density);
    }
    return stars;
}

vec2 solarScreenPos() {
    float altRad = solarAltitude * DEG2RAD;
    float azRad = solarAzimuth * DEG2RAD;
    float x = 0.5 + 0.3 * sin(azRad);
    float y = 0.5 - 0.4 * sin(altRad);
    return vec2(x, y) + vec2(parallaxX * 0.05, parallaxY * 0.05);
}

vec2 moonScreenPos() {
    float altRad = moonAltitude * DEG2RAD;
    float azRad = moonAzimuth * DEG2RAD;
    float x = 0.5 + 0.3 * sin(azRad);
    float y = 0.5 - 0.4 * sin(altRad);
    return vec2(x, y) + vec2(parallaxX * 0.03, parallaxY * 0.03);
}

float moonPhaseMask(vec2 uv, vec2 moonPos, float radius, float phase) {
    vec2 p = uv - moonPos;
    float base = length(p) - radius;
    if (base > 0.0) return 1.0;
    float angle = phase * PI / 4.0;
    float cosA = cos(angle);
    float clipDist = p.x * cosA + radius * (1.0 - abs(cosA)) * 0.5;
    return clamp((cosA > 0.0 ? clipDist : -clipDist) * 100.0 + 0.5, 0.0, 1.0);
}

void main() {
    vec2 uv = qt_TexCoord0;

    float skyGradient = uv.y;
    float horizonBlend = pow(skyGradient, 0.8);
    vec3 skyColor = mix(zenithColor.rgb, horizonColor.rgb, horizonBlend);
    skyColor = mix(skyColor, ambientColor.rgb, 0.15);

    // sun
    vec2 sunPos = solarScreenPos();
    float sunVis = smoothstep(-15.0, -5.0, solarAltitude);
    if (sunVis > 0.001) {
        float dist = distance(uv, sunPos);
        float glowSize = mix(0.15, 0.3, max(0.0, -solarAltitude / 10.0));
        vec3 sunGlow = vec3(1.0, 0.9, 0.7) * exp(-dist * dist * 15.0 / (glowSize * glowSize));
        float core = exp(-dist * dist * 200.0);
        vec3 sunCore = vec3(1.0, 0.95, 0.85) * core;
        float lowAngle = clamp(1.0 - (solarAltitude + 5.0) / 15.0, 0.0, 1.0);
        vec3 lowSunColor = mix(vec3(1.0, 0.9, 0.7), vec3(1.0, 0.5, 0.2), lowAngle);
        skyColor += (sunGlow * lowSunColor * 1.5 + sunCore) * sunVis;
    }

    // moon
    float moonVis = smoothstep(-15.0, -5.0, moonAltitude) * step(0.1, moonIllum);
    if (moonVis > 0.001) {
        vec2 moonPos = moonScreenPos();
        float moonRadius = 0.04;
        float phaseMask = moonPhaseMask(uv, moonPos, moonRadius, moonPhase);
        float moonDist = distance(uv, moonPos);
        vec3 moonGlow = vec3(0.9, 0.95, 1.0) * exp(-moonDist * moonDist * 10.0) * 0.4 * moonVis;
        skyColor += moonGlow;
        if (phaseMask < 0.5) {
            float moonBright = 1.0 - moonDist / moonRadius;
            vec3 moonColor = vec3(0.85, 0.87, 0.9) * clamp(moonBright * 2.0, 0.0, 1.0) * moonIllum;
            moonColor *= (1.0 - phaseMask * 2.0) * moonVis;
            skyColor += moonColor;
        }
    }

    // stars
    vec3 stars = starField(uv, time, starVisibility, 1.0);
    skyColor += stars;

    // exposure + tonemap (ACES)
    skyColor = acesTonemap(skyColor * exposure);

    fragColor = vec4(skyColor, 1.0) * qt_Opacity;
}
