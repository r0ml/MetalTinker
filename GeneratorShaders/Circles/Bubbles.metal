
#define shaderName Bubbles

#include "Common.h"

struct InputBuffer {
  int3 bubbles;
};

initialize() {
  in.bubbles = {10, 40, 100};
}


fragmentFn(
           //           constant SCNSceneBuffer&    scn_frame   [[buffer(0)]],
           //           constant PerNodeData& scn_node [[buffer(1)]]
           ) {

             float2 uv = worldCoordAspectAdjusted;

             // background
             float3 color = float3(0.8 + 0.2*uv.y);

             // bubbles
             for( int i=0; i < in.bubbles.y; i++ ) {
               // bubble seeds
               float pha =      sin(float(i)*546.13+1.0)*0.5 + 0.5;
               float siz = pow( sin(float(i)*651.74+5.0)*0.5 + 0.5, 4.0 );
               float pox =      sin(float(i)*321.55+4.1) * uni.iResolution.x / uni.iResolution.y;

               // buble size, position and color
               float rad = 0.1 + 0.5 * siz;
               float2  pos = float2( pox, -1.0-rad + (2.0+2.0*rad)*mod(pha+0.1*uni.iTime*(0.2+0.8*siz),1.0));
               float dis = length( uv - pos );
               float3  col = mix( float3(0.94,0.3,0.0), float3(0.1,0.4,0.8), 0.5+0.5*sin(float(i)*1.2+1.9));

               // render
               float f = length(uv-pos)/rad;
               f = sqrt(saturate(1.0-f*f));
               color -= col.zyx *(1.0-smoothstep( rad*0.95, rad, dis )) * f;
             }

             color *= sqrt( 1.5 - 0.5 * length(uv) ); // vignetting
             return float4(color,1.0);
           }
