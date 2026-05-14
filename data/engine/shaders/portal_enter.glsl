#ifdef GL_ES
precision mediump float;
precision mediump int;
#endif

#define PROCESSING_TEXTURE_SHADER

#define INTENSITY_PORTALLIGHT_FACTOR 0.33;
#define PI 3.1415926535897932

uniform sampler2D texture;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_offset;





//Intensity should be a really small number for a subtle effect.
//a value like 0.5 will make it REALLY woobly trust me.
uniform float portalLight;
const float frequency = 15.0;


//returns a distorted pixel position for the image
float wooble(vec2 uv, float speed, float frequency) {
	float intensity = portalLight * INTENSITY_PORTALLIGHT_FACTOR;
	float t = u_time*2.*PI;
    return cos(uv.x*frequency+t)*intensity*sin(uv.y*frequency+t*speed);
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = ((gl_FragCoord.xy-u_offset.xy)/u_resolution.xy);
    
	float intensity = portalLight * INTENSITY_PORTALLIGHT_FACTOR;
    float wobbleX = wooble(uv, 1. /*speed 1*/, frequency)*intensity;
    float wobbleY = wooble(uv, 2. /*speed 2*/, frequency)*intensity;
    
    //Create a position vector
    vec2 p = vec2(uv.x-wobbleX, uv.y-wobbleY);
    
    //Apply the effect to the scene.
    gl_FragColor = texture2D( texture, p.xy ) + vec4(portalLight,portalLight,portalLight, 0.0);
    
    
    
}
