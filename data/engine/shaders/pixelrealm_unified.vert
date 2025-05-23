uniform mat4 transformMatrix;
uniform mat4 texMatrix;
uniform mat3 normalMatrix;

attribute vec4 color;
attribute vec4 position;
attribute vec2 texCoord;
attribute vec3 normal;

varying vec4 vertColor;
varying vec4 vertTexCoord;

uniform vec4  tintColor;
uniform float time;
uniform float ambient;
uniform float reffect;
uniform float geffect;
uniform float beffect;
uniform float fadeLength;
uniform float fadeStart;
uniform vec3 lightDirection;

uniform int mode;
#define MODE_STANDARD 1
#define MODE_ENV 2
#define MODE_PORTAL 3
#define MODE_WATER 4
#define MODE_TEST 5

void main() {
  gl_Position = transformMatrix * position;
  
  float z = gl_Position.z;
  float opacity = clamp(1.0-((z-fadeStart) / fadeLength), -1.0, 1.0);
  
  if (mode == MODE_STANDARD || mode == MODE_TEST) {
	vertTexCoord = vec4(texCoord, 1.0, 1.0) * texMatrix;
    vertColor = color*tintColor;
  }
  else if (mode == MODE_ENV || mode == MODE_WATER) {
    // Lighting
    float dp = (normal.x * lightDirection.x + normal.y * lightDirection.y + normal.z * lightDirection.z);
    
    float c = ((dp*2. + 2.) / 2.)*1.0-1.0;
    vertColor = color * vec4(ambient+clamp((c*reffect), 0.0, 1000.), ambient+clamp((c*geffect), 0.0, 1000.), ambient+clamp((c*beffect), 0.0, 1000.), opacity) * tintColor;
	
    vertTexCoord = vec4(texCoord, 0.0, 1.0);
	if (mode == MODE_WATER) {
		vertTexCoord = vec4(texCoord+vec2(time*0.1), 0.0, 1.0);
	}
  }
  else if (mode == MODE_PORTAL) {
	vertTexCoord = vec4(texCoord, 1.0, 1.0) * texMatrix;
    vertColor = color*vec4(1.0, 1.0, 1.0, opacity)*tintColor;
  }
  else {
    vertTexCoord = vec4(0.0);
    vertColor = vec4(0.0)*tintColor;
  }
    
}