
#define shaderName alpha_compositioning

#include "Common.h" 

struct InputBuffer {
  bool Alpha_compositing;
  float3 radius;
  float3 blur;
};

initialize() {
  in.Alpha_compositing = 1;
  in.radius = {0.1, 0.3, 0.9};
  in.blur = {0.1, 0.5, 1 };
}

//set frame setup
static float2 frame(float2 u, float2 r) {
  float camLens = 1; // zoom
  return camLens*( (u-.5) * r)/r.y;
}

/*static float4 aOverB(float4 a,float4 b) {
  a.xyz*=a.w;
  b.xyz*=b.w;
  return float4(a+b*(1.-a));
}*/

//not sure if correct, but looks useful.
static float4 aXorB(float4 a,float4 b) {
  a.xyz*=a.w;
  b.xyz*=b.w;
  return float4(a*(1.-b)+b*(1.-a));
}

fragmentFunc(texture2d<float> tex0, texture2d<float> tex1, constant float2& mouse, device InputBuffer& in) {
  float2 reso = 1/scn_frame.inverseResolution;
  float2 u=frame(textureCoord, reso);
  float2 m=frame(mouse, reso);

// FIXME: this should be uni.lastTouch, not mouse
  float2 n=frame(mouse, reso);
  /*  if (!uni.mouseButtons) {
   m=.5*float2(cos(uni.iTime*phi),0.);
   n=.5*float2(sin(uni.iTime),cos(uni.iTime));
   }
   */
  float a=length(m-u);a=smoothstep(in.blur.y, -in.blur.y, a-in.radius.y);
  float b=length(n-u);b=smoothstep(in.blur.y, -in.blur.y, b-in.radius.y);

  if (!in.Alpha_compositing) {
    return float4(a,0,b,1);//2 color channels are set by mouse positions.
  } else {
    float4 a4 = float4( tex0.sample(iChannel0, u).xyz, a);//colors are set by
    float4 b4 = float4( tex1.sample(iChannel0, u).xyz, b);//alpha channels are set by distance to mouse positions.
    return float4(aXorB(a4, b4).rgb, 1);
  }

}
