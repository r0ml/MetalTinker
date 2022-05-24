/** 
Author: yx
Raytracing the floor plane instead of marching it - fewer iterations to reach the SDF surface, even for the other objects in the scene.
*/

#define shaderName a_Cube_13

// was Fast Plane Tracing

#include "Common.h" 

struct InputBuffer {
};
initialize() {}

 


#define STEPS 32
#define MAX_DIST 100.

static float3 spin(float3 p, float time)
{
   	p.xy = p.xy * rot2d(time);
   	p.xz = p.xz * rot2d(time);
	return p;
}

static float sdFloor(float3 p, float y)
{
    return p.y-y;
}

static float sdFloorFast(float3 p, float3 d, float y)
{
    float t = (y-p.y)/d.y;
    return t >= 0. ? t * .999 : MAX_DIST;
    
    // the .999 is a shitty hack so that we don't overshoot through the floor (yay floating point)
}

static float scene(float3 p, float time)
{
    return min(
        sdBox(spin(p, time),float3(1.)),
        sdFloor(p,-1.)
    );
}

static float sceneFast(float3 p, float3 d, float time)
{
    return min(
        sdBox(spin(p, time),float3(1.)),
        sdFloorFast(p,d,-1.)
    );
}

fragmentFn() {
    float2 uv = thisVertex.where.xy/uni.iResolution.xy-.5;
    uv.x *= uni.iResolution.x/uni.iResolution.y;

    float3 cam = float3(0,0,-5);
    float3 dir = normalize(float3(uv,1));
    
    int i;
    float3 p = cam;
    for(i=0;i<STEPS;++i)
    {
    	float k;
      if (thisVertex.where.xy.x < uni.iResolution.x * (uni.mouseButtons ? uni.iMouse.x : .5))
        	k = scene(p, uni.iTime);
        else
            k = sceneFast(p,dir, uni.iTime);
        if (k < .001 || k > MAX_DIST)
            break;
    	p += dir * k;
    }
    
    // const float2 o = float2(.001,0);
   /* float3 n = normalize(float3(
		scene(p+o.xyy)-scene(p-o.xyy),
		scene(p+o.yxy)-scene(p-o.yxy),
		scene(p+o.yyx)-scene(p-o.yyx)
    )); */
    
    // alternative normal calculation
   	//n = normalize(cross(dFdy(p),dFdx(p)));
    
    // brighter means fewer iterations
    
    float cost = float(i)/float(STEPS);
	return float4(1.-cost);
    //fragColor = float4(fract(p*4.+.5),1);
	//fragColor *= float4(n*.5+.5,1);
}

