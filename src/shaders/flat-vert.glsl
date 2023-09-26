#version 300 es
precision highp float;

// The vertex shader used to render the background of the scene
out vec4 fs_Pos;
const vec2 positions[6] = vec2[](
            vec2(-1.0, -1.0),
            vec2(1.0, -1.0), 
            vec2(1.0, 1.0), 
            vec2(1.0, 1.0), 
            vec2(-1.0, -1.0), 
            vec2(-1.0, 1.0)
        ); 



void main()
{
    fs_Pos = vec4(positions[gl_VertexID], 0.99, 1.0);
    gl_Position = fs_Pos;
}
