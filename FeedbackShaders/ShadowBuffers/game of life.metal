
#define shaderName game_of_life

#include "Common.h"

// variant of https://www.shadertoy.com/view/4dGSWR (done with help of coyote and rar)
// which was compaction of https://www.shadertoy.com/view/4ddSRM (775)

fragmentFn(texture2d<float> lastFrame) {

  
#define T(a) lastFrame.sample(iChannel0, fract((a)/uni.iResolution.xy) )
  //#define T(a) texelFetch(iChannel0, int2(mod(a,uni.iResolution.xy)), 0 ) // +8
  
  float4 C = T(thisVertex.where.xy);
  float4 fragColor = -3.-C;
  for (int i=0; i<9; i++)                         // count life const neighborhood
    fragColor += T(thisVertex.where.xy+float2(i%3,i/3)-1.);
  
    fragColor = float4(    fragColor * fragColor == -C * fragColor                          // 2 neighbors:survive 3:birth
                   || (uni.iFrame < 1 && tan(thisVertex.where.x*thisVertex.where.y) > 0. )   // initial state. last 185 s
                   //  || length(uni.iMouse.xy-U) < 20.          // mouse paint +25
                   );
  return fragColor;
}
