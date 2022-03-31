
#define shaderName Sketch_Drawing

#include "Common.h"

struct InputBuffer {
  bool GRAYSCALE = false;
};

initialize() {
}

#define RANGE 16.
#define STEP 2.
#define ANGLENUM 4.

// Grayscale mode! This is for if you didn't like drawing with colored pencils as a kid
//#define GRAYSCALE

// Here's some magic numbers, and two groups of settings that I think looks really nice. 
// Feel free to play around with them!

#define MAGIC_GRAD_THRESH 0.01

// Setting group 1:
/*#define MAGIC_SENSITIVITY     4.
 #define MAGIC_COLOR           1.*/

// Setting group 2:
#define MAGIC_SENSITIVITY     10.
#define MAGIC_COLOR           0.5

//---------------------------------------------------------
// Your usual image functions and utility stuff
//---------------------------------------------------------
static float4 getCol(float2 pos, float2 reso, texture2d<float> vid0)
{
  float2 uv = pos / reso;
  return vid0.sample(iChannel0, uv);
}

static float getVal(float2 pos, float2 reso, texture2d<float> vid0)
{
  float4 c=getCol(pos, reso, vid0);
  return luminance(c.xyz);
}

static float2 getGrad(float2 pos, float eps, float2 reso, texture2d<float> vid0)
{
  float2 d=float2(eps,0);
  return float2(
                getVal(pos+d.xy, reso, vid0)-getVal(pos-d.xy, reso, vid0),
                getVal(pos+d.yx, reso, vid0)-getVal(pos-d.yx, reso, vid0)
                )/eps/2.;
}


/*static float absCircular(float t)
 {
 float a = floor(t + 0.5);
 return mod(abs(a - t), 1.0);
 }*/

//---------------------------------------------------------
// Let's do this!
//---------------------------------------------------------

fragmentFn(texture2d<float> tex) {
  float2 pos = thisVertex.where.xy;
  float weight = 1.0;
  
  for (float j = 0.; j < ANGLENUM; j += 1.)
  {
    float2 dir = float2(1, 0);
    dir = dir * rot2d(j * TAU / (2. * ANGLENUM));
    
    float2 grad = float2(-dir.y, dir.x);
    
    for (float i = -RANGE; i <= RANGE; i += STEP)
    {
      float2 pos2 = pos + normalize(dir)*i;
      
      // texture texture wrap can't be set to anything other than clamp  (-_-)
      if (pos2.y < 0. || pos2.x < 0. || pos2.x > uni.iResolution.x || pos2.y > uni.iResolution.y)
        continue;
      
      float2 g = getGrad(pos2, 1., uni.iResolution, tex);
      if (length(g) < MAGIC_GRAD_THRESH)
        continue;
      
      weight -= pow(abs(dot(normalize(grad), normalize(g))), MAGIC_SENSITIVITY) / floor((2. * RANGE + 1.) / STEP) / ANGLENUM;
    }
  }
  
  float4 col = in.GRAYSCALE ? float4(getVal(pos, uni.iResolution, tex)) : getCol(pos, uni.iResolution, tex);

  float4 background = mix(col, float4(1), MAGIC_COLOR);
  
  // I couldn't get this to look good, but I guess it's almost obligatory at this point...
  /*float distToLine = absCircular(thisVertex.where.xy.y / (uni.iResolution.y/8.));
   background = mix(float4(0.6,0.6,1,1), background, smoothstep(0., 0.03, distToLine));*/
  
  
  // because apparently all shaders need one of these. It's like a law or something.
  float r = length(pos - uni.iResolution.xy*.5) / uni.iResolution.x;
  float vign = 1. - r*r*r;
  
  float a = interporand(pos/uni.iResolution.xy).x;
  
  return vign * mix(float4(0), background, weight) + a/25.;
  //fragColor = getCol(pos);
}
