uniform vec3 iResolution;
uniform float iTime;
uniform float iTimeDelta;
uniform int iFrame;
uniform vec4 iMouse;
#define fragColor gl_FragColor
#define fragCoord gl_FragCoord.xy
#define _MousePosition iMouse
#define _XCellCount 15.0

vec4 _LineColor = vec4(0.0, 0.1, 0.9, 0.8);
vec4 _LineDrawRange = vec4(2.0, 0.5, 0.0, 1.0);
vec4 _LineWidthRange = vec4(0.015, 0.01, 0.0, 0.0);
vec4 _SparkleColor = vec4(0,0,1,1);
vec4 _SparkleDrawIntensity = vec4(100.0, 100.0, 0.0, 1.0);
float _Speed = 1.0;
float _CenterDriftRange = 0.5;

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

    float mousePosDistance = distance(uv, iMouse.xy);
    float mouseSmoothing = smoothstep(_MousePosition.w, 0.0, mousePosDistance) / 2.0;

    mouseSmoothing = min(1.0, -log(-mouseSmoothing + 1.0));

    float mouseInfluence = max(0.025, mouseSmoothing);

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
            p[1] = GetPos(id, vec2(x, y), mouseInfluence);

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

#if 0 // Draw sparkle online on top of the line
        sparkle *= m;
#endif

        r += sparkle;// * m;// + abs(m)/3;
    }


    m += drawLine(gv, p[1], p[3]);
    m += drawLine(gv, p[1], p[5]);
    m += drawLine(gv, p[7], p[3]);
    m += drawLine(gv, p[7], p[5]);

    return vec2(m,r);
}


void main()
{
    vec2 uv = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;
// }
// fixed4 frag (v2f i) : SV_Target
// {
//     vec2 uv = (i.uv - 0.5) * vec2((_AspectRatio.x/_AspectRatio.y), 1);

#if 0
    float t = _Time.x;

    float m = 0;
    float r = 0;

    for(float i = 0; i <= 1; i += 1.0/4.0) {
        float z = fract(i+t);
        float size = lerp(1.0, 0.5, z);

        vec2 layCol = layer(uv*size+i*20.0);

        m+= layCol.x;
        m+= layCol.y;
    }
#else 
    vec2 layCol = layer(uv);
    float m = layCol.x;
    float r = layCol.y;
#endif

#if 1
    vec4 col = (m * _LineColor) + (r * _SparkleColor);// * avgLength);// * _LineColorSparkleMultiplier);
#endif

    fragColor = col;//fixed4(col,1);;
}