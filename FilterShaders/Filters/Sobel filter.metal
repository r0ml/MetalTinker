
#define shaderName Sobel_filter

#include "Common.h" 

struct InputBuffer {
  float3 THRESHOLD;
  bool image;
  struct {
    int lengthx;
    int lumina;
    int graysc;
    int edge_glow;
    int dfdx;
    int fwidth;
    int test;
  } value;
};

initialize() {
  in.THRESHOLD = {0, 0.2, 1};
}
fragmentFunc(texture2d<float> tex, device InputBuffer& in) {

  texture2d<float> vid = tex;

  float3x3 sobelx =
  float3x3(-1.0, -2.0, -1.0,
           0.0,  0.0, 0.0,
           1.0,  2.0,  1.0);
  float3x3 sobely =
  float3x3(-1.0,  0.0,  1.0,
           -2.0,  0.0, 2.0,
           -1.0,  0.0,  1.0);

  float3x3 YCoCr_mat = float3x3(1./4., 1./2., 1./4.,  -1./4., 1./2., -1./4.,   1./2., 0.0, -1./2. );

  float2 sum = 0.0;

  float2 uv = thisVertex.texCoords;
  float2 res = textureSize(vid);
  float3 pix = vid.sample(iChannel0, uv).xyz;

  if (in.value.lengthx) {

    for(int i = -1; i <= 1; i++) {
      for(int j = -1; j <= 1; j++) {
        float2 xy = uv + float2(i,j) /res;
        float3 clem = vid.sample(iChannel0, xy).xyz;
        float val = length(clem);
        sum += val * float2(sobelx[1+i][1+j], sobely[1+i][1+j]);
      }
    }
  } else if (in.value.lumina) {
    for(int i = -1; i <= 1; i++) {
      for(int j = -1; j <= 1; j++) {
        float2 xy = uv + float2(i,j) /res;
        float3 clem = vid.sample(iChannel0, xy).xyz;
        float val = pow(luminance(clem), 0.6);
        sum += val * float2(sobelx[1+i][1+j], sobely[1+i][1+j]);
      }
    }
  } else if (in.value.graysc) {
    for(int i = -1; i <= 1; i++) {
      for(int j = -1; j <= 1; j++) {
        float2 xy = uv + float2(i,j) /res;
        float3 clem = vid.sample(iChannel0, xy).xyz;
        float val = grayscale(clem);
        sum += val * float2(sobelx[1+i][1+j], sobely[1+i][1+j]);
      }
    }
  } else if (in.value.edge_glow) {
    float2 d = (sin(scn_frame.time * 5.0)*0.5 + 1.5) * scn_frame.inverseResolution; // kernel offset
    float2 p = thisVertex.texCoords;

    // simple sobel edge detection
    float2 gxy = 0;

    for(int i = -1; i<2;i++) {
      for(int j = -1; j<2;j+=2) {
        float gm = j * (2 - abs(i));

        gxy.x += luminance(gm * vid.sample(iChannel0, p + float2(j, i) * d).rgb);
        gxy.y += luminance(gm * vid.sample(iChannel0, p + float2(i, j) * d).rgb);
      }
    }
    // hack: use g^2 to conceal noise in the texture
    float g = dot(gxy, gxy);
    float g2 = 0; // g * (sin(uni.iTime) / 2.0 + 0.5);

    float4 col = vid.sample(iChannel0, p);
    col += float4(0.0, g, g2, 1.0);
    return col;
  } else   if (in.value.dfdx) {
    float2 uv = thisVertex.texCoords;
    float4 color =  vid.sample(iChannel0, uv);
    float gray = length(color.rgb);
    return float4(float3(step(0.06, length(float2(dfdx(gray), dfdy(gray))))), 1.0);
  } else if (in.value.fwidth) {
    float4 fragColor = fwidth(vid.sample(iChannel0, thisVertex.texCoords))*15.;
    fragColor.w = 1;
    return fragColor;
  } else if (in.value.test) {
    float3x3 Y;
    float3x3 Co;
    float3x3 Cr;

    float2 inv_res = 1. /res;
    float2 uv = thisVertex.texCoords;

    for (int i=0; i<3; i++) {
      for (int j=0; j<3; j++) {
        float2 pos = uv + (float2(i, j) - 1) * inv_res;
        float3 temp = YCoCr_mat * vid.sample(iChannel0, pos).xyz;
        Y[i][j] = temp.x;
        Co[i][j] = temp.y;
        Cr[i][j] = temp.z;
      }
    }

    float3 xyz = float3(length(float2(dot(sobelx[0], Y[0]) + dot(sobelx[1], Y[1]) + dot(sobelx[2], Y[2]),
                                      dot(sobely[0], Y[0]) + dot(sobely[1], Y[1]) + dot(sobely[2], Y[2]))),
                        length(float2(dot(sobelx[0], Co[0]) + dot(sobelx[1], Co[1]) + dot(sobelx[2], Co[2]),
                                      dot(sobely[0], Co[0]) + dot(sobely[1], Co[1]) + dot(sobely[2], Co[2]))),
                        length(float2(dot(sobelx[0], Cr[0]) + dot(sobelx[1], Cr[1]) + dot(sobelx[2], Cr[2]),
                                      dot(sobely[0], Cr[0]) + dot(sobely[1], Cr[1]) + dot(sobely[2], Cr[2]))));

    return float4(saturate(xyz), 1);
  }


  float ls = length(sum);
  float3 mm = float3( step(in.THRESHOLD.y, ls) * ls);
  float3 mx = mm * (in.image ? pix : 1);
  return float4( mx, 1);
  // return float4( float3( step(0.4, ls) * ls), 1);
}
