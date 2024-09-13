#ifdef GL_ES
precision mediump float;
#endif



#define PI 3.1415926535

uniform float fadeLength;
uniform float fadeStart;

uniform mat4 modelviewMatrix;
uniform mat4 transformMatrix;
uniform mat3 normalMatrix;
uniform mat4 texMatrix;

varying vec4 vertTexCoord;
varying vec4 vertColor;

attribute vec4 position;
attribute vec4 color;
attribute vec3 normal;
attribute vec2 texCoord;




uniform float ambient;
uniform float reffect;
uniform float geffect;
uniform float beffect;



uniform vec3 lightDirection;

void main(void)
{  
    gl_Position = transformMatrix * position;


    float z = gl_Position.z;
    float opacity = clamp(1.0-((z-fadeStart) / fadeLength), -1.0, 1.0);


    // Lighting
    float dp = (normal.x * lightDirection.x + normal.y * lightDirection.y + normal.z * lightDirection.z);
    
    float c = ((dp*2. + 2.) / 2.)*1.0-1.0;
    vertColor = color*vec4(ambient+clamp((c*reffect), 0.0, 1000.), ambient+clamp((c*geffect), 0.0, 1000.), ambient+clamp((c*beffect), 0.0, 1000.), opacity);
        

    vertTexCoord = vec4(texCoord.x, texCoord.y, 0.0, 1.0);
}