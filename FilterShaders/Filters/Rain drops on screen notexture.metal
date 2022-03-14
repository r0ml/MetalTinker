
#define shaderName Rain_drops_on_screen_notexture

#include "Common.h"

struct InputBuffer {
};

initialize() {
}



static float2 randx(float2 c){
  float2x2 m = float2x2(12.9898,.16180,78.233,.31415);
  return fract(sin(m * c) * float2(43758.5453, 14142.1));
}

static float2 noise(float2 p){
  float2 co = floor(p);
  float2 mu = fract(p);
  mu = 3.*mu*mu-2.*mu*mu*mu;
  float2 a = randx((co+float2(0.,0.)));
  float2 b = randx((co+float2(1.,0.)));
  float2 c = randx((co+float2(0.,1.)));
  float2 d = randx((co+float2(1.,1.)));
  return mix(mix(a, b, mu.x), mix(c, d, mu.x), mu.y);
}

fragmentFn(texture2d<float> tex) {
  float2 u = textureCoord,
  v = textureCoord / 10,
  n = noise(v*200.); // Displacement
  
  float4 fragColor = textureLod(tex, iChannel0, u, 2.5);
  
  // Loop through the different inverse sizes of drops
  for (float r = 4. ; r > 0. ; r--) {
    float2 x = uni.iResolution.xy * r * .015,  // Number of potential drops (in a grid)
    p = TAU * u * x + (n - .5) * 2.,
    s = sin(p);
    
    // Current drop properties. Coordinates are rounded to ensure a
    // consistent value among the fragment of a given drop.
    //float4 d = texture(iChannel1, round(u * x - 0.25) / x);
    float2 v = round(u * x - 0.25) / x;
    float4 d = float4(noise(v*200.), noise(v));
    
    // Drop shape and fading
    float t = (s.x+s.y) * max(0., 1. - fract(uni.iTime * (d.b + .1) + d.g) * 2.);;
    
    // d.r -> only x% of drops are kept on, with x depending on the size of drops
    if (d.r < (5.-r)*.08 && t > .5) {
      // Drop normal
      float3 v = normalize(-float3(cos(p), mix(.2, 2., t-.5)));
      // fragColor = float4(v * 0.5 + 0.5, 1.0);  // show normals
      
      // Poor man's refraction (no visual need to do more)
      fragColor = tex.sample(iChannel0, u - v.xy * .3);
    }
  }
  
  return fragColor;
}
