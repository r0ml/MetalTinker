
#define shaderName Shifting_arrows_animation_2

#include "Common.h"

initialize() {}

fragmentFn() {
  float  h = .5,
  t = uni.iTime / 1.5,
  x = fract(t) - h,
  a = t + x - x* abs(x+x),
  p = 5. / uni.iResolution.y;
  float2   U = thisVertex.where.xy*p, V, C = float2(h, .25);
  int    n = int(t) % 4, i=-1;
  float4 fragColor = 0;
  for ( n%2==1 ? U.y += h, a += 2. : a ;
       i++ < 6 ;
       fragColor += smoothstep(-p,p, min( t<h||x<.25 ? t : t-h, t<h ? .25-x : 1.-x-t))
       )
    V = C + ( fract( n>1 ? U+h : U ) - float2(i%3-1,i/3) -C )
    * makeMat(cos( a*1.5708 + float4(0,33,11,0))),
    x = abs(V.x-h), t = V.y;
  n%2==1 ? fragColor = 1.-fragColor : fragColor;
  return fragColor;
}
