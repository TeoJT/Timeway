#ifdef GL_ES
precision mediump float;
precision mediump int;
#endif

uniform sampler2D texture;

varying vec4 texSamplePoint;
varying vec4 vertColor;
varying vec4 vertTexCoord;

void main() {
  //vec3 c = texture2D(img, texSamplePoint.xy).rgb;
  gl_FragColor = texture2D(texture, texSamplePoint.st) * vertColor;
  //gl_FragColor = vec4(c.rgb, 1.0) * vertColor;
  //gl_FragColor = vec4(1.0, 0.0, 0.0, 1.0);
}