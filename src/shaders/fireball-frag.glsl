#version 300 es
precision highp float;

#define OCTAVES 5

uniform float u_Time;
uniform float u_EyeDistance;
uniform vec4 u_InFireBallColor;
uniform vec4 u_OutFireBallColor;

in vec4 fs_Pos;
in vec4 fs_Nor;

out vec4 out_Col;


float hash(float p) { p = fract(p * 0.011); p *= p + 7.5; p *= p + p; return fract(p); }
vec2 hash(vec2 p) {
    p = vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)));
    return fract(sin(p) * 18.5453);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(mix(dot(hash(i + vec2(0.0, 0.0)), f - vec2(0.0, 0.0)), 
                   dot(hash(i + vec2(1.0, 0.0)), f - vec2(1.0, 0.0)), u.x),
               mix(dot(hash(i + vec2(0.0, 1.0)), f - vec2(0.0, 1.0)), 
                   dot(hash(i + vec2(1.0, 1.0)), f - vec2(1.0, 1.0)), u.x), u.y);
}

float noise(vec3 x) {
    const vec3 step = vec3(110, 241, 171);

    vec3 i = floor(x);
    vec3 f = fract(x);
 
    float n = dot(i, step);

    vec3 u = f * f * (3.0 - 2.0 * f);
    return mix(mix(mix( hash(n + dot(step, vec3(0, 0, 0))), hash(n + dot(step, vec3(1, 0, 0))), u.x),
                   mix( hash(n + dot(step, vec3(0, 1, 0))), hash(n + dot(step, vec3(1, 1, 0))), u.x), u.y),
               mix(mix( hash(n + dot(step, vec3(0, 0, 1))), hash(n + dot(step, vec3(1, 0, 1))), u.x),
                   mix( hash(n + dot(step, vec3(0, 1, 1))), hash(n + dot(step, vec3(1, 1, 1))), u.x), u.y), u.z);
}

float fbm (vec3 st) {
    float value = 0.0;
    float amplitude = 0.5;
    float frequency = 0.5;

    for (int i = 0; i < OCTAVES; i++) {
        value += amplitude * noise(st * frequency);
        st *= 2.;
        amplitude *= .5;
        frequency *= 1.1;
    }
    return value;
}

void main() {			
    float v = fbm(vec3(fs_Pos) * 8.0);
    
    float distFromCenter = length(fs_Pos.xz);
    float heightFactor = smoothstep(-1.0, 1.0, fs_Pos.y);
    
    vec3 centerColor = vec3(0.8, 0.2, 0.0);
    vec3 lerpColor = mix(centerColor, mix(vec3(u_InFireBallColor), vec3(u_OutFireBallColor), distFromCenter), heightFactor);

    float eyeMovementScale = 0.1;
    float eyeHorizontalMovement = 3. * sin(u_Time * 0.01) * eyeMovementScale;
    float eyeVerticalMovement = 3. * cos(u_Time * 0.01) * eyeMovementScale;

    vec3 eyeColor = vec3(0.005f, 0.005f, 0.005f);
    vec2 leftEyeOriginalCenter = vec2(-u_EyeDistance/10., 0.3);
    vec2 rightEyeOriginalCenter = vec2(u_EyeDistance/10., 0.3);
    float eyeSize = 0.15;

    vec2 leftEyeCenter = leftEyeOriginalCenter + vec2(eyeHorizontalMovement, eyeVerticalMovement);
    vec2 rightEyeCenter = rightEyeOriginalCenter + vec2(eyeHorizontalMovement, eyeVerticalMovement);

    vec2 fs_Pos_2D = fs_Pos.xy;
    fs_Pos_2D = vec2(fs_Pos_2D.x, fs_Pos_2D.y * 1.3);
    float noiseForLeftEye = (noise(leftEyeCenter * 5.0 + vec2(u_Time * 0.01)) + 0.4) * 0.06;
    float noiseForRightEye = (noise(rightEyeCenter * 5.0 + vec2(u_Time * 0.01)) + 0.4) * 0.06;

    float distortedLeftEyeRadius = eyeSize + noiseForLeftEye;
    float distortedRightEyeRadius = eyeSize + noiseForRightEye;

    if (length(leftEyeCenter - fs_Pos_2D) < distortedLeftEyeRadius || length(rightEyeCenter - fs_Pos_2D) < distortedRightEyeRadius) {
        if(length(leftEyeCenter + vec2(eyeHorizontalMovement/7., eyeVerticalMovement/7.) - fs_Pos_2D) < eyeSize/1.4 
        || length(rightEyeCenter + vec2(eyeHorizontalMovement/7., eyeVerticalMovement/7.) - fs_Pos_2D) < eyeSize/1.4)
        {
            lerpColor = vec3(0.0f, 0.0f, 0.0f);
        }
        else
        {
            lerpColor = eyeColor;
        }
    }

    vec3 color = pow(v, 0.5) * 1.3 * normalize(lerpColor);
    out_Col = vec4(color, 1.0);
}

