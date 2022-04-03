
#define shaderName magic_ring

#include "Common.h" 

static float4 permute(float4 x){return mod(((x*34.0)+1.0)*x, 289.0);}
static float4 taylorInvSqrt(float4 r){return 1.79284291400159 - 0.85373472095314 * r;}

static float snoise(float3 v){
  const float2  C = float2(1.0/6.0, 1.0/3.0) ;
  const float4  D = float4(0.0, 0.5, 1.0, 2.0);
  
  // First corner
  float3 i  = floor(v + dot(v, C.yyy) );
  float3 x0 =   v - i + dot(i, C.xxx) ;
  
  // Other corners
  float3 g = step(x0.yzx, x0.xyz);
  float3 l = 1.0 - g;
  float3 i1 = min( g.xyz, l.zxy );
  float3 i2 = max( g.xyz, l.zxy );
  
  //  x0 = x0 - 0. + 0.0 * C
  float3 x1 = x0 - i1 + 1.0 * C.xxx;
  float3 x2 = x0 - i2 + 2.0 * C.xxx;
  float3 x3 = x0 - 1. + 3.0 * C.xxx;
  
  // Permutations
  i = mod(i, 289.0 );
  float4 p = permute( permute( permute(
                                       i.z + float4(0.0, i1.z, i2.z, 1.0 ))
                              + i.y + float4(0.0, i1.y, i2.y, 1.0 ))
                     + i.x + float4(0.0, i1.x, i2.x, 1.0 ));
  
  // Gradients
  // ( N*N points uniformly over a square, mapped onto an octahedron.)
  float n_ = 1.0/7.0; // N=7
  float3  ns = n_ * D.wyz - D.xzx;
  
  float4 j = p - 49.0 * floor(p * ns.z *ns.z);  //  mod(p,N*N)
  
  float4 x_ = floor(j * ns.z);
  float4 y_ = floor(j - 7.0 * x_ );    // mod(j,N)
  
  float4 x = x_ *ns.x + ns.yyyy;
  float4 y = y_ *ns.x + ns.yyyy;
  float4 h = 1.0 - abs(x) - abs(y);
  
  float4 b0 = float4( x.xy, y.xy );
  float4 b1 = float4( x.zw, y.zw );
  
  float4 s0 = floor(b0)*2.0 + 1.0;
  float4 s1 = floor(b1)*2.0 + 1.0;
  float4 sh = -step(h, float4(0.0));
  
  float4 a0 = b0.xzyw + s0.xzyw*sh.xxyy ;
  float4 a1 = b1.xzyw + s1.xzyw*sh.zzww ;
  
  float3 p0 = float3(a0.xy,h.x);
  float3 p1 = float3(a0.zw,h.y);
  float3 p2 = float3(a1.xy,h.z);
  float3 p3 = float3(a1.zw,h.w);
  
  //Normalise gradients
  float4 norm = taylorInvSqrt(float4(dot(p0,p0), dot(p1,p1), dot(p2, p2), dot(p3,p3)));
  p0 *= norm.x;
  p1 *= norm.y;
  p2 *= norm.z;
  p3 *= norm.w;
  
  // Mix final noise value
  float4 m = max(0.6 - float4(dot(x0,x0), dot(x1,x1), dot(x2,x2), dot(x3,x3)), 0.0);
  m = m * m;
  return 42.0 * dot( m*m, float4( dot(p0,x0), dot(p1,x1),
                                 dot(p2,x2), dot(p3,x3) ) );
}

///////////////////////////////////////////////////////////////////////
// END OF RIPS
///////////////////////////////////////////////////////////////////////

// Subtract sdf (a-b)
static float sdf_sub(float a, float b) {
  return max(-b, a);
}

// 2D Donut SDF
static float ring(float2 p, float radius, float thickness) {
  float l = length(p);
  float ht = thickness / 2.0;
  float inner = l - (radius - ht);
  float outer = l - (radius + ht);
  return sdf_sub(outer, inner);
}

// Decellerate towards 1.0
static float upsidePowerCurve(float x, float e) {
  return 1.0-pow(1.0-x, e);
}

// Decellerate towards 1.0, then acc+dec back to 0.0
static float bulgeCurve(float x, float e) {
  // Type this in google:
  // 3.0*x*((1.0-x)^2.0)*2.25*(1.0-x)
  return 3.0*x*pow(1.0-x,2.0)*2.25*(1.0-x);
}

// Waterline function
static float clip(float x, float t, float range) {
  return saturate((x-t)/range-t+1.0);
}

fragmentFn() {
  float2 uv = worldCoordAspectAdjusted / 2;
  
  // Static attributes
  float radius = 0.3;
  float thickness = 0.02;
  
  // Repeating time [0, 1] range
  float timespan = 4.0;
  float t = mod(uni.iTime/timespan, 1.0);
  
  // Animate parameters
  float upow = upsidePowerCurve(t, 6.0);
  radius *= upow;
  thickness *= bulgeCurve(t, 3.0);
  
  float d = ring(uv, radius, thickness);
  
  
  float ns = (snoise(float3(uv*6.0/upow, uni.iTime/10.0))+1.0)/2.0;
  float clippedNoise = clip(ns, t, 0.1);
  
  // Hard edge
  //float m = d > 0.0 ? 0.0 : 1.0;
  // Make smooth
  float m = saturate(-d*100.0);
  m *= clippedNoise;
  // TODO: Make glow
  
  // show noise
  //m = (uv.x < 0.0) ? ns : clippedNoise;
  
  return float4(0.5, 0.7, 1.0, 1.0) * m * 3.0;
}
