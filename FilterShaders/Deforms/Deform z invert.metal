
#define shaderName deform_z_invert

#include "Common.h" 
struct InputBuffer {
};

initialize() {
}

fragmentFn(texture2d<float> tex) {
  
  float2 p = worldCoordAspectAdjusted;

  float r2 = dot(p,p);
  float r = sqrt(r2);
  
  float a = atan2(p.y,p.x);
  a += sin(2.0*r) - 3.0*cos(2.0+0.1*uni.iTime);
  float2 uv = float2(cos(a),sin(a))/r;
  
  // animate
  uv += 10.0*cos( float2(0.6,0.3) + float2(0.1,0.13)*uni.iTime );
  
  float3 col = r * tex.sample( iChannel0,uv*.25).xyz;
  
  return float4( col, 1.0 );
}
