
#define shaderName RGB_to_HSV_HSL

#include "Common.h"

constant const float EPSILON = 1e-10;

static float3 HUEtoRGB(const float hue)
{
  // Hue [0..1] to RGB [0..1]
  // See http://www.chilliant.com/rgb2hsv.html
  float3 rgb = abs(hue * 6. - float3(3, 2, 4)) * float3(1, -1, -1) + float3(-1, 2, 2);
  return saturate(rgb);
}

static float3 RGBtoHCV(const float3 rgb)
{
  // RGB [0..1] to Hue-Chroma-Value [0..1]
  // Based on work by Sam Hocevar and Emil Persson
  float4 p = (rgb.g < rgb.b) ? float4(rgb.bg, -1., 2. / 3.) : float4(rgb.gb, 0., -1. / 3.);
  float4 q = (rgb.r < p.x) ? float4(p.xyw, rgb.r) : float4(rgb.r, p.yzx);
  float c = q.x - min(q.w, q.y);
  float h = abs((q.w - q.y) / (6. * c + EPSILON) + q.z);
  return float3(h, c, q.x);
}

static float3 HSLtoRGB(const float3 hsl)
{
  // Hue-Saturation-Lightness [0..1] to RGB [0..1]
  float3 rgb = HUEtoRGB(hsl.x);
  float c = (1. - abs(2. * hsl.z - 1.)) * hsl.y;
  return (rgb - 0.5) * c + hsl.z;
}

static float3 RGBtoHSL(const float3 rgb)
{
  // RGB [0..1] to Hue-Saturation-Lightness [0..1]
  float3 hcv = RGBtoHCV(rgb);
  float z = hcv.z - hcv.y * 0.5;
  float s = hcv.y / (1. - abs(z * 2. - 1.) + EPSILON);
  return float3(hcv.x, s, z);
}

// RGB

static float3 image0(float3 rgb) {
  // Just return the raw image value
  return rgb;
}

static float3 image1(float3 rgb) {
  return float3(grayscale(rgb));
}

static float3 image2(float3 rgb) {
  // Return the exaggerated hue of the image
  float hue = RGBtoHCV(rgb).x;
  return HUEtoRGB(hue);
}

// HSL

static float3 image3(float3 rgb, float time) {
  // Round-trip RGB->HSL->RGB with time-dependent hue shift
  float3 hsl = RGBtoHSL(rgb);
  hsl.x = fract(hsl.x + time * 0.15);
  return HSLtoRGB(hsl);
}

static float3 image4(float3 rgb, float time) {
  // Round-trip RGB->HSL->RGB with time-dependent lightness
  float3 hsl = RGBtoHSL(rgb);
  hsl.z = pow(hsl.z, sin(time) + 1.5);
  return HSLtoRGB(hsl);
}

static float3 image5(float3 rgb) {
  // Round-trip RGB->HSL->RGB and display exaggerated errors
  float3 hsl = RGBtoHSL(rgb);
  return abs(rgb - HSLtoRGB(hsl)) * 10000000.;
}

// HSV

static float3 image6(float3 rgb, float time) {
  // Round-trip RGB->HSV->RGB with time-dependent lightness
  float3 hsv = rgb2hsv(rgb);
  hsv.y = saturate(hsv.y * (1. + sin(time * 1.5)));
  return hsv2rgb(hsv);
}

static float3 image7(float3 rgb, float time) {
  // Round-trip RGB->HSV->RGB with time-dependent value
  float3 hsv = rgb2hsv(rgb);
  hsv.z = pow(hsv.z, sin(time) + 1.5);
  return hsv2rgb(hsv);
}

static float3 image8(float3 rgb) {
  // Round-trip RGB->HSV->RGB and display exaggerated errors
  float3 hsv = rgb2hsv(rgb);
  return abs(rgb - hsv2rgb(hsv)) * 10000000.;
}

// sRGB

static float3 SRGBtoRGB(float3 srgb) {
  // See http://chilliant.blogspot.co.uk/2012/08/srgb-approximations-for-hlsl.html
  // This is a better approximation than the common "pow(rgb, 2.2)"
  return pow(srgb, float3(2.1632601288));
}

static float3 RGBtoSRGB(float3 rgb) {
  // This is a better approximation than the common "pow(rgb, 0.45454545)"
  return pow(rgb, float3(0.46226525728));
}

static float3 image(int panel, float2 uv, float time, texture2d<float> tex0) {
  float3 rgb = SRGBtoRGB(tex0.sample(iChannel0, uv).rgb);
  switch (panel) {
    case 0: return RGBtoSRGB(image0(rgb));
    case 1: return RGBtoSRGB(image1(rgb));
    case 2: return RGBtoSRGB(image2(rgb));
    case 3: return RGBtoSRGB(image3(rgb, time));
    case 4: return RGBtoSRGB(image4(rgb, time));
    case 5: return RGBtoSRGB(image5(rgb));
    case 6: return RGBtoSRGB(image6(rgb, time));
    case 7: return RGBtoSRGB(image7(rgb, time));
    case 8: return RGBtoSRGB(image8(rgb));
  }
  return float3(0);
}

fragmentFunc(texture2d<float> tex) {
//  shaderName shad;
  
  const float ROWS = 3.;
  const float COLUMNS = 3.;
  const float GAP = 0.05;
  // If ROWS=3 and COLUMNS=3 then the layout of the panels is:
  //
  // 	+---+---+---+
  // 	| 6 | 7 | 8 |
  // 	+---+---+---+
  // 	| 3 | 4 | 5 |
  // 	+---+---+---+
  // 	| 0 | 1 | 2 |
  // 	+---+---+---+
  //
  float3 srgb = float3(0.1);
  float2 uv = textureCoord; // Normalized pixel coordinates (from 0 to 1)
  uv.x -= (1. - COLUMNS / ROWS) * 0.5; // Centre the panels according to the aspect ratio
  uv = uv * (ROWS + GAP) - GAP; // Add gaps between panels
  if ((uv.x >= 0.) && (uv.y >= 0.) && (uv.x < COLUMNS))
  {
    // We're inside the main panel region
    int2 iuv = int2(uv);
    uv = fract(uv) * (1. + GAP);
    if (max(abs(uv.x), abs(uv.y)) < 1.)
    {
      // We're inside one of the panels
      int panel = iuv.x + iuv.y * int(COLUMNS);
      srgb = image(panel, uv, scn_frame.time, tex);
    }
  }
  
  // Output to screen
  return float4(srgb, 1);
}
