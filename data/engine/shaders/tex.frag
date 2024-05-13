#ifdef GL_ES
precision mediump float;
precision mediump int;
#endif

#define PI 3.1415926535

uniform sampler2D texture;
uniform int mode;
uniform float fadeLength;
uniform float fadeStart;

varying vec4 texSamplePoint;
varying vec4 vertColor;
varying vec2 fragPos;



// For the portal
uniform float u_dir;
uniform float u_time;

float intensity = 0.043;
float frequency = 15.0;
const float xpos = 0.;

const float speed = 1.0;


float pixelate(float o, float res) {
    return (floor(o*res))/res;
}

const vec2 pixels = vec2(4096., 4096.);


void main(void) {
  // MODE_COLOR_TEX
  if (mode == 1) {
  	gl_FragColor = texture2D(texture, texSamplePoint.st) * vertColor;
  }
  // MODE_FOG_UNLIT
  else if (mode == 2) {
	float z = gl_FragCoord.z / gl_FragCoord.w;
    	float opacity = clamp(1.0-((z-fadeStart) / fadeLength), 0.0, 1.0);
    	gl_FragColor = texture2D(texture, texSamplePoint.xy) * vertColor * vec4(1.0, 1.0, 1.0, opacity);
  }
  // MODE_PORTAL
  else if (mode == 3) {
    vec2 st = fragPos.xy;
    vec2 tt = texSamplePoint.xy;
    vec2 oooo = +(gl_FragCoord.xy/pixels.xy);
    tt.x += oooo.x;
    tt.y -= oooo.y;
    st.y += 0.05;
    
    float ti = u_time*speed;
    float t = (ti-floor(ti))*PI;
    
    tt.x += u_dir;
    
    float wobble = cos((st.y+st.x)*frequency*2.+t) * intensity * sin(st.x*frequency + t);
    
    //Create a position vector
    vec2 p = vec2(((st.x)-xpos)-wobble, st.y-wobble*1.5);
    
    float img = sin(clamp(p.x*PI, 0., PI))*sin(clamp(p.y*PI, 0., PI))*2.;
    float b = pixelate(img, 3.516);
    vec3 color = vec3(b*1.160, b, b*2.);
    float opacity = color.b;
    
    color *= color.g >= 0.99 ? texture2D(texture, tt).rgb : vec3(1.0);
    
    gl_FragColor = vec4(color, opacity) * vertColor;

    // vec2 tt = texSamplePoint.st;
    // vec3 color = texture2D(texture, tt).rgb;
    // gl_FragColor = vec4(color, 1.0); 
  }
  // MODE_TEX
  else {
  	gl_FragColor = texture2D(texture, texSamplePoint.st);
  }

}