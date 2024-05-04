
uniform mat4 transformMatrix;
uniform mat4 texMatrix;

attribute vec4 position;
attribute vec2 texCoord;

varying vec4 texSamplePoint;

void main() {
  gl_Position = transformMatrix * position;
    

  texSamplePoint = texMatrix * vec4(texCoord, 1.0, 1.0);
}