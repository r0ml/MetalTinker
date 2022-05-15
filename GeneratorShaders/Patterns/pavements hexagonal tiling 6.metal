// relying on hexagonal tiling tutos https://www.shadertoy.com/view/4dKXR3
//                               and https://www.shadertoy.com/view/XdKXz3
// from https://www.shadertoy.com/view/4dKXz3

#define shaderName pavements_hexagonal_tiling_6

#include "Common.h" 

fragmentFunc() {
  float2 U = worldCoordAdjusted * 3 *  1.73/2.;  // centered coords
  float2 uv = U;
  U *= float2x2(1,-1./1.73, 0,2./1.73);            // conversion to
  float3 g = float3(U,1.-U.x-U.y), g2,              // hexagonal coordinates
  id = floor(g);                            // cell id
  
  g = fract(g);                                 // diamond coords
  if (length(g)>1.) g = 1.-g;                   // barycentric coords
  g2  = (2.*g-1.);                              // distance to borders
  
  U = id.xy * float2x2(1,.5, 0,1.73/2.);
  
  float l00 = length(U-uv),                     // screenspace distance to nodes
  l10 = length(U+float2(1,0)-uv),
  l01 = length(U+float2(.5,1.73/2.)-uv),
  l11 = length(U+float2(1.5,1.73/2.)-uv),
  l20 = length(U+float2(2,0)-uv),
  l = min(min(min(l00, l10), min( l01, l11)),l20); // closest node
                                                   //float2 C = U+ ( l==l00 ? float2(0) : l==l10 ? float2(1,0) : l==l01 ? float2(.5,1.73/2.) : l==l11 ? float2(1.5,1.73/2.) : float2(2,0)  );
  
  // --- making fish scales
  float k = 1.;
  id += l20<k ? float3(2,0,0) : l11<k ?  float3(1,1,0) : l10<k ? float3(1,0,0) : l01<k ? float3(0,1,0) : float3(0);
  float2 C = id.xy * float2x2(1,.5, 0,1.73/2.);
  
  // --- making pavement
  uv -= C;
  l = length(uv);
  float a = atan2(uv.y,-uv.x), n=8.,
  u = l, //  .5 + 1.73/2.* tan(2.*asin(l/2.)-PI/6.),
  dl = 1.-length(float2(1,0)+u*float2(-.5,1.73/2.)); // % of free arclenght
  
  return pow( abs( sin(PI*a*(floor(n*l)+n*dl)) * sin(PI*n*l)),.5) ;
}
