#ifdef GL_ES
precision mediump float;
#endif



#define PI 3.1415926535
uniform float u_time;
uniform vec2 pixelRes;
uniform sampler2D texture;
varying vec4 vertTexCoord;
varying vec4 vertColor;

float intensity = 0.043;
float frequency = 15.0;
const float xpos = 0.;

const float speed = 1.0;



float pixelate(float o, float res) {
    return (floor(o*res))/res;
}




void main(void)
{
    vec2 st = vertTexCoord.xy;
    
    vec2 tt = st.xy*pixelRes.xy;
    //tt.x *= 2.;
	
    //tt.y = 1.-tt.y;
    
    //st.x *= u_resolution.x/u_resolution.y;
    //st *= 1.1;
    //st.x *= 2.;
	
	st.x -= 0.15;
	st.x *= 1.5;

    
    
    float t = u_time*speed*PI;
    //float t = (ti-floor(ti))*PI;
    
    
    float wobble = cos((st.y+st.x)*frequency*2.+t) * intensity * sin(st.x*frequency + t);
    
    
    
    //Create a position vector
    vec2 p = vec2(((st.x)-xpos)-wobble, st.y-wobble*1.5);
    

    
    float img = sin(clamp(p.x*PI, 0., PI))*sin(clamp(p.y*PI, 0., PI))*2.;
    float b = pixelate(img, 3.516);
    vec3 color = vec3(b*1.160, b, b*2.);
    float opacity = color.b;
    
    color *= color.g >= 0.99 ? texture2D(texture, tt).rgb : vec3(1.0);
    
    gl_FragColor = vec4(color, opacity) * vertColor;
	//gl_FragColor = texture2D(texture, tt).rgba;
}