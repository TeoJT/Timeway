#ifdef GL_ES
precision mediump float;
#endif



#define PI 3.1415926535

uniform sampler2D texture;
uniform float fadeLength;
uniform float fadeStart;
varying vec4 vertTexCoord;
varying vec4 vertColor;





void main(void)
{
    float z = gl_FragCoord.z / gl_FragCoord.w;
    float opacity = clamp(1.0-((z-fadeStart) / fadeLength), 0.0, 1.0);
    gl_FragColor = texture2D(texture, vertTexCoord.xy) * vertColor * vec4(1.0, 1.0, 1.0, opacity);
}