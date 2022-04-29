
#define parts 100

#define shaderName particle_field

#include "Common.h" 

struct KBuffer {
};
initialize() {
}

#undef ComputeBuffer
#define ComputeBuffer ComputeBuffer

struct ComputeBuffer {
  float4 part[parts];
};

fragmentFn1() {
  FragmentOutput fff;

  float3 col = float3(0);
  
  for(int i = 0; i < parts; i++)
  {
    int2 index = int2(i/int(uni.iResolution.y),i%int(uni.iResolution.y));
    float4 dat = texelFetch(renderInput[0], int2(index),0);
    col += .3/(length(thisVertex.where.xy-dat.xy))*(.5+.5*sin(float3(.01,.014,.018)*dat.xxy+uni.iTime));
    col += .3/(length(thisVertex.where.xy-dat.zw))*(.5+.5*sin(float3(.02,.014,.018)*dat.zww+uni.iTime));
  }
  
  fff.fragColor = pow(float4(col,1),float4(2));
  fff.fragColor.w = 1;

// ============================================== buffers =============================

  // float2 uv = thisVertex.where.xy/iChannelResolution.xy;
  
  if(uni.iFrame < 1)
  {
    float2 pos = uni.iResolution.xy/2. + 4.*sin(thisVertex.where.xy.yx)*thisVertex.where.xy;
    
    fff.pass1 = float4(pos,pos+2.4);
    
    //fff.pass1 = 10000.*sin(float4(4.234,24.35,2312.232,432.2)*(+float4(34.,463.,3.,3.))+uni.iTime);
  }
  else if (thisVertex.where.x < 4.)
  {
    float4 pos = renderInput[0].read(uint2(thisVertex.where.xy));
    float4 vel;
    
    if((uni.iFrame%int(parts)==int(thisVertex.where.y)) && uni.mouseButtons) {
      if(int(uni.iTime*9999.)%2==0) {
        pos.xy = uni.iMouse.xy * uni.iResolution;
      } else {
        pos.zw = uni.iMouse.xy * uni.iResolution;
      }
    }
    vel = 1.5*sin(pos.yxwz/60.+uni.iTime);
    
    pos += vel;
    
    pos = mod(pos,uni.iResolution.xyxy);
    fff.pass1 = pos;
  }
  return fff;
}
