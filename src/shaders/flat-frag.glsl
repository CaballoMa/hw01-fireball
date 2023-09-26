#version 300 es
precision highp float;

uniform float u_Time;
uniform vec4 u_InCircleColor;
uniform vec4 u_OutCircleColor;
in vec4 fs_Pos;
out vec4 out_Col;

const float PI = 3.14159265359;

float noise(vec3 uv, float res)
{
	const vec3 s = vec3(1e0, 1e2, 1e4);
	
	uv *= res;
	
	vec3 uv0 = floor(mod(uv, res))*s;
	vec3 uv1 = floor(mod(uv+vec3(1.), res))*s;
	
	vec3 f = fract(uv); f = f*f*(3.0-2.0*f);
	
	vec4 v = vec4(uv0.x+uv0.y+uv0.z, uv1.x+uv0.y+uv0.z,
		      	  uv0.x+uv1.y+uv0.z, uv1.x+uv1.y+uv0.z);
	
	vec4 r = fract(sin(v*1e-3)*1e5);
	float r0 = mix(mix(r.x, r.y, f.x), mix(r.z, r.w, f.x), f.y);
	
	r = fract(sin((v + uv1.z - uv0.z)*1e-3)*1e5);
	float r1 = mix(mix(r.x, r.y, f.x), mix(r.z, r.w, f.x), f.y);
	
	return mix(r0, r1, f.z)*2.-1.;
}

vec2 computeFadeAndP(vec2 uv, float aspectRatio) {
    vec2 p = -0.5 + uv;
    p.x *= aspectRatio;
    float fade = pow(length(2.0 * p), 0.5);
    return vec2(fade, p.x);
}

float accumulatedNoise(vec3 coord, float scaledTime, float brightness, float temporalNoise, float scale) {
    float result = 1.0;
    for(int i = 1; i <= 7; i++) {
        float power = pow(2.0, float(i + 1));
        result += (0.5 / power) * noise(coord + vec3(0.0, -scaledTime, scaledTime * 0.2), 
                                        power * scale * (temporalNoise + 1.0));
    }
    return result;
}

float computeCorona(float accumNoise, float fade) {
    return pow(accumNoise * max(1.1 - fade, 0.0), 2.0) * 50.0;
}

void main() {
    float brightness = 0.0;
    float aspectRatio = 8.0 / 6.0;
    vec2 uv = gl_FragCoord.xy / vec2(1600., 1200.);
	uv.y += 0.13;
    vec2 fadeAndP = computeFadeAndP(uv, aspectRatio);

    float fade = fadeAndP.x;
    vec2 p = vec2(fadeAndP.y, uv.y - 0.55);
    float angle = atan(p.x, p.y) / PI;
    float scaleFactor = 1.;
	float distance = length(p) * scaleFactor;

    vec3 coord = vec3(angle, distance, u_Time * 0.01 * 0.1);

    float temporalNoise1 = abs(noise(coord + vec3(0.0, -u_Time * 0.01 * (0.35 + brightness * 0.001), u_Time * 0.01 * 0.015), 15.0));
    float temporalNoise2 = abs(noise(coord + vec3(0.0, -u_Time * 0.01 * (0.15 + brightness * 0.001), u_Time * 0.01 * 0.015), 45.0));

    float accumNoise1 = accumulatedNoise(coord, u_Time * 0.01, brightness, temporalNoise1, 10.0);
    float accumNoise2 = accumulatedNoise(coord, u_Time * 0.01, brightness, temporalNoise2, 25.0);

    float coronaEffect1 = computeCorona(accumNoise1, fade);
    float coronaEffect2 = computeCorona(accumNoise2, fade);

    vec2 sp = -1.0 + 2.0 * uv;
    sp.x *= aspectRatio;
    sp *= (2.0 - brightness);
    float r = dot(sp, sp);
    float brightnessFactor = (1.0-sqrt(abs(1.0-r)))/r + brightness * 0.5;

    vec3 starSphere = vec3(0.0);
	
    if(distance < brightness) {
        coronaEffect1 *= pow(distance / brightness, 24.0);
        vec2 newUv = sp * brightnessFactor + vec2(u_Time * 0.01, 0.0);
        starSphere = vec3(newUv, 1.0);
    }

	float circleScale = 0.04;
    float starGlow = min(max(1.0 - distance, 0.0), 1.0);
    out_Col.rgb = vec3(brightnessFactor * (0.75 + brightness * 0.3) * vec3(u_InCircleColor)) + 
                  starSphere + (coronaEffect1 + coronaEffect2) * vec3(u_InCircleColor) * circleScale + starGlow * vec3(u_OutCircleColor);
    out_Col.a = 1.0;
}