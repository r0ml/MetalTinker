
#define shaderName particle_field

#include "Common.h" 

constant int parts = 100;

struct MyBuffer {
  float4 part[parts];
};

frameInitialize( device struct MyBuffer &buf) {
  // ============================================== buffers =============================

    // float2 uv = thisVertex.where.xy/iChannelResolution.xy;

  for(int i = 0; i<parts; i++) {

    if(uni.iFrame == 0) {

      float2 pos = uni.iResolution.xy/2. + 4.*sin(float2(i+0.5,0.5)) * float2(0.5, i); // *i;

      buf.part[i] = float4(pos,pos+2.4);

      //fff.pass1 = 10000.*sin(float4(4.234,24.35,2312.232,432.2)*(+float4(34.,463.,3.,3.))+uni.iTime);
    }
    else
    {
      float4 pos = buf.part[i];
      float4 vel;

      /*
      if((uni.iFrame%parts == int(thisVertex.where.y)) && uni.mouseButtons) {
        if(int(uni.iTime*9999.)%2==0) {
          pos.xy = uni.iMouse.xy * uni.iResolution;
        } else {
          pos.zw = uni.iMouse.xy * uni.iResolution;
        }
      }*/


      vel = 1.5*sin(pos.yxwz/60.+uni.iTime);

      pos += vel;

      pos = mod(pos,uni.iResolution.xyxy);
      buf.part[i] = pos;
    }
  }
}

fragmentFn( device struct MyBuffer &buf) {

  float3 col = float3(0);
  
  for(int i = 0; i < parts; i++) {
    float4 dat = buf.part[i];
    col += .3/(length(thisVertex.where.xy-dat.xy))*(.5+.5*sin(float3(.01,.014,.018)*dat.xxy+uni.iTime));
    col += .3/(length(thisVertex.where.xy-dat.zw))*(.5+.5*sin(float3(.02,.014,.018)*dat.zww+uni.iTime));
  }
  
  return pow(float4(col,1),float4(2));
}
