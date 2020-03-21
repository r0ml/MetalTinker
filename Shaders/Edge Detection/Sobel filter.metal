
#define shaderName Sobel_filter

#include "Common.h" 

struct KBuffer {
  int webcam;
  string videos[1];
  string textures[1];
  struct {
    float3 THRESHOLD;
    bool image;
    struct {
      int webcam;
      int video;
      int image;
    } source;
    struct {
      int lengthx;
      int lumina;
      int graysc;
      int edge_glow;
      int dfdx;
      int fwidth;
      int test;
    } value;
  } options;

};

initialize() {
  setVideo(0, asset::kinetic_art);
  setTex(0, asset::still_life);
  kbuff.options.THRESHOLD = {0, 0.2, 1};
}
fragmentFn() {

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

  texture2d<float> vid = webcam;

  if (kbuff.options.source.video) {
    vid = video[0];
  }

  if (kbuff.options.source.image) {
    vid = texture[0];
  }

  float2 uv = thisVertex.where.xy / uni.iResolution;
  float2 res = textureSize(vid);
  float3 pix = vid.sample(iChannel0, uv).xyz;

  if (kbuff.options.value.lengthx) {

    for(int i = -1; i <= 1; i++) {
      for(int j = -1; j <= 1; j++) {
        float2 xy = uv + float2(i,j) /res;
        float3 clem = vid.sample(iChannel0, xy).xyz;
        float val = length(clem);
        sum += val * float2(sobelx[1+i][1+j], sobely[1+i][1+j]);
      }
    }
  } else if (kbuff.options.value.lumina) {
    for(int i = -1; i <= 1; i++) {
      for(int j = -1; j <= 1; j++) {
        float2 xy = uv + float2(i,j) /res;
        float3 clem = vid.sample(iChannel0, xy).xyz;
        float val = pow(luminance(clem), 0.6);
        sum += val * float2(sobelx[1+i][1+j], sobely[1+i][1+j]);
      }
    }
  } else if (kbuff.options.value.graysc) {
    for(int i = -1; i <= 1; i++) {
      for(int j = -1; j <= 1; j++) {
        float2 xy = uv + float2(i,j) /res;
        float3 clem = vid.sample(iChannel0, xy).xyz;
        float val = grayscale(clem);
        sum += val * float2(sobelx[1+i][1+j], sobely[1+i][1+j]);
      }
    }
  } else if (kbuff.options.value.edge_glow) {
    float2 d = (sin(uni.iTime * 5.0)*0.5 + 1.5) / uni.iResolution; // kernel offset
    float2 p = thisVertex.where.xy / uni.iResolution;

    // simple sobel edge detection
    float2 gxy = 0;

    for(int i = -1; i<2;i++) {
      for(int j = -1; j<2;j+=2) {
        float gm = j * (2 - abs(i));

        gxy.x += luminance(gm * vid.sample(iChannel0, p + float2(j, i) * d).rgb);
        gxy.y += luminance(gm * vid.sample(iChannel0, p + float2(i, j) * d).rgb);
      }
    }
    // hack: use g^2 to conceal noise in the video
    float g = dot(gxy, gxy);
    float g2 = 0; // g * (sin(uni.iTime) / 2.0 + 0.5);

    float4 col = vid.sample(iChannel0, p);
    col += float4(0.0, g, g2, 1.0);
    return col;
  } else   if (kbuff.options.value.dfdx) {
    float2 uv = thisVertex.where.xy / uni.iResolution;
    float4 color =  vid.sample(iChannel0, uv);
    float gray = length(color.rgb);
    return float4(float3(step(0.06, length(float2(dfdx(gray), dfdy(gray))))), 1.0);
  } else if (kbuff.options.value.fwidth) {
    float4 fragColor = fwidth(vid.sample(iChannel0, thisVertex.where.xy / uni.iResolution))*15.;
    fragColor.w = 1;
    return fragColor;
  } else if (kbuff.options.value.test) {
    float3x3 Y;
    float3x3 Co;
    float3x3 Cr;

    float2 inv_res = 1. /res;
    float2 uv = thisVertex.where.xy / uni.iResolution;

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
  float3 mm = float3( step(kbuff.options.THRESHOLD.y, ls) * ls);
  float3 mx = mm * (kbuff.options.image ? pix : 1);
  return float4( mx, 1);
  // return float4( float3( step(0.4, ls) * ls), 1);
}
