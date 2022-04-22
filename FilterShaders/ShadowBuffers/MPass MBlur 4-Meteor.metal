/**
 Author: aiekick
 use mouse x for decrease the particle number
 use mouse y for control zoom
 */

#define shaderName mpass_mblur_4_meteor

#include "Common.h" 

fragmentFn( texture2d<float> lastFrame ) {
  float4 fragColor = float4(.8,.2,.5,1);
    float2 s = uni.iResolution.xy;
    
    float2 n = float2(100.,5.);
    if (uni.wasMouseButtons)
        n *= (uni.iMouse.xy);
    
    n = max(n, float2(0.01));
    
	float4 h = lastFrame.sample(iChannel0, thisVertex.where.xy / s * 0.995); // the magie is the 0.995 of s
   	
    float2 g = (thisVertex.where.xy+thisVertex.where.xy-s)/s.y*n.y;
    
  float2 k = float2(1.6,0) + uni.iTime;
  float2 a;
    float m = 0;
    
    
    for (float i=0.;i<100.;i++)
    {   
    	if ( i > n.x) break;
        a = g - sin(k + TAU/n.x*i);
        m += 0.01/dot(a,a);
    }
    
    return m * 0.03 + h * 0.97 + step(h, fragColor) * 0.01;
}
