#ifdef GL_ES
precision mediump float;
precision mediump int;
#endif

uniform sampler2D img;
varying vec4 texSamplePoint;


void main() {
  vec3 c = texture2D(img, texSamplePoint.xy).rgb;
  gl_FragColor = vec4(c.rgb, 1.0);
  //gl_FragColor = vec4(1.0, 0.0, 0.0, 1.0);
}