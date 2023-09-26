#version 300 es
precision highp float;

// Uniforms
uniform mat4 u_Model;
uniform mat4 u_ViewProj;
uniform float u_Time;

// Vertex attributes
in vec4 vs_Pos;
in vec4 vs_Nor;

// Outputs to the fragment shader
out vec4 fs_Pos;

// Constants
const int OCTAVES = 4;

// Helper functions for generating noise

float hash(float p) { p = fract(p * 0.011); p *= p + 7.5; p *= p + p; return fract(p); }

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

float fbm (in vec3 st) {
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

float ease_in_quadratic(float t){
    return t *t;
}

float ease_in_out_quadratic(float t){
    if(t < 0.5)
        return ease_in_quadratic(t*2.0)/2.0;
    else
        return 1.0 - ease_in_quadratic(t*2.0)/2.0;
}

void main()
{
    vec4 deform = vs_Nor * (sin(40.f * fbm(vs_Pos.xyz) * float(sin(u_Time * 0.01))) + 1.0 / 2.f) * 0.05f;
    vec4 deformLF = vs_Nor * (sin(fbm(vs_Pos.xyz) * float(sin(u_Time * 0.02))) + 1.0 / 2.f) * 0.5f;

    vec4 scaledPos = vec4(vs_Pos.xyz * 1., 1.0);
    vec4 translatedPos = scaledPos;

    vec4 deformedPos = translatedPos + deform + deformLF;
    fs_Pos = u_Model * deformedPos;
    gl_Position = u_ViewProj * fs_Pos;
}

