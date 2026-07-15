// math.glsl — 数学常量与常用函数
#ifndef MATH_GLSL
#define MATH_GLSL

const float PI = 3.14159265359;
const float TWO_PI = 6.28318530718;
const float HALF_PI = 1.57079632679;
const float DEG2RAD = 0.01745329252;
const float RAD2DEG = 57.2957795131;

float clamp01(float x) { return clamp(x, 0.0, 1.0); }

float map(float x, float a, float b, float c, float d) {
    return (x - a) / (b - a) * (d - c) + c;
}

float lerp(float a, float b, float t) { return a + (b - a) * t; }

vec3 lerp(vec3 a, vec3 b, float t) { return a + (b - a) * t; }

float smoothstep01(float x) { return x * x * (3.0 - 2.0 * x); }

float saturate(float x) { return clamp(x, 0.0, 1.0); }

#endif
