#ifdef GL_ES
precision mediump float;
#endif

uniform vec4 color;
uniform float intensity;

void main() {
    gl_FragColor = color-(fract(sin(dot((gl_FragCoord.xy), vec2(1.9898, 7.233))) * 43758.5453)*intensity);
}