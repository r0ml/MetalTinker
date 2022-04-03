
#define shaderName Spinning_Ring

#include "Common.h" 

constant const int ringSides = 200;

struct InputBuffer {
//  float4 clearColor = 0;
  float3 radius;
  float3 thickness;
};

initialize() {
//  in.pipeline._1 = {3, 6 * ringSides, 1, 0};
  in.thickness = { 0.01, 0.05, 0.1};
  in.radius = {0.2, 0.3, 0.5};
}

frameInitialize() {
  ctrl.topology = 2;
  ctrl.vertexCount = 6 * ringSides;
}

vertexFn() {
  VertexOut v;
  float2 a = annulus(vid, ringSides, in.radius.y - in.thickness.y / 2, in.radius.y + in.thickness.y / 2);
  
  a = a * rot2d( -uni.iTime * 5. + (sin(uni.iTime) * 3. + 1.));
  
  v.where.xy = (2 * (a + 0.5) - 1) * 0.5;
  v.where.zw = {0, 1};

  v.where = v.where * scale(aspectRatio.y, aspectRatio.x, 1);

  v.color = smoothstep(1, 0, (float(vid)/ ctrl.vertexCount ) ); // a.z * 1.05);
  //  v.theta = a.z;
  return v;
}
