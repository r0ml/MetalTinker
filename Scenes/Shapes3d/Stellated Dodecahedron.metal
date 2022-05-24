/** 
 Author: blbenoit
 A stellated dodecahedron :)
 I really love this geometry shape.
 Can I optimise the code and avoid the "for" loop ? Can I replace with a fract for example ?
 */
#define shaderName Stellated_Dodecahedron

#include "Common.h"

struct InputBuffer { };
initialize() {}


//  Function from Iñigo Quiles 
//  https://www.shadertoy.com/view/MsS3Wc
float3 hsb2rgb( const float3 c ){
  float3 rgb = clamp(abs(mod(c.x*6.0+float3(0.0,4.0,2.0),
                             6.0)-3.0)-1.0,
                     0.0,
                     1.0 );
  rgb = rgb*rgb*(3.0-2.0*rgb);
  return c.z * mix( float3(1.0), rgb, c.y);
}

// Reference to http://thndl.com/square-shaped-shaders.html
float triangle (float2 st, 
                float2 p0, float2 p1, float2 p2,
                float smoothness){
  float3 e0, e1, e2;
  
  e0.xy = normalize(p1 - p0).yx * float2(+1.0, -1.0);
  e1.xy = normalize(p2 - p1).yx * float2(+1.0, -1.0);
  e2.xy = normalize(p0 - p2).yx * float2(+1.0, -1.0);
  
  e0.z = dot(e0.xy, p0) - smoothness;
  e1.z = dot(e1.xy, p1) - smoothness;
  e2.z = dot(e2.xy, p2) - smoothness;
  
  float a = max(0.0, dot(e0.xy, st) - e0.z);
  float b = max(0.0, dot(e1.xy, st) - e1.z);
  float c = max(0.0, dot(e2.xy, st) - e2.z);
  
  return smoothstep(smoothness * 2.0,
                    1e-7,
                    length(float3(a, b, c)));
}

fragmentFn()
{
  float2 st = worldCoordAspectAdjusted;
  float3 color = float3(0.0);
  
  float2 v0 = float2(0.0, 0.0);
  //  float pct = length(v0-st);
  
  // My points for triangles
  float2 v1 = float2(-0.1763355756877419 , -0.2427050983124842 );
  float2 v2 = float2( 0.17633557568774194, -0.2427050983124842 );
  float2 v3 = float2( 0.0                , -0.7854101966249685 );
  float2 v4 = float2( 0.2853169548885461 , -0.39270509831248424);
  float2 v5 = float2(-0.285316954888546  , -0.39270509831248424);
  float2 v6 = float2( 0.461652530576288  , -0.6354101966249684 );
  float2 v7 = float2( 0.1763355756877419 , -0.5427050983124843 );
  float2 v8 = float2( 0.461652530576288  , -0.33541019662496846);
  
  /*float2 translate = float2(cos(uni.iTime),sin(uni.iTime));
   st += translate*0.35;
   st *= rotate2d( cos(uni.iTime) );*/
  
  // [HELP] Can i avoid the "for" loop and replace with a fract ?
  for (float i = 0.0; i < 5.0; i++) {
    color += float3( triangle(st, v0, v1, v2, 0.001) ) * hsb2rgb( float3(cos(st.x-0.57)) );
    color += float3( triangle(st, v1, v3, v2, 0.001) ) * hsb2rgb( float3(cos(st.y-0.10)) );
    color += float3( triangle(st, v2, v3, v4, 0.001) ) * hsb2rgb( float3(cos(st.x-0.60)) );
    color += float3( triangle(st, v1, v5, v3, 0.001) ) * hsb2rgb( float3(cos(st.x-0.50)) );
    color += float3( triangle(st, v4, v7, v6, 0.001) ) * hsb2rgb( float3(cos(st.x-0.80)) );
    color += float3( triangle(st, v4, v6, v8, 0.001) ) * hsb2rgb( float3(cos(st.y-0.00)) );
    st *= rot2d( TAU/5.0 );
  }
  
  return float4(color, 1.0);
}
