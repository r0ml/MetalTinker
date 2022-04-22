/** 
Author: antonOTI
looking at  balkhan shader I finnaly made a correct enoutgh diffusion shader
using :http://www.karlsims.com/rd.html
as source
and : https://www.shadertoy.com/view/XlKXDm#
when I needed help ^^

*/

#define shaderName my_attempt_at_reaction_diffusion

#include "Common.h" 

struct KBuffer {
};
initialize() {}

 

#define _Smooth(p,r,s) smoothstep(-s, s, p-(r))


float4 smp(float2 uv, float x, float y, float2 reso, texture2d<float> rendin0) {
  return rendin0.sample(iChannel0, (uv + float2(x,y) / reso));
}

constant const float2 difRate = float2(1.,.25);

#define FEED .0367;
#define KILL .0649;

constant const float zoom = .9997;

fragmentFn1() {
  FragmentOutput fff;

	float2 uv = thisVertex.where.xy / uni.iResolution.xy;
    float4 state = renderInput[0].sample(iChannel0,uv);
	fff.fragColor =  float4(0.,state.y,state.y/state.x,1.);

 // ============================================== buffers ============================= 

    uv =( uv - float2(.5)) * zoom + float2(.5);
    float4 current = smp(uv, 0.,0., uni.iResolution, renderInput[0]);
    
    float4 cumul = current * -1.;
    
    cumul += (   smp(uv,  1., 0., uni.iResolution, renderInput[0])
               + smp(uv, -1., 0., uni.iResolution, renderInput[0])
               + smp(uv,  0., 1., uni.iResolution, renderInput[0])
               + smp(uv,  0.,-1., uni.iResolution, renderInput[0])
             ) * .2;

    cumul += (
        smp(uv, 1, 1 , uni.iResolution, renderInput[0]) +
        smp(uv, 1,-1 , uni.iResolution, renderInput[0]) +
        smp(uv, -1, 1, uni.iResolution, renderInput[0]) +
        smp(uv, -1,-1, uni.iResolution, renderInput[0])
       )*.05;
    
    
    float feed = FEED;
    float kill = KILL;
    
    float dist = distance(uv,float2(.5)) - .34;
    kill = kill + step(0.,dist) * dist*.25;
    
    float4 lap =  cumul;
    float newR = current.r + (difRate.r * lap.r - current.r * current.g * current.g + feed * (1. - current.r));
    float newG = current.g + (difRate.g * lap.g + current.r * current.g * current.g - (kill + feed) * current.g);
    
    newR = saturate(newR);
    newG = saturate(newG);
    
    current = float4(newR,newG,0.,1.);
    
    
        uv = (thisVertex.where.xy / uni.iResolution.y) -  float2(uni.iResolution.x /uni.iResolution.y * .5,.5);
    	float f = step(length(uv),.25) - step(length(uv),.24);
    	f *=  .25 + fract(atan2(uv.y,uv.x)*.5 + uni.iTime*.5) * .25 * sin(uni.iTime*.1);
        current = max(current, float4(0.,1.,0.,1.) * f);
    
    if (uni.mouseButtons)
    {
        uv = (thisVertex.where.xy - uni.iMouse.xy * uni.iResolution) / uni.iResolution.xy;
        current = max(current,float4(1.) * step(dot(uv,uv),.001225));
    }
    
    fff.pass1 = current;
  return fff;
}
