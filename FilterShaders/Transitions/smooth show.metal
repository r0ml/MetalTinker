
#define shaderName smooth_show

#include "Common.h" 

struct InputBuffer {
};

initialize() {
}

 


fragmentFn(texture2d<float> tex) {
    float speed = uni.iTime * .5;
    float dp = .2;
    
	float2 uv = textureCoord;
    
    float op = smoothstep(max(1.-speed-dp,-dp),
                          max(1.-speed,0.),
                          1.-uv.y);
    
    return op * tex.sample(iChannel0,uv);
}

 
