#ifdef GL_ES
precision mediump float;
precision mediump int;
#endif


#define PI 3.1415926535

uniform vec2 u_resolution;
uniform vec2 u_mouse;
uniform float u_time;

float intensity = 0.043;
float frequency = 15.0;
const float xpos = 0.;

const float speed = 1.0;

float pixelate(float o, float res) {
    return (floor(o*res))/res;
}

void main() {
    vec2 st = gl_FragCoord.xy/u_resolution.xy;
    float aspect = u_resolution.x/u_resolution.y;
    st.x *= u_resolution.x/u_resolution.y;
    
    st *= 1.1;
    st.x *= 2.;
    st += vec2(-0.14,-0.050);
    
    
    //Sawtooth function,
    //THESE EMULATE THE TIME UNIFORM BEING CLAMPED TO 3.14
    float ti = u_time*speed;
    float t = (ti-floor(ti))*PI;
    
    
    //the core of the code, distorts the image making it wobbly.
    //Use an random number for the speed of the two wobble funcitons to
    //ensure they are unsynced for maximum randomness.
    //If you wish for the wooble to be lower you can change those values.
    //I recommend between 1.0-5.0.
    
    //Uncomment the following line and add it to ashe's town code along with
    //the wobble line.
    //float t = time*speed;
    float wobble = cos((st.y+st.x)*frequency*2.+t) * intensity * sin(st.x*frequency + t);
    
    
    
    //Create a position vector
    vec2 p = vec2(((st.x)-xpos)-wobble, st.y-wobble*1.5);
    

    vec3 color = vec3(0.);
    // color =  > 0.404 ? vec3(1.) : vec3(0.);
    
    float img = sin(clamp(p.x*PI, 0., PI))*sin(clamp(p.y*PI, 0., PI))*2.;
    float b = pixelate(img, 3.516);
    color = vec3(b*1.160, b, b*2.);

    gl_FragColor = vec4(color, color.b);
}