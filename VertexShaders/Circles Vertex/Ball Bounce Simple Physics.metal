
#define shaderName ball_bounce_simple_physics

#include "Common.h" 

struct InputBuffer {
  bool motion_blur = true;
  int3 max_bounces;
  int3 motion_blur_samples;
};

initialize() {
  in.max_bounces = { 4, 16, 32};
  in.motion_blur_samples = {4, 16, 32};
}

//solve 2nd order polynomial, return the maximum of two solutions
//could have optimised for this particular example... meh...
static float second(float a,float b,float c)
{
  float x1 = (-b+sqrt((b*b-4.0*a*c)))/(2.0*a);
  float x2= (-b-sqrt((b*b-4.0*a*c)))/(2.0*a);
  return max(x1,x2);
}

//compute position after t seconds
//there is a plane at y=0, need to check for collisions with it
static float3 physics(float3 pos, float3 vel, float3 acc, float t, const int bounces)
{
  //this loop processes upto max_bounces collisions... nice :)
  for (int i=0; i<bounces; i++)
  {
    float tc = second(acc.y*.5,vel.y,pos.y);
    //now we know that there will be a collision with the plane
    //in exactly tc seconds
    
    if (t>tc) //if time is greater than time of collision
    {
      t-=tc; //process the collision
      pos = pos + vel*tc + acc*tc*tc*.5;
      vel = vel + acc*tc;
      vel.y*=-.6; //make it bounce
    }
    else break; //it wont collide, yay!
  }
  
  return pos + vel*t + acc*t*t*.5; // x = v*t + .5*a*t^2
}

static float hash(float2 x)
{
  return fract(cos(dot(x.xy,float2(2.31,53.21))*124.123)*412.0);
}

fragmentFn() {
  float2 uv = worldCoordAspectAdjusted * 8;
  float acc = .0;
  
  //new simulation after every 4 seconds
  float mt = mod(uni.iTime,4.0);
  float seed = uni.iTime-mt; //the seed to generate new variables
  
  for (int _sample = 0; _sample<in.motion_blur_samples.y; _sample++)
  {
    float tnoise = .0;
    if (in.motion_blur) {
     tnoise = hash(uv.xy+float2(_sample,_sample))*(1.0/24.0);
    }

    float3 p = (
                physics(
                        float3(sin(seed*.5)*4.0,8.0,.0), //initial position
                        float3(cos(seed)*4.0,cos(seed*4.7)*cos(seed*1.7)*16.0-4.0,.0), //initial velocity
                        float3(.0,-(sin(seed*3.1)*12.0+21.0),.0),  //acceleration
                        mt+tnoise,
                        in.max_bounces.y));
    
    float2 temp = uv-p.xy+float2(.0,3.0+4.0);
    float s = sqrt(dot(temp,temp));
    s-=1.0;
    s*=uni.iResolution.y*.05;
    s = min(1.0,max(.0,s));
    
    acc+=s/float(in.motion_blur_samples.y);
  }
  
  float3 color = mix(float3(1.1,.8,.5),float3(.3,.2,.4),acc);
  
  color = mix(color*color,color,1.4);
  color *=.8;
  color -= length(uv)*.005;
  
  color += hash(uv.xy+color.xy)*.02;
  
  return float4(color,1.0);
}
