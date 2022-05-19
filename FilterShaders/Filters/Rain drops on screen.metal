
#define shaderName rain_drops_on_screen

#include "Common.h" 
struct InputBuffer {
  bool random = false;
};

initialize() {
}

fragmentFunc(texture2d<float> tex, constant InputBuffer & in) {
  constexpr sampler chan(coord::normalized, address::repeat, filter::linear, mip_filter::linear);
  
  float2 u = textureCoord;
  
  float2 n = in.random ? fract(rand2(scn_frame.time+u))
  : interporand(u * .1).rg;  // Displacement
  
  float4 fragColor = tex.sample(chan, u, level(3.5) );
  
  // Loop through the different inverse sizes of drops
  for (float r = 4. ; r > 0. ; r--) {
    float2 x = r * .015 / scn_frame.inverseResolution;  // Number of potential drops (in a grid)
    float2 p = TAU * u * x + (n - .5) * 2.;
    float2 s = sin(p);
    
    // Current drop properties. Coordinates are rounded to ensure a
    // consistent value among the fragment of a given drop.
    float3 d = interporand(round(u * x - 0.25) / x);
    
    // Drop shape and fading
    float t = (s.x+s.y) * max(0., 1. - fract(scn_frame.time * (d.b + .1) + d.g) * 2.);;
    
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
