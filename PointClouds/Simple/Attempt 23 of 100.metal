
#define shaderName attempt_23_of_100

#include "Common.h" 
struct InputBuffer {
//  float4 clearColor = { 0.9, 0.8, 0.7, 1 };
    int3 SCALE;
    float3 SPEED;
    float3 FREQUENCY;
};

initialize() {
  in.SPEED = {2, 5, 10};
  in.FREQUENCY = {0.3, 0.7, 2};
  in.SCALE = {10, 25, 50};
//  in.pipeline._1 = {0, 60, 40, 0};
  // in.pipeline._1.yz = int2(floor(60 * uni.iResolution.y / uni.iResolution));
}

frameInitialize() {
  ctrl.instanceCount = 40;
  ctrl.vertexCount = 60;
  ctrl.topology = 0;
}

/*computeFn() {
  int2 xx = int2(floor(41.0 *  uni.iResolution / uni.iResolution.y));
  if (xx.x > 0) {
    in.pipeline._1.y = xx.x;
  }
  if (xx.y > 0) {
    in.pipeline._1.z = xx.y;
  }
}*/

/*
fragmentFn() {
  float2 uv = float2(thisVertex.where.xy - 0.5 * uni.iResolution.xy) / uni.iResolution.y;
  uv *= SCALE;
  
  float2 f = fract(uv);
  uv = floor(uv);
  
  float t= sqrt( uv.x*uv.x + uv.y*uv.y) * FREQUENCY + uni.iTime*SPEED;
  
  float2 o = float2(cos(t),sin(t))*.4+.5;
  
  float d = length(f-o);
  if (d <= .1) {
    return float4( float3(d), 1);
  } else {
    discard_fragment();
  }
}
*/

vertexPointFn() {
  VertexOutPoint v;
  v.point_size = uni.iResolution.x/220;
  float2 vi = float2(ctrl.vertexCount, ctrl.instanceCount);

  float2 b = (-0.5 + float2(vid, iid)) / (vi - 2);

  float2 t = (2 * float2(vid, iid) / vi - 1) * in.SCALE.y;
  float tt = length(t * uni.iResolution / uni.iResolution.y) * in.FREQUENCY.y + uni.iTime * in.SPEED.y;
  float2 ttt = (float2(cos(tt), sin(tt)) * 0.4 + 0.5) / vi;

  b += ttt * uni.iResolution.x / uni.iResolution;

  v.where.xy = 2 * b - 1;
  v.where.zw = {0, 1};

  v.color = float4(0.1, 0.1, 0.1, 1);
  return v;
}

// the canonical "make it a circle"
  fragmentPointFn() {
    float2 h = pointCoord;
    if ( distance(h, 0.5) > 0.5) {
      // fragColor.rgb = {1,0,0};
      discard_fragment();
    }
    return float4(thisVertex.color.rgb, 1);
  }
