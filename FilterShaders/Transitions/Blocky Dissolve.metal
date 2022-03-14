
#define shaderName blocky_dissolve

#include "Common.h" 
struct InputBuffer {
};
initialize() {}

 



static float randx(float2 co){
  return fract(sin(dot(co.xy ,float2(12.9898,78.233))) * 43758.5453);
}

fragmentFn() {
  float2 uv = thisVertex.where.xy / uni.iResolution.xy;
  float resolution = 5.0;
  float2 lowresxy = float2(
                           floor(thisVertex.where.xy.x / resolution),
                           floor(thisVertex.where.xy.y / resolution)
                           );
  
  if(sin(uni.iTime) > randx(lowresxy)){
    return float4(uv,0.5+0.5*sin(5.0 * thisVertex.where.xy.x),1.0);
    //fragColor = float4(uv,0.5+0.5*sin(uni.iTime * 5.0 * uv.x),1.0);
    //fragColor = float4(uv,0.5+0.5*sin(uni.iTime * 5.0 * uv.x * sin(uv.x * uv.y * uni.iTime)),1.0);
    //fragColor = float4(uv,0.5+0.5*sin(uni.iTime * 5.0 * uv.x * sin(uv.x / uv.y * uni.iTime / 500000.0)),1.0);
    //fragColor = float4(uv,0.5+0.5*sin(uni.iTime * 5.0 * uv.x * sin(uv.x * uv.y * uni.iTime / 5000.0)),1.0);
    //fragColor = float4(uv,0.5+0.5*sin(uni.iTime * 500.0 * uv.x * sin(uv.y + uni.iTime * 500.0)),1.0);
    //fragColor = float4(uv,0.5+0.5*sin((uv.x + uv.y) * 500.0 * sin(uni.iTime)),1.0);
  }else{
    return float4(0.0,0.0,0.0,1.0);
  }
}


