#ifdef GL_ES
precision mediump float;
#endif



#define PI 3.1415926535

uniform sampler2D texture;
varying vec4 vertTexCoord;
varying vec4 vertColor;



void main(void)
{
    gl_FragColor = texture2D(texture, vertTexCoord.xy) * vertColor;
}