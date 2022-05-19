
#define shaderName Comic_Book_Video_FX

#include "Common.h"


static float HueToRGB(float f1, float f2, float hue)
{
  if (hue < 0.0)
    hue += 1.0;
  else if (hue > 1.0)
    hue -= 1.0;
  float res;
  if ((6.0 * hue) < 1.0)
    res = f1 + (f2 - f1) * 6.0 * hue;
  else if ((2.0 * hue) < 1.0)
    res = f2;
  else if ((3.0 * hue) < 2.0)
    res = f1 + (f2 - f1) * ((2.0 / 3.0) - hue) * 6.0;
  else
    res = f1;
  return res;
}

static float3 RGBToHSL(float3 color)
{
  float3 hsl; // init to 0 to avoid warnings ? (and reverse if + remove first part)
  
  float fmin = min(min(color.r, color.g), color.b);    //Min. value of RGB
  float fmax = max(max(color.r, color.g), color.b);    //Max. value of RGB
  float delta = fmax - fmin;             //Delta RGB value
  
  hsl.z = (fmax + fmin) / 2.0; // Luminance
  
  if (delta == 0.0)		//This is a gray, no chroma...
  {
    hsl.x = 0.0;	// Hue
    hsl.y = 0.0;	// Saturation
  }
  else                                    //Chromatic data...
  {
    if (hsl.z < 0.5)
      hsl.y = delta / (fmax + fmin); // Saturation
    else
      hsl.y = delta / (2.0 - fmax - fmin); // Saturation
    
    float deltaR = (((fmax - color.r) / 6.0) + (delta / 2.0)) / delta;
    float deltaG = (((fmax - color.g) / 6.0) + (delta / 2.0)) / delta;
    float deltaB = (((fmax - color.b) / 6.0) + (delta / 2.0)) / delta;
    
    if (color.r == fmax )
      hsl.x = deltaB - deltaG; // Hue
    else if (color.g == fmax)
      hsl.x = (1.0 / 3.0) + deltaR - deltaB; // Hue
    else if (color.b == fmax)
      hsl.x = (2.0 / 3.0) + deltaG - deltaR; // Hue
    
    if (hsl.x < 0.0)
      hsl.x += 1.0; // Hue
    else if (hsl.x > 1.0)
      hsl.x -= 1.0; // Hue
  }
  
  return hsl;
}

static float3 HSLToRGB(float3 hsl)
{
  float3 rgb;
  
  if (hsl.y == 0.0)
    rgb = float3(hsl.z, hsl.z, hsl.z); // Luminance
  else
  {
    float f2;
    
    if (hsl.z < 0.5)
      f2 = hsl.z * (1.0 + hsl.y);
    else
      f2 = (hsl.z + hsl.y) - (hsl.y * hsl.z);
    
    float f1 = 2.0 * hsl.z - f2;
    
    rgb.r = HueToRGB(f1, f2, hsl.x + (1.0/3.0));
    rgb.g = HueToRGB(f1, f2, hsl.x);
    rgb.b= HueToRGB(f1, f2, hsl.x - (1.0/3.0));
  }
  
  return rgb;
}

static float _sind( const float _a) {
  {
    return sin((_a * 0.017453292));;
  }
}

static float _cosd( const float _a) {
  {
    return cos((_a * 0.017453292));;
  }
}

static float _added( const float2 _sh, const float _sa, const float _ca, const float2 _c, const float _d) {
  {
    return ((0.5 + (0.25 * cos(((((_sh.x * _sa) + (_sh.y * _ca)) + _c.x) * _d)))) + (0.25 * cos(((((_sh.x * _ca) - (_sh.y * _sa)) + _c.y) * _d))));;
  }
}

static float4 Halftone(const float2 fc, texture2d<float> vid0) {
  {
    float _threshold = 0.8;
//    float _ratio = (reso.y / reso.x);
    float _coordX = (fc.x );
    float _coordY = (fc.y );
    float2 _dstCoord = float2(_coordX, _coordY);
    float2 _srcCoord = float2(_coordX, (_coordY ));
    float2 _rotationCenter = float2(0.5, 0.5);
    float2 _shift = (_dstCoord - _rotationCenter);
    float _dotSize = 1.0;
    float _angle = 45.0;
    float _rasterPattern = _added(_shift, _sind(_angle), _cosd(_angle), _rotationCenter, ((PI / _dotSize) * 680.0));
    float4 _srcPixel = vid0.sample(iChannel0, _srcCoord);
    float _avg = (((0.21250001 * _srcPixel.x) + (0.71539998 * _srcPixel.y)) + (0.072099999 * _srcPixel.z));
    float _gray = ((((_rasterPattern * _threshold) + _avg) - _threshold) / (1.0 - _threshold));
    return float4(_gray, _gray, _gray, 1.0) * _srcPixel;
  }
}

fragmentFunc(texture2d<float> tex)
{
  const float2 uv = textureCoord;
  
  float fCartoonEffect = 50.0;
  float outline = 0.0001;
  float saturation = 2.0;
  
  float SensitivityUpper = fCartoonEffect;
  float SensitivityLower = fCartoonEffect;
  
  float dx = outline;
  float dy = outline;
  
  float4 c1 = tex.sample(iChannel0, uv +  float2(-dx,-dy));
  float4 c2 = tex.sample(iChannel0, uv + float2(0,-dy));
  float4 c3 = tex.sample(iChannel0, uv +  float2(-dx,dy));
  float4 c4 = tex.sample(iChannel0, uv +  float2(-dx,0));
  float4 c5 = tex.sample(iChannel0, uv +  float2(0,0));
  float4 c6 = tex.sample(iChannel0, uv +  float2(dx,0));
  float4 c7 = tex.sample(iChannel0, uv +  float2(dx,-dy));
  float4 c8 = tex.sample(iChannel0, uv +  float2(0,dy));
  float4 c9 = tex.sample(iChannel0, uv +  float2(dx,dy));
  
  float4 c0 = (-c1-c2-c3-c4+c6+c7+c8+c9);
  
  float4 average = (c1 + c2 + c3 + c4 + c6 +  c7 + c8 + c9) - (c5 * 6.0);
  float av = (average.x + average.y + average.z) / 3.0;
  
  c0 = float4(1.0-abs((c0.r+c0.g+c0.b)/av));
  float val = pow(saturate((c0.r + c0.g + c0.b) / 3.0), SensitivityUpper);
  val = 1.0 - pow(abs(1.0 - val), SensitivityLower);
  c0 = float4(val, val, val, val);
  
  c1 = tex.sample(iChannel0, uv);
  
  float3 hsl = RGBToHSL(c1.xyz);
  hsl.g *= saturation;
  c1 = float4(HSLToRGB(hsl),1.0);
  
  float4 basePixel = c1 * c0;
  float4 overlayPixel = Halftone(uv, tex);
  
  if (overlayPixel.x > 0.0) {
    overlayPixel = basePixel;
  }
  
  return overlayPixel;
}
