#ifdef GL_ES
precision mediump float;
#endif



#define PI 3.1415926535

uniform sampler2D texture;
varying vec4 vertTexCoord;
varying vec4 vertColor;


uniform float portalLookDir;
uniform float time;

float intensity = 0.043;
float frequency = 15.0;
const float xpos = 0.;
const float speed = 1.0;

uniform int mode;
#define MODE_STANDARD 1
#define MODE_ENV 2
#define MODE_PORTAL 3
#define MODE_WATER 4


float pixelate(float o, float res) {
    return (floor(o*res))/res;
}

const vec2 pixels = vec2(1500., 221.);



void main(void)
{
	vec4 fragOut;
	vec2 st = vertTexCoord.xy;

    if (mode == MODE_STANDARD) {
		fragOut = texture2D(texture, vertTexCoord.xy) * vertColor;
    }
    else if (mode == MODE_ENV || mode == MODE_WATER) {
		fragOut = texture2D(texture, vertTexCoord.xy) * vertColor;
    }
    else if (mode == MODE_PORTAL) {
		
		
		float aspect = (pixels.x/pixels.y);
		vec2 tt = gl_FragCoord.xy/pixels.xy;
		//tt.x *= 2.;
		tt.y = 1.-tt.y;
		
		//st.x *= u_resolution.x/u_resolution.y;
		//st *= 1.1;
		//st.x *= 2.;
		st.y -= 0.05;

		
		
		float t = time*speed*PI;
		//float t = (ti-floor(ti))*PI;
		
		tt.x += portalLookDir;
		
		float wobble = cos((st.y+st.x)*frequency*2.+t) * intensity * sin(st.x*frequency + t);
		
		
		
		//Create a position vector
		vec2 p = vec2(((st.x)-xpos)-wobble, st.y-wobble*1.5);
		

		
		float img = sin(clamp(p.x*PI, 0., PI))*sin(clamp(p.y*PI, 0., PI))*2.;
		float b = pixelate(img, 3.516);
		vec3 color = vec3(b*1.160, b, b*2.);
		float opacity = color.b;
		
		color *= color.g >= 0.99 ? texture2D(texture, tt).rgb : vec3(1.0);
		
		fragOut = vec4(color, opacity) * vertColor;
    }
	else {
		fragOut = vec4(0.0);
	}
	
	gl_FragColor = fragOut;

}