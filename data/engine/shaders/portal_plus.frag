#ifdef GL_ES
precision mediump float;
#endif



#define PI 3.1415926535
uniform float u_dir;
uniform float u_time;
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

const vec2 pixels = vec2(1500., 221.);


void main(void)
{
    vec2 st = vertTexCoord.xy;
    
    float aspect = (pixels.x/pixels.y);
    vec2 tt = gl_FragCoord.xy/pixels.xy;
    //tt.x *= 2.;
    tt.y = 1.-tt.y;
    
    //st.x *= u_resolution.x/u_resolution.y;
    //st *= 1.1;
    //st.x *= 2.;
    st.y -= 0.05;

    
    
    float t = u_time*speed*PI;
    //float t = (ti-floor(ti))*PI;
    
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
}