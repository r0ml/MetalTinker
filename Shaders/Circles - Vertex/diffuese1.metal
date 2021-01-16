
#define shaderName diffuese1

#include "Common.h" 
struct InputBuffer {  };
initialize() {}

 


fragmentFn() {
    float r = 100. * (abs(sin(uni.iTime))+0.2);
    float offsetX = 40.*sin(uni.iTime+10.);
    float offsetY = 30.*cos(uni.iTime+10.);
    
	// float2 uv = thisVertex.where.xy.xy / uni.iResolution.xy;
    float b = (pow((thisVertex.where.xy.x + offsetX - uni.iResolution.x/2.), 2.) +
        			pow((thisVertex.where.xy.y +offsetY - uni.iResolution.y/2.), 2.))/pow(r, 2.);
    
	return float4(0.8, b*0.7 + 0.3, b*0.2 + 0.8,1.0);
}
