
#define shaderName toycamera_tilt_shift_blur

#include "Common.h" 

struct InputBuffer {
};

initialize() {
}

/*static float normpdf( float x, float sigma)
{
  return 0.39894*exp(-0.5*x*x/(sigma*sigma))/sigma;
}*/

/*static float blendScreen(float base, float blend) {
  return 1.0-((1.0-base)*(1.0-blend));
}*/

/*static float3 blendScreen(float3 base, float3 blend) {
  return float3(blendScreen(base.r,blend.r),blendScreen(base.g,blend.g),blendScreen(base.b,blend.b));
}
*/

/*
static float3 blendScreen(float3 base, float3 blend, float opacity) {
  return (blendScreen(base, blend) * opacity + blend * (1.0 - opacity));
}*/

constant const float bluramount  = 0.7;
constant const float center      = 1.0;
constant const float stepSize    = 0.004;
constant const float steps       = 15.0;

constant const float minOffs     = (float(steps-1.0)) / -2.0;
constant const float maxOffs     = (float(steps-1.0)) / +2.0;

fragmentFn(texture2d<float> tex [[texture(0)]]) {
  float3 c = tex.sample(iChannel0, textureCoord).rgb;
  float2 tcoord = textureCoord;
  if (thisVertex.where.x < uni.iMouse.x * uni.iResolution.x)
  {
    return float4(c, 1.0);
  } else {

    float amount;
    float4 blurred;

    //Work out how much to blur based on the mid point
    amount = pow((tcoord.y * center) * 2.0 - 1.0, 2.0) * bluramount;

    //This is the accumulation of color from the surrounding pixels in the texture
    blurred = float4(0.0, 0.0, 0.0, 1.0);

    //From minimum offset to maximum offset
    for (float offsX = minOffs; offsX <= maxOffs; ++offsX) {
      for (float offsY = minOffs; offsY <= maxOffs; ++offsY) {

        //copy the coord so we can mess with it
        float2 temp_tcoord = tcoord.xy;

        //work out which uv we want to sample now
        temp_tcoord.x += offsX * amount * stepSize;
        temp_tcoord.y += offsY * amount * stepSize;

        //accumulate the sample
        blurred += tex.sample(iChannel0, temp_tcoord);
        
      } //for y
    } //for x

    //because we are doing an average, we divide by the amount (x AND y, hence steps * steps)
    blurred /= float(steps * steps);



    return blurred;
  }
}
