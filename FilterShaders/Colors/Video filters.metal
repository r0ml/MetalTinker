
#define shaderName video_filters

#include "Common.h" 
struct InputBuffer {
  struct {
    bool desaturate = true;
    bool invert;
    bool chromatic_aberration;
    bool color_switching;
    bool combined;
  } effect;
};

fragmentFunc(device InputBuffer &in, texture2d<float> tex) {
  float2 p = textureCoord;
  float4 fragColor = tex.sample(iChannel0, p);

  if (in.effect.desaturate) {
    fragColor = (fragColor.r+fragColor.g+fragColor.b) / 3.0;
  } else if (in.effect.invert) {
    fragColor.rgb = 1-fragColor.rgb;
  } else if (in.effect.chromatic_aberration) {
    float2 offset = float2(.01,.0);
    fragColor.r = tex.sample(iChannel0, p+offset.xy).r;
    fragColor.b = tex.sample(iChannel0, p+offset.yx).b;
  } else if (in.effect.color_switching) {
    fragColor.rgb = fragColor.brg;
  } else if (in.effect.combined) {
    if(p.x<.25) { fragColor = (fragColor.r+fragColor.g+fragColor.b)/3.; }
    else if (p.x<.5) { fragColor = 1-fragColor; }
    else if (p.x<.75) { float2 offset = float2(.01,.0);
      fragColor.r = tex.sample(iChannel0, p+offset.xy).r;
      fragColor.b = tex.sample(iChannel0, p+offset.yx).b;
    } else { fragColor.rgb = fragColor.brg; }
    //Line
    if( mod(abs(p.x+.5 * scn_frame.inverseResolution.y ),.25)<  scn_frame.inverseResolution.y ) { fragColor = float4(1.); }
  }
  return fragColor;
}
