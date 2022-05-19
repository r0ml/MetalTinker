
#define shaderName Filters

#include "Common.h"

struct InputBuffer {
    struct {
      bool barrel_and_pincushion;
      bool bloating;
      bool box;
      bool grayscale;
      bool emboss;
    } type;
};

initialize() {
}

fragmentFunc(texture2d<float> tex, constant InputBuffer& in, constant float2& mouse) {
  float2 uv = textureCoord;
  float3 ocol = tex.sample(iChannel0, uv).rgb;
  float3 col = ocol;
  float t = scn_frame.time;

  if (in.type.barrel_and_pincushion) {
    float2 distortion_center = float2(0.5,0.5);

    //K1 < 0 is pincushion distortion
    //K1 >=0 is barrel distortion
    float k1 = 1.0 * sin(t*0.5),
    k2 = 0.5;

    float2 rx = uv - distortion_center;
    float rr = dot(rx,rx);
    float r2 = sqrt(rr) * (1.0 + k1*rr + k2*rr*rr);
    float theta = atan2(rx.x, rx.y);
    float2 distortion = float2(sin(theta), cos(theta)) * r2;
    float2 dest_uv = distortion + 0.5;
    col = tex.sample( iChannel0, dest_uv).rgb;
  } else if (in.type.bloating) {
    float maxPower = 1.5; //Change this to change the grade of bloating that is applied to the image.
    float2 bloatPos = 0; //The position at which the effect occurs

    float n = smoothstep(0.,1.,abs(1.-mod(t/2.,2.)));
    float2 q = bloatPos+0.5;
    float l = length(uv-q);
    float2 p = uv - q;

    float a1 = acos(clamp(dot(normalize(p),float2(1,0)),-1.,1.));
    if (p.y < 0) a1 = -a1;
    if (length(p) == 0) a1 = 0;

    l = pow(l,1.+n*(maxPower-1.));
    float2 uv2 = l*float2(cos(a1),sin(a1))+q;
    col = tex.sample(iChannel0, uv2).rgb;
  } else if (in.type.box) {
    col = 0;

    for(int i = 0; i < 3; i++){
      for(int j = 0; j < 3; j++){
        float2 realRes = float2(i - 1, j - 1) * scn_frame.inverseResolution * 2;
        float3 x = tex.sample(iChannel0, uv + realRes, level(1)).rgb ;
        col += pow(x, 2.2);
      }
    }
    col = gammaEncode(col / 9);
  } else if (in.type.grayscale) {
    float boost = 1.5;
    float reduction = 4.0;
    //float boost = uni.iMouse.x < 0.01 ? 1.5 : uni.iMouse.x / uni.iResolution.x * 2.0;
    //float reduction = uni.iMouse.y < 0.01 ? 2.0 : uni.iMouse.y / uni.iResolution.y * 4.0;

    float3 col = tex.sample(iChannel0, uv).rgb;
    float vignette = distance( 0.5, uv );
    float3 grey = grayscale(col);
    col = mix(grey, col, saturate(boost - vignette * reduction));
  } else if (in.type.emboss) {
    float2 delta = 1 / textureSize(tex);
    col = (tex.sample(iChannel0, uv - delta) * 3. - tex.sample(iChannel0, uv) - tex.sample(iChannel0, uv+delta)).rgb;
  }

  return float4( mix(col, ocol, uv.x > mouse.x ) * (abs(uv.x - mouse.x) > 2. * scn_frame.inverseResolution.x) , 1);
}
