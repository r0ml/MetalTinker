
// This generalizes to "passsing in a palette, and then mapping the texture to the nearest
// textures in the palette
#define shaderName place_ify

#include "Common.h" 
struct InputBuffer {
};

initialize() {
}


#define rgb(r,g,b) float3(r,g,b)/255.

static void map(float3 inp, float3 color, thread float4& dat) {
  float3 diff = inp - color;
  float dst = length(diff);
  if(dst < dat.w) {
    dat = float4(color, dst);
  }
}

static float4 mapColor(float4 orig) {
  float4 outColor = float4(0.,0.,0.,100000.);
  
  map(orig.rgb, rgb(255.,255.,255.), outColor);
  map(orig.rgb, rgb(228.,228.,228.), outColor);
  map(orig.rgb, rgb(136.,136.,136.), outColor);
  map(orig.rgb, rgb(34.,34.,34.), outColor);
  map(orig.rgb, rgb(255.,167.,209.), outColor);
  map(orig.rgb, rgb(229.,0.,0.), outColor);
  map(orig.rgb, rgb(229.,149.,0.), outColor);
  map(orig.rgb, rgb(160.,106.,66.), outColor);
  map(orig.rgb, rgb(229.,217.,0.), outColor);
  map(orig.rgb, rgb(148.,224.,68.), outColor);
  map(orig.rgb, rgb(2.,190.,1.), outColor);
  map(orig.rgb, rgb(0.,211.,221.), outColor);
  map(orig.rgb, rgb(0.,131.,199.), outColor);
  map(orig.rgb, rgb(0.,0.,234.), outColor);
  map(orig.rgb, rgb(207.,110.,228.), outColor);
  map(orig.rgb, rgb(130.,0.,128.), outColor);
  
  return float4(outColor.xyz, orig.w);
}

fragmentFn(texture2d<float> tex) {
  float2 s  = float2(uni.iResolution.x/uni.iResolution.y,1.)*1000.;
  float2 uv = floor(textureCoord*s)/s;
  
  return mapColor(tex.sample(iChannel0, uv));
}
