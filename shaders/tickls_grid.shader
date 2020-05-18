#define _MousePosition iMouse
#define _XCellCount 38.0

vec4 _LineColor = vec4(1, 1, 1, 0.8);
vec4 _LineColor2 = vec4(0.1, 0.1, 0.1, 1);
vec4 _LineDrawRange = vec4(2.0, 0.5, 0.0, 1.0);
vec4 _LineWidthRange = vec4(0.04, 0.02, 0.0, 0.0);
vec4 _SparkleColor = vec4(0.1,0.1,0.1,1);
//vec4 _SparkleColor = vec4(0.2,0.3,0.9,1);
vec4 _HighlightColor = vec4(0.25, 0.0, 0.0, 0.0);
vec4 _SparkleDrawIntensity = vec4(500.0, 500.0, 0.0, 1.0);

float _Speed = 2.0;
float _CenterDriftRange = 0.9;

float distToLine(vec2 p, vec2 a, vec2 b) {
    vec2 pa = p - a;
    vec2 ba = b - a;
    float t = clamp(dot(pa, ba) / dot(ba, ba), _LineDrawRange.z, _LineDrawRange.w);

    return length(pa - ba*t);
}

float N21(vec2 p) {
    float mult = iTime / 100.0;

    p = fract(p * vec2(237.74, 1201.17));
    p += dot(p, p+85.51);

    return fract(p.x*p.y);
}

vec2 N22(vec2 p) {
    float n = N21(p);

    return vec2(n, N21(p+n));
}

vec2 GetPos(vec2 id, vec2 offset, float driftRange) {

    vec2 n = N22(id+offset) * iTime * _Speed;
    return offset + sin(n) * _CenterDriftRange * driftRange;

    //float x = sin(_Time.y * n.x);
    //float y = cos(_Time.y * n.y);

    //return vec2(x,y) * 0.45;
}

float drawLine(vec2 p, vec2 a, vec2 b) {
    float d = distToLine(p, a, b);
    float m = smoothstep(_LineWidthRange.x, _LineWidthRange.y, d);

    float d2 = length(a-b);
    m *= smoothstep(_LineDrawRange.x, _LineDrawRange.y, length(a-b))
#if 1 // Flash line
        *0.5 + smoothstep(0.1, 0.01, abs(d2 - 0.6));
#endif
    ;

    return m;
}

vec2 layer(vec2 uv) {

    vec2 mousePos = ((iMouse.xy - 0.5 * iResolution.xy) / iResolution.y);
    mousePos.y = -mousePos.y;
    float mousePosDistance = length(uv - mousePos);
    
    float mouseSmoothing = min(1.0, -log(-mousePosDistance + 1.0));
    float mouseInfluence = 0.5 - min(mouseSmoothing, 0.5);// max(0.025, 4.0);

    float m = 0.0;//smoothstep(0.1, 0.05, d);
    float r = 0.0;

    uv *= _XCellCount / 2.0;

    vec2 gv = fract(uv) - 0.5;
    vec2 id = floor(uv);
    //vec2 pos = GetPos(id);// N22(id) - 0.5;

    //float d = length(gv - pos);
    //m = smoothstep(0.05, 0.01, d);

    vec2 p[9];
    int j = 0;

    float avgLength = 0.0;

    for(float y = -1.0; y <= 1.0; y++) {
        for(float x = -1.0; x <= 1.0; x++) {
            p[j] = GetPos(id, vec2(x, y), mouseInfluence*1.5);

            avgLength += distance(gv, p[j]);

            j++;
        }
    }

    avgLength /= 9.0;
    avgLength = -log(-avgLength+1.0) / 10.0;


    for(int i = 0; i < 9; i++) {
        float lineCol = drawLine(gv, p[4], p[i]);

        m += lineCol;

        vec2 j = (p[i]-gv);

#if 0 // Dynamic sparkling sparkles
        float sparkle = 1 / dot(j*_SparkleDrawIntensity.y, j*_SparkleDrawIntensity.y); // Outer Glow

        r += sparkle * abs( (sin(_Time.z + fract(p[i].x) * 10.0) * 2 + 0.5) );
#endif

#if 1// Fixed sparkle size
        float sparkle = 1.0 / length(j*_SparkleDrawIntensity.x); // Center Glow // dot(j, j);//length(j);
        sparkle += (1.0 / dot(j*_SparkleDrawIntensity.y, j*_SparkleDrawIntensity.y)); // Outer Glow
#endif

#if 1 // Draw sparkle online on top of the line
        sparkle *= m;
#endif

        r += sparkle;// * m;// + abs(m)/3;
    }


    m += drawLine(gv, p[1], p[3]);
    m += drawLine(gv, p[1], p[5]);
    m += drawLine(gv, p[7], p[3]);
    m += drawLine(gv, p[7], p[5]);

//    m += _HighlightColor * mouseInfluence;

    return vec2(m, r + mouseInfluence * _HighlightColor.r);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 mousePos = ((iMouse.xy - 0.5 * iResolution.xy) / iResolution.y);
    mousePos.y = -mousePos.y;

    vec2 uv = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;

    float mouseDist = min(distance(mousePos, uv), 1.0);

    vec2 layCol = layer(uv);
    float m = layCol.x;
    float r = layCol.y;

#if 1
    vec4 col = mix((m * _LineColor), m * _LineColor2, 0.5 + mouseDist * 0.9);// + (r * _SparkleColor);// * avgLength);// * _LineColorSparkleMultiplier);
#endif

    fragColor = col;//fixed4(col,1);;
}