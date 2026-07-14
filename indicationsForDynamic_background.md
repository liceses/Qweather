# QML 动态天气背景 —— Canvas / Shader 实现方案

---

## 一、两种方案对比总览

| 维度 | **Canvas** | **ShaderEffect** |
|------|-----------|-----------------|
| 渲染位置 | CPU → 位图 → 上传 GPU | 直接在 GPU 上运行 [4] |
| 性能 | 粒子数多时（>500）明显下降 | 数千粒子无压力 |
| 开发难度 | ⭐⭐ 低，QML/JS 即可 | ⭐⭐⭐⭐ 高，需写 GLSL |
| 适合效果 | 少量粒子、简单渐变、雪/雨 | 全屏渐变、光线、云层、大量粒子 |
| Qt6 兼容 | ✅ 直接可用 | ✅ 支持，但 shader 需用 `.qsb` 格式 [6][19] |
| 推荐用途 | 快速原型、简单效果 | 生产级、复杂动态背景 |

> **我推測**：对于你的天气应用，**ShaderEffect 是更优选择**——天气背景需要持续运行且覆盖全窗口，GPU 渲染能保证 UI 响应不受影响。

---

## 二、架构设计

### 推荐分层结构

```
┌─────────────────────────────────────────────────────┐
│ ApplicationWindow                                   │
│                                                     │
│  Layer 0: WeatherBackground {                       │
│    id: bgLayer                                      │
│    // 根据 weatherCode 动态切换子组件                │
│                                                     │
│    Loader { id: bgLoader }  ← 动态加载对应 shader   │
│                                                     │
│    // 方案A: ShaderEffect (推荐)                     │
│    // 方案B: Canvas (备选，简单场景)                  │
│  }                                                  │
│                                                     │
│  Layer 1: 半透明遮罩 (可选，增强文字可读性)           │
│                                                     │
│  Layer 2: RowLayout {                               │
│    左侧面板 (Column)  │  右侧网格 (GridLayout)       │
│  }                                                  │
└─────────────────────────────────────────────────────┘
```

### 文件结构（推測）

```
qml/
├── main.qml                        # 主窗口
├── WeatherBackground.qml           # 背景容器 + Loader 调度
├── backgrounds/
│   ├── SunnyBackground.qml         # 晴天：暖色渐变 + 光线
│   ├── CloudyBackground.qml        # 阴天：灰色渐变 + 云层漂移
│   ├── RainBackground.qml          # 雨天：雨滴粒子
│   ├── SnowBackground.qml          # 雪天：雪花飘落
│   ├── NightBackground.qml         # 夜间：星空 + 暗色渐变
│   └── ThunderBackground.qml       # 雷暴：闪电闪烁
├── shaders/
│   ├── rain.frag                   # 雨滴 fragment shader
│   ├── snow.frag                   # 雪花 fragment shader
│   ├── clouds.frag                 # 云层漂移 shader
│   ├── sun_glow.frag              # 阳光光晕 shader
│   ├── stars.frag                 # 星空 shader
│   └── lightning.frag             # 闪电 shader
└── components/
    ├── SidePanel.qml              # 左侧选项面板
    └── WeatherGrid.qml            # 右侧天气网格
```

---

## 三、天气码 → 背景效果映射表

基于 WeatherAPI 的标准天气 code [1]：

```
天气 code    条件          背景效果              实现方式
──────────────────────────────────────────────────────────
1000        晴天/晴夜      暖色渐变+光晕/星空    ShaderEffect
1003        多云          灰白渐变+云层漂移     ShaderEffect
1006        阴天          深灰渐变+厚重云层     ShaderEffect
1009        Overcast      均匀灰色+暗沉        Rectangle渐变
1030        雾/霾         模糊+乳白渐变         ShaderEffect + blur
1063-1195   各种雨         雨滴下落+涟漪        ShaderEffect (粒子)
1066-1072   雨夹雪         雨+雪混合           ShaderEffect
1114-1117   雪/暴雪        雪花飘落             ShaderEffect
1087        雷暴           暗色+闪电闪烁        ShaderEffect
1135        雾凇           白色渐变+模糊        ShaderEffect
1210-1252   冻雨/雪粒      冰晶粒子             ShaderEffect
1273-1282   雷雨           雨+闪电混合          ShaderEffect 组合
```

> ⚠️ 以上映射是我基于常识的**推測**，具体可根据你的审美偏好调整。

---

## 四、核心实现：ShaderEffect 方案（Qt6）

### 4.0 Qt6 ShaderEffect 基础模板

Qt6 中 `vertexShader` 和 `fragmentShader` 属性变为 URL，指向 `.qsb` 或内联 shader 文件 [6]。ShaderEffect 会自动将 QML 属性映射为 GLSL 中的 `uniform` 变量 [4]。

```qml
// Qt6 ShaderEffect 基础写法
ShaderEffect {
    id: effect
    anchors.fill: parent
  
    // QML 属性自动成为 shader 的 uniform
    property real time: 0
    property real intensity: 1.0
    property color skyTop: "#4a90d9"
    property color skyBottom: "#87ceeb"
  
    // Qt6: shader 以文件 URL 方式引用
    fragmentShader: "qrc:/shaders/clouds.frag"
  
    // 驱动动画
    NumberAnimation on time {
        from: 0; to: 1000
        duration: 1000000
        loops: Animation.Infinite
    }
}
```

### 4.1 晴天（Sunny）—— 暖色渐变 + 动态光晕

```glsl
// shaders/sun_glow.frag
#version 440

layout(location=0) in vec2 qt_TexCoord0;
layout(location=0) out vec4 fragColor;

layout(std140, binding=0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float time;
    vec4 skyTop;      // 天空顶部颜色，如 #4A90D9
    vec4 skyBottom;   // 天空底部颜色，如 #F5A623（暖金色）
    float sunAngle;   // 太阳角度（影响光线方向）
} ubuf;

// 2D 噪声函数（用于云朵效果）
float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    return mix(
        mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x),
        mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x),
        f.y
    );
}

void main() {
    vec2 uv = qt_TexCoord0;
  
    // 垂直渐变：上蓝下暖金
    vec3 gradient = mix(ubuf.skyBottom.rgb, ubuf.skyTop.rgb, uv.y);
  
    // 太阳光晕（右上角）
    float sunDist = distance(uv, vec2(0.75, 0.25));
    float glow = exp(-sunDist * 4.0) * 0.6;
    vec3 sunColor = vec3(1.0, 0.9, 0.5) * glow;
  
    // 动态光线（随时间旋转）
    float angle = ubuf.time * 0.05;
    vec2 lightDir = vec2(cos(angle), sin(angle));
    float lightRay = smoothstep(0.0, 1.0, 
        dot(uv - vec2(0.5), lightDir) * 2.0) * 0.08;
  
    // 轻微云朵噪点
    float cloud = noise(uv * 8.0 + ubuf.time * 0.02) * 0.03;
  
    vec3 finalColor = gradient + sunColor + vec3(lightRay) + cloud;
    fragColor = vec4(finalColor, 1.0) * ubuf.qt_Opacity;
}
```

### 4.2 雨天（Rain）—— 纯 Shader 雨滴粒子

```glsl
// shaders/rain.frag
#version 440

layout(location=0) in vec2 qt_TexCoord0;
layout(location=0) out vec4 fragColor;

layout(std140, binding=0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float time;
    float intensity;  // 雨强度 (0.0 ~ 1.0)，控制雨滴密度
    vec4 skyColor;    // 阴天背景色
} ubuf;

// 哈希函数生成伪随机
float hash(float n) { return fract(sin(n) * 43758.5453123); }

// 雨滴函数：返回该像素是否为雨滴
float raindrop(vec2 uv, float id, float t) {
    float seed = hash(id);
  
    // 每条雨滴的水平偏移
    float x = mod(seed * 6.28318, 1.0);
  
    // 雨滴垂直位置（循环下落）
    float speed = mix(0.3, 0.8, seed);
    float y = fract(seed * 3.14159 + t * speed);
  
    // 雨滴位置
    vec2 dropPos = vec2(x, y);
  
    // 与当前像素的距离
    float dist = abs(uv.x - dropPos.x) * 200.0;
    float vertDist = abs(uv.y - dropPos.y);
  
    // 雨滴形状：细长 + 尾部淡出
    float tail = smoothstep(0.0, 0.03, vertDist) * 0.7;
    float body = 1.0 - smoothstep(0.0, 0.002, dist);
    float head = 1.0 - smoothstep(0.0, 0.003, 
        distance(uv, dropPos) * 10.0);
  
    return max(body * tail, head * 0.5);
}

void main() {
    vec2 uv = qt_TexCoord0;
    vec3 bg = ubuf.skyColor.rgb;  // 深灰色阴天背景
  
    float rain = 0.0;
    int dropCount = int(mix(8.0, 30.0, ubuf.intensity));
  
    for (int i = 0; i < 30; i++) {
        if (i >= dropCount) break;
        rain += raindrop(uv, float(i) + floor(ubuf.time * 0.5), ubuf.time);
    }
  
    rain = clamp(rain, 0.0, 1.0);
  
    // 雨滴颜色：浅灰白
    vec3 rainColor = mix(bg, vec3(0.8, 0.85, 0.9), rain);
  
    fragColor = vec4(rainColor, 1.0) * ubuf.qt_Opacity;
}
```

### 4.3 雪天（Snow）—— 飘落雪花

```glsl
// shaders/snow.frag
#version 440

layout(location=0) in vec2 qt_TexCoord0;
layout(location=0) out vec4 fragColor;

layout(std140, binding=0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float time;
    float intensity;   // 雪强度
    vec4 skyTop;       // 上色
    vec4 skyBottom;    // 下色
} ubuf;

float hash12(vec2 p) {
    float h = dot(p, vec2(127.1, 311.7));
    return fract(sin(h) * 43758.5453);
}

// 雪花
float snowflake(vec2 uv, float id, float t, float wind) {
    float seed = hash12(vec2(id, 0.0));
  
    // 水平摆动（模拟风吹）
    float sway = sin(t * 0.8 + seed * 6.28) * 0.03 * wind;
    float x = mod(seed + sway, 1.0);
  
    // 垂直下落 + 左右摆动
    float speed = mix(0.1, 0.3, seed);
    float y = fract(seed * 6.28 + t * speed);
  
    vec2 pos = vec2(x, y);
    float dist = distance(uv, pos);
  
    // 雪花大小随机
    float size = mix(0.003, 0.012, hash12(vec2(id, 1.0)));
    float alpha = 1.0 - smoothstep(0.0, size, dist);
  
    // 边缘柔和的圆形
    return alpha * smoothstep(size, size * 0.5, dist);
}

void main() {
    vec2 uv = qt_TexCoord0;
  
    // 渐变背景
    vec3 bg = mix(ubuf.skyBottom.rgb, ubuf.skyTop.rgb, uv.y);
  
    float snow = 0.0;
    int count = int(mix(15.0, 50.0, ubuf.intensity));
  
    for (int i = 0; i < 50; i++) {
        if (i >= count) break;
        snow += snowflake(uv, float(i), ubuf.time, 0.5);
    }
  
    snow = clamp(snow, 0.0, 1.0);
    vec3 color = mix(bg, vec3(0.95), snow);
  
    fragColor = vec4(color, 1.0) * ubuf.qt_Opacity;
}
```

### 4.4 夜间（Night）—— 星空

```glsl
// shaders/stars.frag
#version 440

layout(location=0) in vec2 qt_TexCoord0;
layout(location=0) out vec4 fragColor;

layout(std140, binding=0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float time;
} ubuf;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1,311.7))) * 43758.5453); }

void main() {
    vec2 uv = qt_TexCoord0;
  
    // 深蓝到黑的夜空渐变
    vec3 skyTop = vec3(0.02, 0.02, 0.15);
    vec3 skyBottom = vec3(0.05, 0.05, 0.2);
    vec3 bg = mix(skyTop, skyBottom, 1.0 - uv.y);
  
    // 星空
    float stars = 0.0;
    for (int i = 0; i < 40; i++) {
        vec2 starPos = vec2(
            hash(vec2(float(i), 0.0)),
            hash(vec2(float(i), 1.0))
        );
        float twinkle = sin(ubuf.time * 2.0 + float(i)) * 0.5 + 0.5;
        float dist = distance(uv, starPos);
        float glow = exp(-dist * 40.0) * twinkle * 0.8;
        stars += glow;
    }
  
    vec3 color = bg + vec3(stars * 0.9, stars * 0.85, stars);
    fragColor = vec4(color, 1.0) * ubuf.qt_Opacity;
}
```

---

## 五、核心实现：Canvas 备选方案

对于简单效果或不支持 ShaderEffect 的后端，Canvas 是可靠的备选：

```qml
// backgrounds/RainCanvas.qml
Canvas {
    id: canvas
    anchors.fill: parent
  
    property real time: 0
    property real intensity: 0.5
    property int dropCount: 100
  
    // 存储雨滴状态
    property var drops: []
  
    Component.onCompleted: {
        for (var i = 0; i < 100; i++) {
            drops.push({
                x: Math.random(),
                y: Math.random(),
                speed: 0.003 + Math.random() * 0.007,
                length: 0.02 + Math.random() * 0.04,
                opacity: 0.3 + Math.random() * 0.5
            });
        }
    }
  
    // 动画循环
    Timer {
        interval: 16  // ~60 FPS
        running: true
        repeat: true
        onTriggered: {
            canvas.time += 0.016;
            // 更新雨滴位置
            for (var i = 0; i < canvas.drops.length; i++) {
                var d = canvas.drops[i];
                d.y += d.speed;
                if (d.y > 1.05) {
                    d.y = -0.05;
                    d.x = Math.random();
                }
            }
            canvas.requestPaint();
        }
    }
  
    onPaint: {
        var ctx = getContext("2d");
        var w = width, h = height;
      
        // 背景
        var gradient = ctx.createLinearGradient(0, 0, 0, h);
        gradient.addColorStop(0, "#2c3e50");
        gradient.addColorStop(1, "#4a6670");
        ctx.fillStyle = gradient;
        ctx.fillRect(0, 0, w, h);
      
        // 绘制雨滴
        ctx.strokeStyle = "rgba(200, 210, 220, 0.6)";
        ctx.lineWidth = 1;
      
        for (var i = 0; i < drops.length; i++) {
            var d = drops[i];
            var x = d.x * w;
            var y = d.y * h;
          
            ctx.globalAlpha = d.opacity;
            ctx.beginPath();
            ctx.moveTo(x, y);
            ctx.lineTo(x - 2, y + d.length * h);  // 斜线雨滴
            ctx.stroke();
        }
        ctx.globalAlpha = 1.0;
    }
}
```

> ⚠️ Canvas 在 100+ 粒子时性能可接受，但不建议超过 200 个。对于更密集的效果应使用 ShaderEffect。

---

## 六、背景切换机制（WeatherBackground.qml）

```qml
// WeatherBackground.qml —— 核心调度器
import QtQuick

Item {
    id: root
    anchors.fill: parent
  
    // 天气数据
    property int weatherCode: 1000       // 天气代码
    property bool isDay: true            // 是否白天
    property real transitionDuration: 800  // 过渡动画时长 ms
  
    // 当前活跃背景
    property Item currentBackground: null
  
    // 天气码到组件的映射
    function backgroundForCode(code, day) {
        if (!day) return "qrc:/qml/backgrounds/NightBackground.qml";
      
        // 晴天类
        if (code === 1000) return "qrc:/qml/backgrounds/SunnyBackground.qml";
      
        // 多云类
        if (code >= 1003 && code <= 1030) 
            return "qrc:/qml/backgrounds/CloudyBackground.qml";
      
        // 雨类
        if ((code >= 1063 && code <= 1201) || 
            (code >= 1240 && code <= 1246))
            return "qrc:/qml/backgrounds/RainBackground.qml";
      
        // 雪类
        if ((code >= 1114 && code <= 1117) || 
            (code >= 1210 && code <= 1225))
            return "qrc:/qml/backgrounds/SnowBackground.qml";
      
        // 雷暴
        if (code >= 1087 && code <= 1087)
            return "qrc:/qml/backgrounds/ThunderBackground.qml";
      
        // 默认多云
        return "qrc:/qml/backgrounds/CloudyBackground.qml";
    }
  
    // 双层 Loader 实现淡入淡出过渡
    Loader {
        id: loaderOld
        anchors.fill: parent
        opacity: 0
      
        Behavior on opacity {
            NumberAnimation { duration: root.transitionDuration }
        }
    }
  
    Loader {
        id: loaderNew
        anchors.fill: parent
        source: backgroundForCode(root.weatherCode, root.isDay)
      
        onLoaded: {
            root.currentBackground = item;
        }
    }
  
    // 监听天气变化，触发过渡
    onWeatherCodeChanged: switchBackground()
    onIsDayChanged: switchBackground()
  
    function switchBackground() {
        var newSource = backgroundForCode(weatherCode, isDay);
        if (loaderNew.source === newSource) return;
      
        // 移到旧层
        loaderOld.source = loaderNew.source;
        loaderOld.opacity = 1;
      
        // 加载新背景
        loaderNew.source = "";
        loaderNew.source = newSource;
      
        // 淡出旧层
        loaderOld.opacity = 0;
    }
}
```

---

## 七、ShaderEffect 使用注意事项（Qt6 特有问题）

### 7.1 Qt5 → Qt6 变化

Qt6 中 ShaderEffect 发生了重大变化 [19]：

| Qt5 | Qt6 |
|-----|-----|
| `fragmentShader: "..."` 内联 GLSL | `fragmentShader: "file.frag"` 引用文件 URL [6] |
| 直接写 GLSL | 需通过 `qsb` 工具编译为 `.qsb` [9] |
| 内置 QtGraphicalEffects | 已移除，需用 Ergosign/qml-shader-effects 替代 [9] |
| `property var source` | 使用 `sampler2D` 在 binding 1 [6] |

### 7.2 qsb 编译流程

```bash
# 将 GLSL 编译为 Qt Shader Baker 格式
qsb --glsl "430" -o rain.frag.qsb rain.frag
qsb --glsl "430" -o snow.frag.qsb snow.frag
qsb --hlsl 50 -o rain.frag.qsb rain.frag    # Windows/D3D
qsb --msl 20 -o rain.frag.qsb rain.frag     # macOS/Metal
```

然后在 QML 中引用 `.qsb` 文件：
```qml
fragmentShader: "qrc:/shaders/rain.frag.qsb"
```

### 7.3 运行时回退

```qml
ShaderEffect {
    id: shader
    anchors.fill: parent
    fragmentShader: "qrc:/shaders/rain.frag.qsb"
  
    // 如果 shader 不支持，回退到纯色
    status: ShaderEffect.Error ? fallback.visible = true : fallback.visible = false
}

Rectangle {
    id: fallback
    anchors.fill: parent
    visible: false
    gradient: Gradient {
        GradientStop { position: 0; color: "#2c3e50" }
        GradientStop { position: 1; color: "#4a6670" }
    }
}
```

---

## 八、推荐实现路径

```
阶段1 (1-2天)                阶段2 (3-5天)              阶段3 (2-3天)
┌─────────────────┐    ┌─────────────────────┐    ┌─────────────────┐
│ Rectangle 渐变   │ →  │ Canvas 粒子效果      │ →  │ ShaderEffect    │
│ 纯色/渐变背景    │    │ RainBackground      │    │ GPU 全效果      │
│ (立即可用)      │    │ SnowBackground      │    │ 雨/雪/星空/光晕 │
│                 │    │ (回退方案)           │    │ (最终方案)      │
└─────────────────┘    └─────────────────────┘    └─────────────────┘
```

> **我推測**的路径：先用 Rectangle 渐变快速搭建骨架 → 再用 Canvas 实现粒子逻辑验证 → 最后将粒子逻辑移植到 GLSL 获得 GPU 性能。这样可以保证每个阶段都有可用的视觉效果。

---

## 九、关键参考资源

| 资源 | 用途 |
|------|------|
| [Qt6 ShaderEffect 文档](https://doc.qt.io/qt-6/qml-qtquick-shadereffect.html) [6] | ShaderEffect API 参考 |
| [Ergosign/qml-shader-effects](https://github.com/Ergosign/qml-shader-effects) [9] | Qt6 预置 shader 效果库（MIT） |
| [Woboq GPU Drawing](https://woboq.com/blog/gpu-drawing-using-shadereffects-in-qtquick.html) [4] | ShaderEffect 原理详解 |
| [QML Book Ch.11](https://qmlbook.github.io/ch11-shaders/shaders.html) [5] | GLSL 入门教程 |
| [basysKom Qt5→Qt6 迁移](https://www.basyskom.de/en/qt-6-how-to-port-shader-effects-from-qt-5) [19] | Shader 迁移指南 |
| [Cyanilux Rain Effects](https://www.cyanilux.com/tutorials/rain-effects-breakdown) [11] | 雨天效果设计思路 |
| [Rain Shader Live Demo](https://rain-shader.nordicbeaver.io/) [10] | 玻璃雨滴效果参考 |

---

需要我进一步展开某个具体的 shader（比如带闪电的雷暴效果、或者云层漂移的 Perlin Noise 实现）吗？

---

---

## 十、正式实现方案：ShaderEffect + Manager 架构（2026-07-14）

> 基于原始方案分析，结合项目实际架构（C++ Store + QML 纯渲染 + context property 注册），
> 设计三层解耦：Manager（中间层状态机）→ WeatherBackground（渲染容器）→ DebugPanel（调试控制）。

---

### 10.1 架构总览

```
Main.qml
│
├── WeatherBackgroundManager { id: weatherBgManager }   ← 中间层状态机
│     mode: Auto(跟随App天气) | Debug(手动接管)
│     输出: currentType, currentIntensity, currentWindSpeed
│
├── WeatherBackground { manager: weatherBgManager }     ← 渲染容器
│     ├── Loader A                                      ← 双层 + bool角色交换(零开销)
│     │     └── SunnyBg | CloudyBg | RainBg | SnowBg | NightBg | FogBg
│     ├── Loader B                                      ← 每层独立 animationProgress 动画
│     │     └── [下一个背景]                              ← 进入层: 0→1, 退出层: 1→0 (800ms 同时驱动)
│     ├── NumberAnimation×2 (drive transitionProgress)  ← 元素级过程式过渡(非 opacity 混合)
│     ├── abortCurrentTransition()                      ← 中断式防抖
│     └── MouseArea (hoverEnabled → parallaxX/Y)
│
├── [Layer 1: RowLayout + StackLayout 现有UI]
│
└── WeatherBackgroundDebugPanel { manager: weatherBgManager }  ← 浮动面板
      Switch: Auto/Debug
      类型选择网格 + 参数滑块
```

**核心规则**：
- 项目本体 **只通过 Manager 的 `updateAppWeather()`** 改变背景
- DebugPanel **只通过 Manager 的 `setDebugXxx()`** 接管背景
- 两者互不感知，只跟 Manager 对话
- Manager 是唯一的 `currentType` 真值源

**过渡机制（V2 过程式）**：
- 不是两个画面 opacity 交叉淡入淡出（幻灯片切换）
- 每个 shader 的每个元素用 `transitionProgress` (0↔1) 驱动独立动画
- 进入层 (0→1): 云从屏幕外漂入 / 雨滴渐增 / 光晕渐显
- 退出层 (1→0): 光晕淡出 / 天空色恢复 / 粒子渐消
- 两层同时驱动，800ms 后角色交换，卸载旧背景

---

### 10.2 WeatherBackgroundManager 中间层设计

```qml
// WeatherBackgroundManager.qml
// 实例化在 Main.qml 顶层，通过 id 传递

Item {
    id: manager

    // ===== 模式枚举 =====
    readonly property int modeAuto: 0
    readonly property int modeDebug: 1
    property int controlMode: modeAuto

    // ===== Auto 模式输入（Main.qml 写入） =====
    property string appType: "sunny"       // typeFromCode() 映射结果
    property string appIconCode: "100"     // 原始 icon code（调试面板只读展示）
    property bool appIsDay: true

    // ===== Debug 模式输入（DebugPanel 写入） =====
    property string debugType: "sunny"
    property real debugIntensity: 0.5
    property real debugWindSpeed: 0.3

    // ===== 计算输出（WeatherBackground 只读绑定） =====
    readonly property string currentType:
        controlMode === modeAuto ? appType : debugType
    readonly property real currentIntensity:
        controlMode === modeAuto ? 0.5 : debugIntensity
    readonly property real currentWindSpeed:
        controlMode === modeAuto ? 0.3 : debugWindSpeed

    // ===== 公共 API =====

    // 供 Main.qml 调用
    function updateAppWeather(iconCode, isDay) {
        appIconCode = String(iconCode)
        appIsDay = !!isDay
        appType = typeFromCode(iconCode, isDay)
    }

    // 供 DebugPanel 调用
    function enterDebugMode() {
        debugType = appType        // 继承当前 App 背景，避免突变
        debugIntensity = 0.5
        debugWindSpeed = 0.3
        controlMode = modeDebug
    }
    function exitDebugMode() {
        controlMode = modeAuto
    }
    function setDebugType(t)      { if (controlMode === modeDebug) debugType = t }
    function setDebugIntensity(v) { if (controlMode === modeDebug) debugIntensity = v }
    function setDebugWindSpeed(v) { if (controlMode === modeDebug) debugWindSpeed = v }

    // ===== icon code → 背景类型映射（与 WeatherIcon.qml 一致） =====
    function typeFromCode(code, isDay) {
        var c = parseInt(code)
        if (isNaN(c)) return "sunny"
        if (!isDay) return "night"
        if (c === 100) return "sunny"
        if (c >= 101 && c <= 104) return "cloudy"
        if (c >= 300 && c <= 399) return "rain"
        if (c >= 400 && c <= 499) return "snow"
        if (c >= 500 && c <= 599) return "fog"
        return "sunny"
    }

    // 供 WeatherBackground 使用：类型 → QML 路径
    function qmlForType(type) {
        switch (type) {
            case "sunny":  return "SunnyBg.qml"
            case "cloudy": return "CloudyBg.qml"
            case "rain":   return "RainBg.qml"
            case "snow":   return "SnowBg.qml"
            case "night":  return "NightBg.qml"
            case "fog":    return "FogBg.qml"
            default:       return "SunnyBg.qml"
        }
    }

    // 供 DebugPanel 使用：所有可用类型列表
    readonly property var allTypes: ["sunny", "cloudy", "rain", "snow", "night", "fog"]
    readonly property var typeLabels: ({
        "sunny": "晴", "cloudy": "阴", "rain": "雨",
        "snow": "雪", "night": "夜", "fog": "雾"
    })
}
```

**关键设计点**：
- `controlMode` 的切换是数据驱动：改变 `controlMode` 即改变 `currentType` 的计算结果
- `enterDebugMode()` 时自动继承 `appType`，避免切换瞬间背景突变
- `setDebugType()` 只在 Debug 模式下才允许写入，防止误操作（Auto 模式下写进去也不生效，因为 `currentType` 取的是 `appType`）
- `typeFromCode()` 基于项目现有 icon code 体系，与 WeatherIcon.qml 保持一致

---

### 10.3 WeatherBackground 渲染容器设计（V2 — 三层过渡模型）

> **核心理念**：不是两个完整画面的 opacity 交叉淡入淡出（幻灯片切换）。
> 而是分为**两层过渡机制**覆盖全部 2278 种天气码过渡对：
> - **跨类型**（rain→snow 等）：双层 Loader + transitionProgress 元素级过程式过渡 (800ms)
> - **同类型参数变化**（305小雨→307大雨）：单层 shader 参数平滑动画 (400ms)
> - **相同不变**：NO-OP
>
> **过渡时间线示例（Sunny → Cloudy — 跨类型）**：
> ```
> T=0ms:    进入动画(CloudyBg.transitionProgress 0→1) + 退出动画(SunnyBg.transitionProgress 1→0)
> T=0→800ms: 云从右侧屏幕外漂入 + 云覆盖率渐增 + 天空变灰  |  太阳光晕淡出 + 暖色消失
> T=800ms:   角色交换: CloudyBg 成为 active → 旧 SunnyBg Loader source="" 卸载
> ```
> 用户看到的效果：云真的从边缘外移动进来遮住了太阳，而不是两张图交叉混合。
>
> **参数平滑示例（小雨→大雨 — 同类型）**：
> ```
> T=0ms:    active shader (RainBg) 当前 intensity=0.2
> T=0→400ms: intensity 0.2 平滑→0.7, shader 内粒子密度连续增加
> T=400ms:   完成, 视觉效果是"雨渐渐变大"而非瞬间加密
> ```

#### 10.3.1 潜在问题矩阵

| # | 场景 | 风险 | 等级 |
|---|------|------|:---:|
| I1 | 过渡期间(800ms)再次切换城市 | 动画堆叠、闪烁、状态错乱 | **P0** |
| I2 | 连续快速切换不同城市 | 过渡反复中断重启，需防抖 | **P0** |
| I3 | 同天气类型重复触发 | 无意义过渡浪费 GPU 资源 | **P0** |
| I4 | 首次加载无"旧背景" | Loader 空引用→属性访问崩溃 | P1 |
| I5 | 过渡中 ShaderEffect 编译失败 | 单个 shader 黑屏 → 叠加后闪烁 | P1 |
| I6 | Debug ↔ Auto 快速切换 | pendingType 和 appType 竞态 | P1 |
| I7 | 旧 Loader 未清空 source | 内存泄漏 + GPU 纹理未释放 | P1 |
| I8 | 两个 ShaderEffect 同时运行 | 过渡期 GPU 负载翻倍(≤120 粒子可接受) | P2 |
| I9 | 鼠标视差 + 过渡并存 | 两个 shader 绑定同一 parallax 值，Qt.binding 确保一致 | P2 |
| I10 | Manager 同帧多属性变更 | 仅 `appType` 改变 `currentType`，不重复触发 | P3 |
| I11 | 应用最小化后恢复 | 过渡 Timer 可能超时丢失 → onTransitionComplete 中状态保护 | P3 |
| I12 | resize 窗口期间过渡 | 坐标归一化(uv)天然免疫 | — |
| I13 | 同类型参数变化（小雨→大雨） | 若 switchTo 被 NO-OP 拦截，intensity 瞬间跳变 | **P0** |

#### 10.3.2 核心策略：三层决策 + 中断式防抖

**决策树**：

```
switchTo(requestedType, requestedIntensity, requestedVariant):
    sameType ← (requestedType == activeType)
    paramsChanged ← (intensity≠ || variant≠)

    ┌─ sameType && !paramsChanged  → return (NO-OP)           // 层0: 完全相同
    ├─ sameType && paramsChanged   → smoothParamsTransition()  // 层1: 参数平滑
    ├─ !sameType && transitioning  → abortCurrentTransition()
    ├─ activeType==""              → instantLoad()             // 首次
    └─ !sameType                   → startTypeTransition()     // 层2: 过程式
```

**层1: 参数平滑过渡**（I13 消解）：

```
smoothParamsTransition(newIntensity, newVariant):
    paramAnimIntensity.from = activeLdr.item.intensity
    paramAnimIntensity.to   = newIntensity
    paramAnimIntensity.duration = 400ms  (InOutCubic)
    paramAnimIntensity.start()
    // variant 同理平滑（如有效）
    // 不换 Loader，不触发 transitionProgress
    // 视觉: 雨滴密度缓缓增大/减小，闪电从无到偶尔
```

**层2: 过程式过渡**：

```
startTypeTransition(requestedType):
    ... 双层 Loader + transitionProgress 0↔1 (800ms) ...
```

**中断式防抖**：

```
abortCurrentTransition():
    ├─ enterAnim.stop(); exitAnim.stop()
    ├─ paramAnimIntensity.stop(); paramAnimVariant.stop()  // ★ 也停止参数动画
    ├─ transitionTimer.stop()
    ├─ activeLdr.item.transitionProgress = 1.0   // 活跃层恢复完整
    ├─ activeLdr.item.intensity = currentIntensity // ★ 恢复当前参数
    ├─ activeLdr.item.variant   = currentVariant
    ├─ inactiveLdr.source = ""                   // 丢弃半成品
    ├─ transitioning = false; pendingType = ""
    └─ // 此时状态干净如初，可以安全发起新过渡
```

**关键原则**：中断时**回退到当前活跃背景的完整状态**，绝不在部分混合的画面上继续操作。

#### 10.3.3 角色交换（零开销 Loader 管理）

不用 "A 覆盖 B 的 source" 模式（会 reload 导致 GPU 资源重建），改用 **bool 标记**：

```
property bool loaderAIsActive: true

activeLdr   → loaderAIsActive ? loaderA : loaderB
inactiveLdr → loaderAIsActive ? loaderB : loaderA

onTransitionComplete:
    loaderAIsActive = !loaderAIsActive     // 角色交换（零开销）
    inactiveLdr.source = ""                // 卸载旧背景,释放 GPU 资源
    activeType = pendingType; pendingType = ""
    transitioning = false
```

每个背景只被 Loader 加载和卸载各一次，不涉及重新创建 / 重新编译 shader。

#### 10.3.4 完整 V2 伪代码

```qml
// WeatherBackground.qml — V2 过程式过渡版
Item {
    id: bgRoot
    property var manager: null
    property string activeType: ""
    property bool transitioning: false
    property string pendingType: ""
    property bool loaderAIsActive: true

    property double parallaxX: 0
    property double parallaxY: 0

    // 辅助引用
    readonly property Loader activeLdr:   loaderAIsActive ? loaderA : loaderB
    readonly property Loader inactiveLdr: loaderAIsActive ? loaderB : loaderA

    Loader { id: loaderA; anchors.fill: parent; opacity: 1.0 }
    Loader { id: loaderB; anchors.fill: parent; opacity: 1.0 }

    // 动画组件
    NumberAnimation {
        id: enterAnim; property: "transitionProgress"
        duration: 800; easing.type: Easing.InOutCubic
    }
    NumberAnimation {
        id: exitAnim; property: "transitionProgress"
        duration: 800; easing.type: Easing.InOutCubic
    }
    // ★ 参数平滑动画
    NumberAnimation {
        id: paramAnimIntensity; property: "intensity"
        duration: 400; easing.type: Easing.InOutCubic
    }
    NumberAnimation {
        id: paramAnimVariant; property: "variant"
        duration: 400; easing.type: Easing.InOutCubic
    }
    Timer { id: transitionTimer; interval: 800; onTriggered: onTransitionComplete() }

    // ===== 入口（三层决策） =====
    function switchTo(type, intensity, variant) {
        var sameType = (type === activeType)
        var paramsChanged = (intensity !== currentIntensity || variant !== currentVariant)

        // 层0: 完全相同 → NO-OP
        if (sameType && !paramsChanged && !transitioning) return
        // I2: 相同目标已在进行中
        if (transitioning && type === pendingType) return
        // I1: 中断当前过渡
        if (transitioning) abortCurrentTransition()
        // 层1: 同类型参数变化 → 参数平滑
        if (sameType && paramsChanged) {
            smoothParamsTransition(intensity, variant)
            return
        }
        // I4: 首次加载
        if (activeType === "") { loadInstant(type); return }
        // 层2: 跨类型过程式过渡
        startTransition(type)
    }

    // ===== 层1: 参数平滑过渡 ★ 新增 =====
    function smoothParamsTransition(newIntensity, newVariant) {
        var item = activeLdr.item
        if (!item) return
        paramAnimIntensity.target = item
        paramAnimIntensity.from = item.intensity
        paramAnimIntensity.to = newIntensity
        paramAnimIntensity.start()
        paramAnimVariant.target = item
        paramAnimVariant.from = item.variant
        paramAnimVariant.to = newVariant
        paramAnimVariant.start()
        // 视觉: 雨滴密度缓缓增大/减小，闪电渐現/渐消
    }

    // ===== 首次加载(无动画) =====
    function loadInstant(type) {
        activeLdr.source = manager.qmlForType(type)
        waitAndInject(activeLdr, true)
        activeType = type
    }

    // ===== 正常过渡 =====
    function startTransition(type) {
        pendingType = type
        inactiveLdr.source = manager.qmlForType(type)
        waitAndInject(inactiveLdr, false)

        // 初始化 progress
        if (activeLdr.item)   activeLdr.item.transitionProgress = 1.0
        if (inactiveLdr.item) inactiveLdr.item.transitionProgress = 0.0

        transitioning = true

        // 进入动画(新背景 0→1) + 退出动画(旧背景 1→0) 同时驱动
        exitAnim.target = activeLdr.item
        exitAnim.from = 1.0; exitAnim.to = 0.0
        enterAnim.target = inactiveLdr.item
        enterAnim.from = 0.0; enterAnim.to = 1.0

        exitAnim.start()
        enterAnim.start()
        transitionTimer.start()
    }

    // ===== 中断 =====
    function abortCurrentTransition() {
        enterAnim.stop(); exitAnim.stop()
        paramAnimIntensity.stop(); paramAnimVariant.stop()  // ★ 也停止参数动画
        transitionTimer.stop()

        // 活跃层恢复到完整显示状态
        if (activeLdr && activeLdr.item) {
            activeLdr.item.transitionProgress = 1.0
            activeLdr.item.intensity = manager.currentIntensity   // ★ 恢复
            activeLdr.item.variant   = manager.currentVariant     // ★ 恢复
        }
        // 丢弃非活跃层的半成品
        inactiveLdr.source = ""

        transitioning = false
        pendingType = ""
    }

    // ===== 过渡完成 =====
    function onTransitionComplete() {
        loaderAIsActive = !loaderAIsActive   // 角色交换
        inactiveLdr.source = ""             // 卸载旧背景

        transitioning = false
        activeType = pendingType
        pendingType = ""
    }

    // ===== 属性注入 Helper =====
    property var _pendingLdr: null

    function waitAndInject(ldr, isActive) {
        if (ldr.item) {
            injectProperties(ldr.item)
            ldr.item.transitionProgress = isActive ? 1.0 : 0.0
        } else {
            _pendingLdr = ldr
            _pendingIsActive = isActive
        }
    }
    property bool _pendingIsActive: false

    Connections {
        target: _pendingLdr
        enabled: _pendingLdr !== null
        function onLoaded() {
            bgRoot.injectProperties(_pendingLdr.item)
            _pendingLdr.item.transitionProgress = bgRoot._pendingIsActive ? 1.0 : 0.0
            _pendingLdr = null
        }
    }

    function injectProperties(item) {
        if (!item || !manager) return
        item.intensity = Qt.binding(function() { return manager.currentIntensity })
        item.variant   = Qt.binding(function() { return manager.currentVariant })    // ★
        item.windSpeed = Qt.binding(function() { return manager.currentWindSpeed })
        item.parallaxX = Qt.binding(function() { return bgRoot.parallaxX })
        item.parallaxY = Qt.binding(function() { return bgRoot.parallaxY })
    }

    // ===== 监听 Manager =====
    Connections {
        target: bgRoot.manager
        enabled: bgRoot.manager !== null
        function onCurrentTypeChanged() {
            bgRoot.switchTo(bgRoot.manager.currentType)
        }
    }

    // ===== 鼠标视差 =====
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onPositionChanged: function(mouse) {
            bgRoot.parallaxX = (mouse.x / bgRoot.width  - 0.5) * 2.0
            bgRoot.parallaxY = (mouse.y / bgRoot.height - 0.5) * 2.0
        }
    }
}
```

**关键设计点**：
- `transitionProgress` 驱动元素级别进场/退场，每层独立动画，而非整个画面 opacity 混合
- `abortCurrentTransition()` 先恢复 active 到完整状态再接受新请求，保证状态干净
- `bool loaderAIsActive` 角色交换零开销，避免反复创建/销毁 shader
- `Qt.binding()` 动态注入属性绑定，parallax/intensity/windSpeed 即时跟随 Manager
- `waitAndInject()` + `Connections onLoaded` 处理 Loader 异步加载时序
- `_pendingIsActive` 标记确保异步注入时 transitionProgress 初值正确

#### 10.3.5 过渡覆盖矩阵

68 种天气码产生 68×67 = 2278 种唯一过渡对（去除自循环），全部由三层模型覆盖：

| 过渡类型 | 举例 | 机制 | 视觉 | 时长 | 覆盖率 |
|------|------|------|------|:---:|:---:|
| 完全相同 | 305→305 | NO-OP | 无 | — | ~68 对 |
| 同类型±intensity | 305小雨→307大雨 | paramAnim | 雨滴密度缓缓增大 | 400ms | ~1600 对 |
| 同类型±variant | 307大雨→302雷阵雨 | paramAnim | 闪电从无到偶尔 | 400ms | ~500 对 |
| 同类型±两者 | 305小雨→303强雷暴 | paramAnim×2 | 密度↑+闪电渐現 | 400ms | ~180 对 |
| 跨类型 | 305小雨→400小雪 | transitionProgress | 雨丝渐消+雪花渐显 | 800ms | ~30 对 |

**2278 种过渡全部无缝覆盖。** 跨类型仅 ~30 种触发 800ms 过程式过渡，其余均为 400ms 参数平滑或 NO-OP。

---

### 10.4 ShaderEffect 背景组件统一接口

每个天气类型 = 1 个 `.qml` (ShaderEffect 包装) + 1 个 `.frag` (GLSL fragment shader)

#### 10.4.1 通用 QML 模板

```qml
// 以 SunnyBg.qml 为例
ShaderEffect {
    id: effect
    anchors.fill: parent

    // === 标准属性（由 WeatherBackground 的 injectProperties 注入） ===
    property real time: 0
    property real intensity: 0.5
    property real windSpeed: 0.3
    property real parallaxX: 0
    property real parallaxY: 0
    property real transitionProgress: 0.0   // ★ 0→1 进场 / 1→0 退场,由 WeatherBackground 动画驱动

    // === 专用属性（各背景不同） ===
    property color colorTop: "#4a90d9"
    property color colorBottom: "#f5a623"

    // === Shader ===
    fragmentShader: "qrc:/shaders/sunny.frag"

    // === 时间驱动 ===
    NumberAnimation on time { from: 0; to: 1000; duration: 1000000; loops: Animation.Infinite }

    // === 容错：Shader 编译失败时回退到纯色渐变 ===
    Rectangle {
        anchors.fill: parent
        visible: effect.status === ShaderEffect.Error
        gradient: Gradient {
            GradientStop { position: 0; color: "#4a90d9" }
            GradientStop { position: 1; color: "#f5a623" }
        }
    }
}
```

#### 10.4.2 GLSL 统一 Uniform 接口

```glsl
// qrc:/shaders/xxx.frag 通用 uniform block 结构
#version 440
layout(location=0) in vec2 qt_TexCoord0;
layout(location=0) out vec4 fragColor;

layout(std140, binding=0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    // --- QML 属性按声明顺序自动映射为 uniform ---
    float time;               // 持续递增的时间 (0→1000→0...)
    float intensity;          // 0.0~1.0 效果强度（粒子密度等）
    float windSpeed;          // 0.0~1.0 动画速度倍率
    float parallaxX;          // -1.0~1.0 鼠标水平偏移
    float parallaxY;          // -1.0~1.0 鼠标垂直偏移
    float transitionProgress; // ★ 0→1 进场(元素入场/渐显) / 1→0 退场(元素退场/渐消)
    // 以下按具体背景类型可选添加：
    vec4 colorTop;            // 天空顶部颜色
    vec4 colorBottom;         // 天空底部颜色
} ubuf;

// transitionProgress 语义：
// 0.0 → 全部元素不可见/在屏幕外（不是"透明"，而是还没入场）
// 1.0 → 完全展示、正常运行
// 所有元素用 mix(emptyState, fullState, tp) 统一过渡
```

**QML 属性 → GLSL uniform 映射规则**：
- 属性按 QML 中的**声明顺序**出现在 uniform block 中 [Qt6 文档]
- `real` → `float`, `color` → `vec4`, `int` → `int`, `bool` → `int`
- `qt_Matrix` + `qt_Opacity` 由 Qt 自动插入前两个 slot
- 多余的 QML 属性被忽略（不会报错）

---

### 10.5 各天气类型 Shader 效果设计（V2 — 含 transitionProgress）

> 每个天气类型的每个视觉元素都用 `mix(emptyState, fullState, tp)` 驱动，
> 其中 `tp = clamp(transitionProgress, 0.0, 1.0)`。
> 进入动画时 tp 0→1，元素从"不可见/在屏幕外"过渡到完全展示；
> 退出动画时 tp 1→0，元素反向退场。

---

#### 10.5.1 SunnyBg — 晴天

`qrc:/shaders/sunny.frag`

| 元素 | 满状态 (tp=1) | 空状态 (tp=0) | 过渡公式 |
|------|:---:|:---:|---|
| 太阳光晕 | `exp(-dist*4)*0.6` | 0 | `glow *= tp` |
| 天空暖色 | 蓝→金渐变 | 灰蓝(与阴天色一致) | `sky = mix(skyCloudy, skySunny, tp)` |
| 旋转光线 | `dot*0.08` | 0 | `ray *= tp` |
| 云纹理 | `noise*0.03` | 0 | `cloud *= tp` |

---

#### 10.5.2 CloudyBg — 阴天

`qrc:/shaders/cloudy.frag`

| 元素 | 满状态 (tp=1) | 空状态 (tp=0) | 过渡公式 |
|------|:---:|:---:|---|
| 云层1 水平位移 | `normalPos1` | `normalPos1 + 0.6` (屏幕右侧外) | `cloudX1 = mix(normalPos1 + 0.6, normalPos1, tp)` |
| 云层2 水平位移 | `normalPos2` | `normalPos2 + 0.5` (反方向) | `cloudX2 = mix(normalPos2 + 0.5, normalPos2, tp)` |
| 云覆盖率 | `intensity*0.55+0.15` | 0.0 | `coverage = mix(0.0, density, tp)` |
| 天空色调 | 阴天灰蓝 `#8d9ba6` | 晴天蓝 `#4a90d9` | `sky = mix(skyClear, skyCloudy, tp)` |

```glsl
// 天空色调过渡
vec3 skyClear  = vec3(0.29, 0.56, 0.85);
vec3 skyCloudy = vec3(0.55, 0.62, 0.70);
vec3 sky = mix(skyClear, skyCloudy, tp);

// 云层水平位移: tp=0 时云在屏幕右侧外 +0.6
float cloud1Offset = mix(0.6, 0.0, tp);
float cloud1 = noise(vec2((uv.x - 0.3 + cloud1Offset + time*speed1) * 3.0, uv.y * 4.0));

// 云覆盖率
float coverage = mix(0.0, ubuf.intensity * 0.55 + 0.15, tp);
float cloudMask = smoothstep(1.0 - coverage, 1.0 - coverage + 0.15, cloud);

vec3 color = mix(sky, vec3(0.82, 0.84, 0.87), cloudMask);
```

---

#### 10.5.3 RainBg — 雨天

`qrc:/shaders/rain.frag`

| 元素 | 满状态 (tp=1) | 空状态 (tp=0) | 过渡公式 |
|------|:---:|:---:|---|
| 雨滴数量 | `mix(15, 50, intensity)` | 0 | `dropCount = int(mix(0.0, float(maxDrops), tp))` |
| 天空色调 | 雨天暗灰 | 晴天蓝 | `sky = mix(skyClear, skyRain, tp)` |
| 底部涟漪 | `noise*0.02` | 0 | `ripple *= tp` |

> 注意：GLSL for 循环上限必须在编译时确定（const int），不能动态变化。
> 实际做法是用固定上限（如 60），用 tp 控制每条雨滴的可见度：`dropAlpha *= (i < int(mix(0,maxDrops,tp))) ? 1.0 : 0.0`。

---

#### 10.5.4 SnowBg — 雪天

`qrc:/shaders/snow.frag`

| 元素 | 满状态 (tp=1) | 空状态 (tp=0) | 过渡公式 |
|------|:---:|:---:|---|
| 雪花数量 | `mix(20, 60, intensity)` | 0 | `flakeAlpha *= (i < int(mix(0,maxFlakes,tp))) ? 1.0 : 0.0` |
| 天空色调 | 雪天冷白 | 晴天蓝 | `sky = mix(skyClear, skySnow, tp)` |
| 雪花整体亮度 | 1.0 | 0.3 (微光) | `flakeBright = mix(0.3, 1.0, tp)` |

---

#### 10.5.5 NightBg — 夜间

`qrc:/shaders/night.frag`

| 元素 | 满状态 (tp=1) | 空状态 (tp=0) | 过渡公式 |
|------|:---:|:---:|---|
| 星星亮度 | `twinkle*0.8` | 0 | `starAlpha *= tp` |
| 天空暗度 | 深蓝黑 | 日间色 | `sky = mix(skyDay, skyNight, tp)` |
| 月光光晕 | `exp(-dist*3)*0.15` | 0 | `moonGlow *= tp` |

---

#### 10.5.6 FogBg — 雾天

`qrc:/shaders/fog.frag`

| 元素 | 满状态 (tp=1) | 空状态 (tp=0) | 过渡公式 |
|------|:---:|:---:|---|
| 雾气不透明度 | `mix(0.1, 0.4, intensity)` | 0.0 | `fogAlpha = mix(0.0, maxAlpha, tp)` |
| 雾气覆盖范围 | 全屏 | 0 (仅边缘) | `range = mix(0.0, 1.0, tp)` |
| 天空色调 | 雾白 | 晴天蓝 | `sky = mix(skyClear, skyFog, tp)` |

---

### 10.6 WeatherBackgroundDebugPanel 调试面板设计

#### 布局

```
位置: 右侧滑出，z 轴最高层 (z: 100)
宽度: 280px，高度: fill parent
背景: #e0e8e0 (不透明实色，独立于动态背景)
触发: Ctrl+Shift+B 快捷键 或 设置页按钮
```

#### UI 结构（从上到下）

```
┌─────────────────────────────┐
│  调试面板            [✕]    │
│                             │
│  ⬤Auto    跟随焦点城市天气  │  ← Switch 切换
│  ○Debug   手动测试模式      │
│                             │
│  ─────── 天气类型 ────────   │
│  ┌────┐ ┌────┐ ┌────┐      │
│  │ ☀ │ │ ☁ │ │ 🌙 │      │  ← 3×2 Grid 类型卡片
│  │晴  │ │阴  │ │夜  │      │     点击即切换
│  └────┘ └────┘ └────┘      │     当前选中高亮 #4caf50 边框
│  ┌────┐ ┌────┐ ┌────┐      │
│  │ 🌧 │ │ ❄ │ │ 🌫 │      │
│  │雨  │ │雪  │ │雾  │      │
│  └────┘ └────┘ └────┘      │
│                             │
│  ─────── 参数 ──────────    │
│  强度     [═══════╪══] 0.5  │  ← Slider: 粒子密度
│  风速     [══╪═══════] 0.2  │  ← Slider: 动画速度
│  (Debug 模式才可调)          │
│                             │
│  ─────── 当前状态 ───────    │
│  App天气码: 100 (晴)         │  ← 只读信息
│  App白天:   true            │
│  Manager:  Debug → cloudy   │
└─────────────────────────────┘
```

#### 交互行为

| 操作 | 行为 |
|------|------|
| 快捷键 `Ctrl+Shift+B` | 切换面板显示/隐藏 |
| Switch: Auto → Debug | `enterDebugMode()` → 继承当前 App 背景类型，参数区 enabled |
| Switch: Debug → Auto | `exitDebugMode()` → 背景恢复跟随 App 天气，参数区 disabled |
| 点击类型卡片 | Debug 模式下 `setDebugType(type)` 立即生效 |
| 拖动滑块 | `setDebugIntensity(v)` / `setDebugWindSpeed(v)` 即时生效 |
| 关闭面板 (✕ 或快捷键) | 自动 `exitDebugMode()` → 恢复 Auto |
| 面板打开时 | Auto 模式：仅展示只读状态信息 |
| 面板打开时 | Debug 模式：可操作类型卡片 + 参数滑块 |

---

### 10.7 数据流（V2 — 过程式过渡）

#### 正常模式 (Auto) — 以 Sunny → Cloudy 为例

```
weatherApi.weatherNowReady(now) → icon="104", isDay=true
  → Main.qml:
      weatherBgManager.updateAppWeather("104", true)
        → Manager.typeFromCode(104, true) → "cloudy"
        → Manager.appType = "cloudy"
          → Manager.currentType → "cloudy"  (controlMode == Auto)
            → WeatherBackground: onCurrentTypeChanged
              → switchTo("cloudy")
                → startTransition("cloudy")
                  ├─ inactiveLdr.source = "CloudyBg.qml"
                  │    └─ loaded → injectProperties → transitionProgress = 0.0
                  ├─ activeLdr.item.transitionProgress = 1.0
                  ├─ enterAnim: CloudyBg.transitionProgress 0→1 (800ms, InOutCubic)
                  │    └─ Shader: 云从右侧漂入、覆盖率渐增、天空渐灰
                  ├─ exitAnim:  SunnyBg.transitionProgress 1→0 (800ms, InOutCubic)
                  │    └─ Shader: 光晕淡出、暖色消失、光线消失
                  └─ transitionTimer (800ms) → onTransitionComplete
                       ├─ loaderAIsActive = !loaderAIsActive
                       ├─ inactiveLdr.source = "" (卸载 SunnyBg)
                       └─ transitioning = false
```

#### 快速连点 — 中断式防抖

```
T=0ms:   switchTo("cloudy") → startTransition, transitioning=true
T=300ms: switchTo("rain")   → abortCurrentTransition()
                                ├─ enterAnim/exitAnim/timer 全部 stop
                                ├─ activeLdr(CloudyBg).transitionProgress = 1.0 (恢复完整)
                                ├─ inactiveLdr.source = "" (丢弃 RainBg 半成品)
                                └─ transitioning = false
          switchTo("rain")   → startTransition 重新开始
```

#### 调试模式 (Debug)

```
用户点击 DebugPanel 中 ☁
  → Manager.setDebugType("cloudy")
    → Manager.debugType = "cloudy"
      → Manager.currentType → "cloudy"  (controlMode == Debug)
        → WeatherBackground.switchTo("cloudy") → startTransition 同上

用户拖动风速到 0.7
  → Manager.setDebugWindSpeed(0.7)
    → Manager.currentWindSpeed → 0.7
      → Qt.binding → CloudyBg.windSpeed → 0.7 (即时生效，无过渡动画)
        → Shader uniform windSpeed → 云朵移动加速

用户拖动强度 (intensity)
  → 同 windSpeed，即时生效
  → 注意: 强度影响粒子数量/覆盖率，对于 CloudyBg 是云密度，
      对于 RainBg/SnowBg 是粒子数量（shader 内用固定上限 + 可见度控制）
```

#### 模式切换

```
DebugPanel Switch: Auto → Debug
  → Manager.enterDebugMode()
    → debugType = appType  // 继承当前背景
    → controlMode = Debug
    → currentType 不变 (debugType == appType) → 不触发过渡
    → 参数区 enabled

DebugPanel Switch: Debug → Auto (或面板关闭)
  → Manager.exitDebugMode()
    → controlMode = Auto
    → currentType 重新 = appType（如不同则触发 switchTo 及其过程式过渡）
    → 参数区 disabled
```

#### Manager 属性变更时序（I10 消解）

```
Manager.updateAppWeather(iconCode, isDay):
    appIconCode = ...     // 无 readonly 依赖
    appIsDay = ...        // 无 readonly 依赖
    appType = ...         // ← 仅此行改变 currentType
    // → onCurrentTypeChanged 只触发一次 → switchTo() 只调用一次
```

---

### 10.8 文件清单

#### 新增文件 (15 个)

| 文件 | 说明 | 类型 |
|------|------|------|
| `WeatherBackgroundManager.qml` | 中间层状态管理 | QML Item |
| `WeatherBackground.qml` | 背景容器 + 双层 Loader + 过渡 + 视差 | QML Item |
| `SunnyBg.qml` | 晴天 ShaderEffect 包装 | QML ShaderEffect |
| `CloudyBg.qml` | 阴天 ShaderEffect 包装 | QML ShaderEffect |
| `RainBg.qml` | 雨天 ShaderEffect 包装 | QML ShaderEffect |
| `SnowBg.qml` | 雪天 ShaderEffect 包装 | QML ShaderEffect |
| `NightBg.qml` | 夜间 ShaderEffect 包装 | QML ShaderEffect |
| `FogBg.qml` | 雾天 ShaderEffect 包装 | QML ShaderEffect |
| `WeatherBackgroundDebugPanel.qml` | 调试面板浮动 UI | QML Rectangle |
| `shaders/sunny.frag` | 晴天 fragment shader | GLSL |
| `shaders/cloudy.frag` | 阴天 fragment shader | GLSL |
| `shaders/rain.frag` | 雨天 fragment shader | GLSL |
| `shaders/snow.frag` | 雪天 fragment shader | GLSL |
| `shaders/night.frag` | 夜间 fragment shader | GLSL |
| `shaders/fog.frag` | 雾天 fragment shader | GLSL |

#### 修改文件 (2 个)

| 文件 | 变更 |
|------|------|
| `Main.qml` | (1) 移除临时绿色渐变 Rectangle；(2) 实例化 Manager + Background + DebugPanel（三层叠加）；(3) `onWeatherNowReady` 中调用 `weatherBgManager.updateAppWeather(now.icon, isDay)`；(4) 添加快捷键 `Ctrl+Shift+B` 切换 DebugPanel |
| `CMakeLists.txt` | (1) `QML_FILES` 添加 9 个 `.qml`；(2) `qt_add_resources` 添加 6 个 `.frag` shader |

---

### 10.9 Qt6 ShaderEffect 技术要点

| 要点 | 说明 |
|------|------|
| Shader 格式 | `#version 440` Vulkan 兼容 GLSL，Qt6 RHI 运行时编译到对应后端 (D3D/Metal/Vulkan) |
| Uniform 映射 | QML 属性按**声明顺序**出现在 `layout(std140, binding=0) uniform buf` 中 |
| 类型映射 | `real`→`float`, `color`→`vec4`, `int`→`int`, `bool`→`int` |
| 默认 vertex shader | 提供 `qt_TexCoord0`（归一化纹理坐标 0~1），无需自定义 |
| 默认 mesh | 单个 quad (2 triangles)，网格密度 1×1，覆盖整个 ShaderEffect 区域 |
| 容错 | `effect.status === ShaderEffect.Error` 时显示 Rectangle 渐变回退 |
| 性能 | GPU 直接渲染，数千粒子无压力，远优于 Canvas 的 CPU 管线 |
| vs Qt5 差异 | Qt6 中 `fragmentShader` 改为文件 URL（非内联字符串）；默认 vertexShader 自动提供；`property var source` 改用 `sampler2D` |

---

### 10.10 实施阶段（V2）

#### 阶段 A：基础架构（Manager + Background + SunnyBg） ~2h

1. 创建 `WeatherBackgroundManager.qml`（Item，全部属性/API/映射函数）
2. 创建 `WeatherBackground.qml`（V2 版：角色交换 + 中断式防抖 + transitionProgress 动画 + 视差）
3. 创建 `shaders/sunny.frag` + `SunnyBg.qml`
4. 修改 `Main.qml`：移除临时绿色渐变 Rectangle；实例化 Manager + Background + DebugPanel；`onWeatherNowReady` 中调用 `weatherBgManager.updateAppWeather(now.icon, isDay)`；添加 `Ctrl+Shift+B` 快捷键
5. 验证：
   - 首次加载：无闪屏，直接显示 SunnyBg
   - focusId 切换：过程式过渡（光晕淡出/淡入正常）
   - 同天气类型：不触发过渡（NO-OP）
   - Shader 容错：删除 .frag 文件 → fallback Rectangle 显示

#### 阶段 B：全部 6 种 Shader 背景 ~4h

1. `shaders/night.frag` + `NightBg.qml` — 验证星空点亮/熄灭动画
2. `shaders/cloudy.frag` + `CloudyBg.qml` — 验证云层从屏幕外漂入/漂出
3. `shaders/rain.frag` + `RainBg.qml` — 验证雨滴渐增/渐减 + 天空变暗
4. `shaders/snow.frag` + `SnowBg.qml` — 验证雪花渐增/渐减 + 风吹摆动
5. `shaders/fog.frag` + `FogBg.qml` — 验证雾气渐显/渐散

每个验证项：
- transitionProgress 0→1 元素进场行为正确
- transitionProgress 1→0 元素退场行为正确
- intensity / windSpeed / parallax 实时绑定到 shader uniforms
- fallback Rectangle 颜色与 shader 配色一致

#### 阶段 C：调试面板 ~2h

1. 创建 `WeatherBackgroundDebugPanel.qml`
2. 实现 Auto/Debug Switch + 类型选择网格 + 参数滑块
3. 验证：
   - Auto→Debug: 继承当前背景，无突变
   - Debug 模式下点类型卡片: 过程式过渡正常
   - 拖动滑块: 即时生效（不触发过渡动画）
   - Debug→Auto / 关闭面板: 自动恢复 Auto
   - 面板关闭→重新打开: 自动回 Auto 模式

#### 阶段 D：防抖/中断/边界测试 + CMakeLists ~1h

1. 防抖测试：连续快速点击 5 个不同城市 → 不闪不崩不堆叠
2. 中断测试：过渡中途再次切换 → 回退到 active 完整状态再重来
3. 首次加载测试：清空缓存启动 → 直接显示背景无异常
4. 同类型测试：连续选同天气类型 → 不触发过渡
5. 容错测试：故意破坏一个 .frag → fallback 渐变显示
6. 更新 `CMakeLists.txt`:
   - `QML_FILES` 添加 9 个 `.qml`
   - `qt_add_resources` 添加 6 个 `.frag` shader

---

### 10.11 方案演进总结

| 维度 | 原始方案（第一章~第九章） | V1 正式方案（10.1~10.11） | V2 过程式过渡版 |
|------|-------------------------|--------------------------|----------------|
| 渲染方式 | Canvas → ShaderEffect 逐步 | 直接 ShaderEffect | 同 V1 |
| 中间层 | 无 | Manager 状态机 Auto/Debug | 同 V1 |
| 过渡方式 | opacity crossfade | opacity crossfade | **transitionProgress 过程式** |
| 视觉呈现 | "幻灯片切换"两张画面 | 同左 | **元素独立动画：云漂入/雨渐密/光晕淡出** |
| 防抖策略 | 无 | 无 | **中断式防抖 (abort→恢复→重来)** |
| Loader 管理 | 单层或 source 覆盖 | source 覆盖 (需 reload) | **bool 角色交换 (零开销)** |
| 调试面板 | 无 | 完整 DebugPanel | 同 V1 |
| Shader 接口 | 5 个 uniform | 5 个 uniform | **+transitionProgress (6 个)** |
| 问题覆盖 | 无 | 未考虑 | **12 个潜在问题 P0~P3 全覆盖** |

> **V2 的核心改进**：从"两个画面 opacity 交叉淡入淡出"升级为"每个 shader 元素独立动画"。
> 用户看到的不再是"换了一张背景图"，而是"天气正在发生变化"——云真的从边缘外飘进来遮住了太阳。

---

### 10.12 强度+变体双参数精细控制（V2.1）

> 现有 `typeFromCode()` 将 68 个天气码粗暴映射为 6 种背景，损失了大量细节：
> 302 雷阵雨→rain（闪电消失）、304 雷阵雨伴有冰雹→rain（闪电+冰雹全丢失）、
> 501 雾 vs 502 霾 vs 508 强沙尘暴→全是 fog（色调/质感无差异）、
> 400 小雪 vs 403 暴雪→snow（密度一样）。
>
> **对策**：不是新增 shader 文件，而是给每个 shader 增加 `intensity`（程度）和 `variant`（变体）两个参数。
> 仍为 6 个 shader，不增加 QML 文件数量，只扩展属性接口和 shader 内部分支。

---

#### 10.12.1 和风天气全部 68 个 icon code 与映射

##### 晴天类 (100–153)

| 代码 | 天气 | 白天 | 夜晚 |
|:---:|------|:---:|:---:|
| 100 | 晴 Sunny | ✅ | — |
| 101 | 多云 Cloudy | ✅ | — |
| 102 | 少云 Few Clouds | ✅ | — |
| 103 | 晴间多云 Partly Cloudy | ✅ | — |
| 104 | 阴 Overcast | ✅ | ✅ |
| 150 | 晴 Clear | — | ✅ |
| 151 | 多云 Cloudy | — | ✅ |
| 152 | 少云 Few Clouds | — | ✅ |
| 153 | 晴间多云 Partly Cloudy | — | ✅ |

##### 雨类 (300–399) — 22 种

| 代码 | 天气 | 变体线索 |
|:---:|------|------|
| 300 | 阵雨 Shower Rain | — |
| 301 | 强阵雨 Heavy Shower Rain | intensity↑ |
| 302 | 雷阵雨 Thundershower | **闪电** |
| 303 | 强雷阵雨 Heavy Thunderstorm | **闪电** + intensity↑ |
| 304 | 雷阵雨伴有冰雹 Hail | **闪电+冰雹** |
| 305 | 小雨 Light Rain | intensity↓ |
| 306 | 中雨 Moderate Rain | intensity=mid |
| 307 | 大雨 Heavy Rain | intensity↑ |
| 308 | 极端降雨 Extreme Rain | intensity=MAX |
| 309 | 毛毛雨/细雨 Drizzle | intensity=MIN |
| 310 | 暴雨 Storm | intensity=high |
| 311 | 大暴雨 Heavy Storm | intensity=very-high |
| 312 | 特大暴雨 Severe Storm | intensity=MAX |
| 313 | 冻雨 Freezing Rain | **冰晶** |
| 314 | 小到中雨 | intensity↓→mid |
| 315 | 中到大雨 | intensity=mid→↑ |
| 316 | 大到暴雨 | intensity↑→high |
| 317 | 暴雨到大暴雨 | intensity=high→very-high |
| 318 | 大暴雨到特大暴雨 | intensity=very-high→MAX |
| 350 | 阵雨(夜) Shower Rain | — |
| 351 | 强阵雨(夜) Heavy Shower Rain | intensity↑ |
| 399 | 雨(通用) Rain | — |

##### 雪类 (400–499) — 15 种

| 代码 | 天气 | 变体线索 |
|:---:|------|------|
| 400 | 小雪 Light Snow | intensity↓ |
| 401 | 中雪 Moderate Snow | intensity=mid |
| 402 | 大雪 Heavy Snow | intensity↑ |
| 403 | 暴雪 Snowstorm | intensity=MAX |
| 404 | 雨夹雪 Sleet | **mixed** |
| 405 | 雨雪天气 Rain And Snow | **mixed** |
| 406 | 阵雨夹雪 Shower Snow | **mixed** |
| 407 | 阵雪 Snow Flurry | — |
| 408 | 小到中雪 | intensity↓→mid |
| 409 | 中到大雪 | intensity=mid→↑ |
| 410 | 大到暴雪 | intensity↑→MAX |
| 456 | 阵雨夹雪(夜) | **mixed** |
| 457 | 阵雪(夜) Snow Flurry | — |
| 499 | 雪(通用) Snow | — |

##### 雾/霾/沙尘类 (500–515) — 14 种

| 代码 | 天气 | 变体线索 |
|:---:|------|------|
| 500 | 薄雾 Mist | intensity↓ |
| 501 | 雾 Foggy | — |
| 502 | 霾 Haze | **黄色调** |
| 503 | 扬沙 Sand | **沙尘** |
| 504 | 浮尘 Dust | **沙尘** |
| 507 | 沙尘暴 Duststorm | **沙尘** + intensity↑ |
| 508 | 强沙尘暴 Sandstorm | **沙尘** + intensity=MAX |
| 509 | 浓雾 Dense fog | intensity↑ |
| 510 | 强浓雾 Strong fog | intensity↑ |
| 511 | 中度霾 Moderate haze | **黄色调** + intensity=mid |
| 512 | 重度霾 Heavy haze | **黄色调** + intensity↑ |
| 513 | 严重霾 Severe haze | **黄色调** + intensity=MAX |
| 514 | 大雾 Heavy fog | intensity↑ |
| 515 | 特强浓雾 Extra heavy fog | intensity=MAX |

##### 极端温度 + 未知 (900–999)

| 代码 | 天气 | 映射 |
|:---:|------|------|
| 900 | 热 Hot | sunny (default) |
| 901 | 冷 Cold | sunny (default) |
| 999 | 未知 Unknown | sunny (default) |

---

#### 10.12.2 双参数定义

**`intensity`** (0.0~1.0) — 粒子密度 / 效果强度 / 覆盖率，直接从天气码计算：

| 类型 | 0.1–0.3（低） | 0.4–0.6（中） | 0.7–1.0（高） |
|------|------|------|------|
| rain | 309, 305, 314 | 306, 307, 315 | 308, 310, 311, 312, 316–318, 301, 303 |
| snow | 400, 408 | 401, 402, 409 | 403, 410 |
| fog | 500 | 501, 502, 503, 504 | 507, 508, 509, 510, 511, 512, 513, 514, 515 |
| cloudy | 102 | 101, 103 | 104 |
| sunny | 100 (默认) | — | 900 (热, 更亮的光晕) |

**`variant`** (int 0~3) — 同类型内的视觉变体，控制 shader 分支：

| 类型 | variant=0 | 1 | 2 | 3 |
|------|:---:|:---:|:---:|:---:|
| rain | 普通雨 | **雷暴**（闪电闪烁） | **冰雹/冻雨**（白色硬粒） | 雷暴+冰雹 |
| snow | 纯雪 | **雨夹雪**（雨雪混合粒子） | — | — |
| fog | 雾/薄雾（乳白） | **霾**（黄色调） | **沙尘**（棕褐调） | — |
| cloudy | 少云（低覆盖） | 多云（中覆盖） | 阴（全覆盖） | — |
| sunny | 正常晴 | — | — | — |
| night | 正常夜 | — | — | — |

---

#### 10.12.3 Manager 新增函数

```qml
// ===== 从 weather code 计算 appIntensity/appVariant =====

function intensityFromCode(code, type) {
    switch (type) {
        case "rain":
            if ([309, 305, 314].indexOf(code) >= 0)  return 0.2
            if ([306, 315].indexOf(code) >= 0)        return 0.5
            if ([307, 316].indexOf(code) >= 0)        return 0.7
            if ([308, 312, 318].indexOf(code) >= 0)   return 1.0
            if ([301, 303].indexOf(code) >= 0)        return 0.8
            if ([310, 317].indexOf(code) >= 0)        return 0.85
            if ([311].indexOf(code) >= 0)             return 0.9
            if ([300, 302, 304, 350, 351, 399].indexOf(code) >= 0) return 0.5
            return 0.5
        case "snow":
            if ([400, 408].indexOf(code) >= 0)   return 0.2
            if ([401, 409].indexOf(code) >= 0)   return 0.5
            if ([402, 410].indexOf(code) >= 0)   return 0.7
            if ([403].indexOf(code) >= 0)        return 1.0
            if ([404, 405, 406, 456].indexOf(code) >= 0)  return 0.4
            if ([407, 457, 499].indexOf(code) >= 0)        return 0.5
            return 0.5
        case "fog":
            if ([500].indexOf(code) >= 0)   return 0.2
            if ([501, 502, 503, 504].indexOf(code) >= 0)  return 0.4
            if ([509, 510, 511, 514].indexOf(code) >= 0)  return 0.7
            if ([507, 508, 512, 513, 515].indexOf(code) >= 0) return 1.0
            return 0.4
        case "cloudy":
            if ([102].indexOf(code) >= 0) return 0.3
            if ([101, 103, 151, 152, 153].indexOf(code) >= 0) return 0.5
            if ([104].indexOf(code) >= 0) return 0.8
            return 0.5
        default:
            return 0.5
    }
}

function variantFromCode(code, type) {
    switch (type) {
        case "rain":
            if (code === 304) return 3    // 雷暴+冰雹
            if (code === 302 || code === 303) return 1  // 雷暴
            if (code === 313) return 2    // 冻雨→冰雹
            return 0  // 普通雨
        case "snow":
            if (code === 404 || code === 405 || code === 406 || code === 456) return 1  // 雨夹雪
            return 0
        case "fog":
            if (code === 502 || code === 511 || code === 512 || code === 513) return 1  // 霾
            if (code === 503 || code === 504 || code === 507 || code === 508) return 2  // 沙尘
            return 0  // 普通雾
        case "cloudy":
            if (code === 102 || code === 152) return 0  // 少云
            if (code === 101 || code === 103 || code === 151 || code === 153) return 1  // 多云
            if (code === 104) return 2  // 阴
            return 1
        default:
            return 0
    }
}

// 更新 updateAppWeather:
function updateAppWeather(iconCode, isDay) {
    appIconCode = String(iconCode)
    appIsDay = !!isDay
    var c = parseInt(iconCode)
    appType = typeFromCode(c, isDay)
    appIntensity = intensityFromCode(c, appType)
    appVariant = variantFromCode(c, appType)
}
```

---

#### 10.12.4 更新 Manager 属性

在现有 Manager 属性基础上新增：

```qml
// === 现有属性（保持） ===
property int controlMode: modeAuto
property string appType: "sunny"
property string appIconCode: "100"
property bool appIsDay: true
property string debugType: "sunny"
property real debugIntensity: 0.5
property int debugVariant: 0       // ★ 新增
property real debugWindSpeed: 0.3

// === 强度/变体（精细控制） ★ 新增 ===
property real appIntensity: 0.5
property int appVariant: 0

// === 计算输出 ★ 更新 ===
readonly property real currentIntensity:
    controlMode === modeAuto ? appIntensity : debugIntensity
readonly property int currentVariant:
    controlMode === modeAuto ? appVariant : debugVariant
```

---

#### 10.12.5 更新 Shader 统一接口

在 10.4.2 的 uniform block 中新增 `variant`：

```glsl
layout(std140, binding=0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float time;
    float intensity;          // 粒子密度/覆盖率 (0.0~1.0)
    float windSpeed;
    float parallaxX;
    float parallaxY;
    float transitionProgress;
    float variant;            // ★ 变体 0/1/2/3 (shader 中 int(variant+0.5) 转整型)
    vec4 colorTop;
    vec4 colorBottom;
} ubuf;
```

QML 组件模板新增属性：

```qml
property real variant: 0    // ★ 由 injectProperties 注入
```

`injectProperties` 新增：

```qml
item.variant = Qt.binding(function() { return manager.currentVariant })
```

---

#### 10.12.6 各 Shader 的 variant 行为

##### Rain shader

```glsl
int variant = int(ubuf.variant + 0.5);
bool thunder = (variant == 1 || variant == 3);
bool hail    = (variant == 2 || variant == 3);

// 闪电：每 3~8 秒随机闪一次，全屏瞬间提亮
float flash = 0.0;
if (thunder) {
    float flashSeed = floor(ubuf.time * 0.3);
    float flashTime = hash(vec2(flashSeed, 99.0)) * 5.0 + 3.0; // 3~8s间隔
    float flashPhase = fract(ubuf.time * 0.3 / flashTime);
    flash = step(0.95, flashPhase) * step(flashPhase, 0.97) * 0.4;
}

// 冰雹：白色圆形硬粒，速度快于雨滴
float hailParticle = 0.0;
if (hail) {
    // 额外 10~20 个白色粒子，下落速度×2，圆形非线形
    for (int i = 60; i < 80; i++) {
        if (i >= 60 + int(mix(0.0, 20.0, ubuf.intensity))) break;
        hailParticle += hailDrop(uv, float(i), ubuf.time);
    }
    hailParticle = clamp(hailParticle, 0.0, 1.0);
}

// 合成
vec3 finalColor = bg + rainColor + vec3(flash) * vec3(0.9, 0.85, 0.7);
finalColor = mix(finalColor, vec3(0.95), hailParticle * 0.6);
```

##### Fog shader

```glsl
int variant = int(ubuf.variant + 0.5);

// 基础色（variant 区分雾/霾/沙尘）
vec3 fogWhite  = vec3(0.88, 0.90, 0.92);  // 雾：乳白
vec3 fogHaze   = vec3(0.82, 0.76, 0.58);  // 霾：黄灰
vec3 fogSand   = vec3(0.68, 0.58, 0.42);  // 沙尘：棕褐
vec3 fogBase   = (variant == 1) ? fogHaze : ((variant == 2) ? fogSand : fogWhite);

// 沙尘额外：带颗粒感的噪声纹理
float grain = (variant == 2) ? noise(uv * 40.0 + ubuf.time * 0.05) * 0.08 : 0.0;

vec3 color = fogBase + vec3(grain);
```

##### Snow shader

```glsl
int variant = int(ubuf.variant + 0.5);
bool mixedRainSnow = (variant == 1);  // 雨夹雪

// 正常雪花粒子 + 如果 mixed 额外叠加少量雨丝
// 雨丝比重随 variant 增加
float rainMix = mixedRainSnow ? 0.3 : 0.0;
vec3 finalColor = mix(snowColor, rainColor, rainMix);
```

##### Cloudy shader

```glsl
int variant = int(ubuf.variant + 0.5);

// 云覆盖率: variant 0=少云 1=多云 2=阴
float baseCoverage = mix(0.2, 0.85, float(variant) / 2.0);
float coverage = mix(0.0, baseCoverage, tp);  // + transitionProgress
```

---

#### 10.12.7 DebugPanel 改造

参数区扩展：

```
强度     [═══════╪══] 0.5        ← 已有
变体     ○ 普通雨  ● 雷暴  ○ 冰雹  ○ 雷暴+冰雹  ← ★ 新增 (rain时)
         ○ 纯雪    ○ 雨夹雪               ← snow时
         ○ 雾      ○ 霾    ○ 沙尘        ← fog时
         ○ 少云    ○ 多云  ○ 阴          ← cloudy时
         (sunny/night → 禁用,显示 "—")
风速     [══╪═══════] 0.2        ← 已有
```

Auto 模式下变体为只读显示（由天气码自动决定），Debug 模式下可手动切换。

---

#### 10.12.8 文件清单更新

新增文件不变（15 个）。修改文件增加：

| 文件 | 变更 |
|------|------|
| `WeatherBackgroundManager.qml` | 新增 `intensityFromCode()` / `variantFromCode()` / `appIntensity` / `appVariant` |
| `WeatherBackground.qml` | `injectProperties` 新增 `variant` 绑定 |
| `*Bg.qml` (6个) | 新增 `property real variant: 0` |
| `shaders/rain.frag` | 新增 thunder + hail 分支 |
| `shaders/fog.frag` | 新增 haze + sand 色调分支 |
| `shaders/snow.frag` | 新增 mixed rain/snow 分支 |
| `shaders/cloudy.frag` | 新增 coverage 级别分支 |
| `WeatherBackgroundDebugPanel.qml` | 新增变体选择器（动态选项） |

---

#### 10.12.9 映射完整性验证

| 原始码范围 | 数量 | type | intensity 范围 | variant |
|-----------|:---:|------|:---:|:---:|
| 100 | 1 | sunny | 0.5 | 0 |
| 101, 102, 103, 104 | 4 | cloudy | 0.3–0.8 | 0–2 |
| 150, 151, 152, 153 | 4 | night | 0.5 | 0 |
| 300–304, 350, 351 | 7 | rain | 0.5–0.8 | 0/1/3 |
| 305–318 | 14 | rain | 0.2–1.0 | 0/2 |
| 399 | 1 | rain | 0.5 | 0 |
| 400–403 | 4 | snow | 0.2–1.0 | 0 |
| 404–406, 456 | 4 | snow | 0.4 | 1 |
| 407, 408–410, 457, 499 | 7 | snow | 0.2–1.0 | 0 |
| 500–515 | 14 | fog | 0.2–1.0 | 0/1/2 |
| 900, 901, 999 | 3 | sunny | 0.5 | 0 |

**全部 68 种天气码均映射到有意义的 (type, intensity, variant) 三元组，零信息损失。**

---

#### 10.12.10 实施阶段更新

| 阶段 | 新增内容 |
|------|---------|
| A | Manager 新增 `intensityFromCode()` + `variantFromCode()`；WeatherBackground 注入 `variant` |
| B | 每个 shader 实现 variant 分支（rain: thunder+hail / fog: haze+sand / snow: mixed / cloudy: coverage levels） |
| C | DebugPanel 新增变体选择器，根据当前 type 动态显示选项 |
| D | 68 个天气码全覆盖验证：每个码 → 三元组 → shader 效果正确 |

---

#### 10.12.11 方案演进总览

| 版本 | 过渡方式 | 参数维度 | 信息保真度 | 天气码覆盖 |
|------|---------|---------|:---:|:---:|
| V1 | opacity crossfade | type (6种) | 低 — 68→6 粗暴映射 | ✅ 6 类 |
| V2 | transitionProgress 过程式 | type + intensity + windSpeed | 中 — 密度有差异但变体丢失 | ✅ 6 类 |
| **V2.1** | transitionProgress 过程式 | **type + intensity + variant** | **高 — 雷暴/冰雹/霾/沙尘/雨夹雪 全部保留** | ✅ **68 码逐码映射** |

---

### 10.13 天文天空模型（V2.2）

> 不再只是"天气背景"，而是**天气+天文的完整天空模拟系统**。
> 根据日出日落时间 + 当前时间，计算太阳位置/颜色/光晕角度/天空时变色渐变/月相。
> Manager 每 60s 重新计算 SunSkyParams，通过 uniform 传给 shader。

---

#### 10.13.1 核心参数：sunProgress

```
nowMinutes = currentTime.hours * 60 + currentTime.minutes
sunriseMinutes = parse("05:42") → 342
sunsetMinutes  = parse("19:12") → 1152

sunProgress = (nowMinutes - sunriseMinutes) / (sunsetMinutes - sunriseMinutes)
// 0.0 = 日出,  0.5 = 正午,  1.0 = 日落
// <0 = 日出前, >1 = 日落后
```

---

#### 10.13.2 天空色模型：7 时段 × 3 色

| # | 时段 | sunProgress | 天顶 (skyTop) | 地平线 (skyHorizon) | 下方 (skyBottom) |
|:---:|------|:---:|------|------|------|
| 1 | 深夜 | < -0.3 | `#0a0a1a` | `#0d0d28` | `#050510` |
| 2 | 蓝调(日出前) | -0.3 ~ 0.0 | `#1a2a5a` | `#4a3060` | `#0a0a20` |
| 3 | 金粉(日出) | 0.0 ~ 0.15 | `#4a6fa5` | `#f4a460` | `#e07050` |
| 4 | 白天 | 0.15 ~ 0.7 | `#4a90d9` | `#87ceeb` | `#c8e0f0` |
| 5 | 暖午后 | 0.7 ~ 0.9 | `#5a8ab5` | `#d4996a` | `#c0b0a0` |
| 6 | 橙红(日落) | 0.9 ~ 1.0 | `#3a5a8a` | `#e07840` | `#a03030` |
| 7 | 紫调(日落后) | 1.0 ~ 1.3 | `#2a1a4a` | `#602040` | `#0a0a20` |
| →1 | 回深夜 | > 1.3 | 同 1 | 同 1 | 同 1 |

> 地平线色时段最敏感（金粉→亮蓝→橙红→紫），天顶色相对保守（深蓝↔浅蓝），下方色最暗。
> 各时段之间用 `mix()` 平滑过渡。天气类型在此基础上调整饱和度和亮度。

---

#### 10.13.3 太阳位置与颜色

```qml
// Manager 计算逻辑
angle = (sunProgress - 0.5) * π              // -π/2(dusk) ~ +π/2(dawn)
sunX = 0.5 + sin(angle) * 0.55              // 屏幕横向: 左→中→右
sunY = 0.7 - cos(angle) * 0.5              // 屏幕纵向: 地平→天顶→地平

elevation = cos(angle)                       // 0=地平线, 1=天顶(正午)

// 太阳颜色: 低角→橙红, 高角→亮白
sunColor = mix(#ff6633, #fffff0, sqrt(elevation))

// 光晕半径: 近地平线更大
sunGlow = 0.04 + (1.0 - elevation) * 0.15
```

---

#### 10.13.4 月亮模型

**可见性**：夜晚(sunProgress<0 或 >1+twilight)→可见 / twilight期间→淡入淡出 / 白天→不可见

**位置**：与太阳对跖（antipodal），太阳落下时月亮在对面升起

```qml
moonAngle = (sunProgress + 0.5) * π        // 与太阳相位差半圈
moonX = 0.5 + sin(moonAngle) * 0.45
moonY = 0.75 - cos(moonAngle) * 0.45      // 轨道略低于太阳
```

**月相**（weatherApi.astronomyMoon 返回 800~807）：

| 代码 | 月相 | Shader 渲染 |
|:---:|------|------|
| 800 | 新月 | 几乎不可见（仅暗色轮廓） |
| 801 | 蛾眉月 | 右侧细弯亮 |
| 802 | 上弦月 | 右半亮 |
| 803 | 盈凸月 | 右侧大半亮 |
| 804 | 满月 | 正圆全亮，最强月光 |
| 805 | 亏凸月 | 左侧大半亮 |
| 806 | 下弦月 | 左半亮 |
| 807 | 残月 | 左侧细弯亮 |

Shader 用 `moonPhase` (0-7) 生成月牙 SDF：
```glsl
float moonMask = abs(length(uv - moonPos) - 0.05) < 0.005 ? 1.0 : 0.0;
// 按 moonPhase 裁剪左右半圆
float phaseCut = mix(1.0, -1.0, moonPhase / 7.0) * 0.05;
// moonIllum (0-1) 控制亮度
```

---

#### 10.13.5 各天气背景的天文融合

| 背景 | 天空基 | 太阳 | 天气叠加 | 夜间 |
|------|--------|------|---------|------|
| SunnyBg | 时变三色 | 完整光晕+光线 | 无 | → NightBg |
| CloudyBg | 时变(低饱和) | 被云遮挡(漫射) | 云噪声 | → NightBg(多云) |
| RainBg | 时变×暗化0.4 | 不可见 | 雨丝+闪电 | 同白天但更暗 |
| SnowBg | 时变×冷化 | 漫射光晕 | 雪花 | 同白天,月亮朦胧可见 |
| NightBg | 深蓝黑+星空 | 无 | 无 | 月亮渲染 |
| FogBg | 时变×去饱和0.3 | 不可见 | 雾气带 | 同白天但更暗 |

**关键**：太阳和月亮不同时可见。白天 shader 渲染太阳光晕，夜晚 shader 渲染月亮。CloudyBg→NightBg 切换时（isNight 触发），太阳淡出+星空淡入+月亮淡入，800ms transitionProgress 驱动。

---

#### 10.13.6 数据流

```
focusId 变更:
  Main.qml → weatherApi.astronomySun(focusId, today, focusId)
           → weatherApi.astronomyMoon(focusId, today, focusId)

astronomySunReady(cityId, json):
  if cityId == focusId:
    Manager.receiveSun(json.sunrise, json.sunset)

astronomyMoonReady(cityId, json):
  if cityId == focusId:
    Manager.receiveMoon(json.moonPhase[0].icon, json.moonPhase[0].illumination)

Timer(60s):
  Manager.updateSunSkyParams():
    计算 sunProgress, sunX/Y, sunColor, sunGlow,
          skyTop/Horizon/Bottom, isTwilight, isNight,
          moonX/Y, moonVisible
    → 写入 Manager 只读属性
    → WeatherBackground Qt.binding → shader uniforms 自动更新
```

---

#### 10.13.7 完整 Shader Uniform 接口（全量 25 个）

```glsl
layout(std140, binding=0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    // === 动画 (2) ===
    float time;
    float transitionProgress;
    // === 天气 (3) ===
    float intensity;          // 粒子密度 0.0~1.0
    float windSpeed;          // 动画速度 0.0~1.0
    float variant;            // 变体 0/1/2/3 (shader内int(v+0.5)转整)
    // === 天文/时间 (9) ===
    float sunProgress;        // 0=dawn, 0.5=noon, 1=dusk
    float sunX, sunY;         // 屏幕太阳位置 [0,1]
    vec4  sunColor;           // 太阳光晕颜色
    float sunGlow;            // 光晕半径
    vec4  skyTop;             // 天顶色
    vec4  skyHorizon;         // 地平线色
    vec4  skyBottom;          // 下方色
    float isNight;            // 0 or 1
    float isTwilight;         // 0 or 1
    // === 月亮 (5) ===
    float moonVisible;        // 0 or 1
    float moonX, moonY;       // 屏幕月亮位置
    float moonPhase;          // 0-7 (对应 icon 800-807)
    float moonIllum;          // 0-1 月面亮度
    // === 交互 (2) ===
    float parallaxX;
    float parallaxY;
} ubuf;
// 25 个 uniform ≈ 100 字节/帧 — GPU 开销可忽略
```

---

### 10.14 性能分析

#### 10.14.1 各背景 GPU 负载

| 背景 | 每像素运算 | 粒子循环上限 | 分支 | 估算负载 |
|------|-----------|:---:|------|:---:|
| SunnyBg | 渐变 + 光晕 + 光线 | 0 | 无 | 极轻 |
| CloudyBg | 渐变 + 2-3 层 fBM 噪声 | 0 | 无 | 轻 |
| RainBg | 渐变 + 雨丝 + 闪电分支 + 冰雹分支 | **60** | uniform 一致 | **最重** |
| SnowBg | 渐变 + 雪花 + 雨夹雪分支 | **60** | uniform 一致 | 重 |
| NightBg | 渐变 + 星空 + 月牙 SDF | 50 | 无 | 中 |
| FogBg | 渐变 + 2-3 条雾气带 | 0 | 无 | 轻 |

> 60 次循环 × 1920×1080 = ~124M 迭代/帧。桌面 GPU 无压力，集显/4K 是风险点。

#### 10.14.2 三个优化策略

**A. Uniform 分支 → 零发散惩罚**

`intensity` 和 `transitionProgress` 是 uniform（同帧所有像素值相同），GPU warp 内 100% 一致：

```glsl
// 同帧所有像素走同一条路径 — 零 warp divergence
if (ubuf.intensity * ubuf.transitionProgress > 0.001) {
    for (int i = 0; i < MAX_DROPS; i++) {
        if (i >= dropLimit) break;  // uniform break，无发散
        // 粒子循环
    }
}
```

`transitionProgress=0` 或 `intensity=0` 时整帧跳过循环。旧层退出时 tp→0 自动轻载。

**B. 分档粒子上限**

```qml
// AppSettings 新增
property int perfLevel: 2   // 0=低配, 1=中配, 2=高配
```

| 档位 | Rain 粒子 | Snow 粒子 | Night 星星 | 4K@60fps | 适用场景 |
|:---:|:---:|:---:|:---:|:---:|------|
| 高(2) | 60 | 60 | 50 | 独显 | 桌面独显 |
| 中(1) | 40 | 40 | 35 | 集显 | 桌面集显/笔记本 |
| 低(0) | 20 | 20 | 20 | 嵌入 | 嵌入式/低端集显 |

Shader 循环上限不变（编译时常量 `MAX_DROPS=60`），用 uniform 控制 break 点：

```glsl
const int MAX_DROPS = 60;                  // 编译时常量，不变
int dropLimit = int(ubuf.particleLimit);   // uniform 传入 20/40/60
for (int i = 0; i < MAX_DROPS; i++) {
    if (i >= dropLimit) break;             // uniform break，无 warp 发散
    // ...
}
```

**C. 天文计算开销 → 极轻**

Manager `updateSunSkyParams()` 每 60s 调一次：若干 `parseInt` + 2 次 `sin/cos` + 7 行 `mix` 查表。即使在 JS 中也不到 0.1ms。uniform 传参 25 个 float = 100 字节/帧。

#### 10.14.3 过渡期间峰值

双层 shader 并行时（800ms）：

- 旧层 tp→0 → `intensity*tp < 0.001` → 整个粒子循环跳过 → **仅渲染天空渐变（极轻）**
- 新层 tp→0 时同理（粒子还未入场）
- 实际峰值：单层满负荷 + 另一层几乎空载 → **不翻倍**

#### 10.14.4 性能结论

| 风险 | 等级 | 对策 |
|------|:---:|------|
| 粒子循环 (60×FHD) | 中 | 分档粒子上限 + uniform break 零发散 |
| 双层 ShaderEffect 并行 | 低 | tp=0 层自动跳过循环 |
| 天文计算 | 无 | 60s 一次 <0.1ms |
| uniform 带宽 | 无 | 25 × 4B = 100 字节 |
| 4K 显示 | 需验证 | 建议中配(40粒子)起步，4K 低配(20粒子) |
| DebugPanel 实时调参 | 无 | 只改 parameter→uniform，不触发 shader 重编译 |

**结论：完全可控。** 高配 60 粒子稳 60fps，低配降至 20 粒子稳 30fps。唯一运行时变量是粒子上限，通过 `AppSettings.perfLevel` 调节。

---

### 10.15 方案演进总览（全版本）

| 版本 | 过渡 | 天气维度 | 天文维度 | Shader | perf |
|------|------|------|------|:---:|:---:|
| V1 | opacity crossfade | type (6) | 无 | 6 个 | — |
| V2 | transitionProgress 过程式 | type + intensity + windSpeed | 无 | 6 个 | — |
| V2.1 | transitionProgress 过程式 | **type + intensity + variant** | 无 | 6 个 | — |
| **V2.2** | transitionProgress 过程式 | type + intensity + variant | **sunProgress + sunX/Y + sunColor + sunGlow + skyTop/Horizon/Bottom + isNight/Twilight + moonX/Y + moonPhase + moonIllum** | 6 个 + **25 uniform** | 分档

