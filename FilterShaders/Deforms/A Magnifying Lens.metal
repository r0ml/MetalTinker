/** 
 It's a lens which magnifies and removes blurriness. Click and drag the mouse to move the lens around.
 */
#define shaderName a_magnifying_lens

#include "Common.h" 

static float normalDistribution(const float mean, const float deviation, const float x)
{
  // 2.50662827463 = sqrt(2 * pi)
  return (1.0 / (2.50662827463 * deviation)) * exp((-1.0 * pow(x - mean, 2.0))/(2.0 * pow(deviation, 2.0)));
}

static float4 sampleTexture(const texture2d<float> smp, const float2 winCoord, const float2 uvOffsets, float2 reso)
{
  const float textureEdgeOffset = 0.005;

  float2 textureCoordinates = (winCoord + uvOffsets) / reso.xy;
  textureCoordinates.y = 1.0 - textureCoordinates.y;
  textureCoordinates = clamp(textureCoordinates, 0.0 + textureEdgeOffset, 1.0 - textureEdgeOffset);
  return smp.sample(iChannel0, textureCoordinates);
}

fragmentFn(texture2d<float> tex) {
  const float textureSamplesCount = 8.0;
  const float mean = 0.0;

  float2 mouseCoords = uni.iMouse.xy * uni.iResolution;
  // This causes the lens to animate in a figure-eight pattern if the user hasn't clicked anything.
  if ( all(mouseCoords == float2(0.0)) )
  {
    mouseCoords = (float2(sin(uni.iTime), sin(uni.iTime) * cos(uni.iTime)) * 0.35 + float2(0.5)) * uni.iResolution.xy;
  }

  float distanceFromLensCenter = distance(thisVertex.where.xy, mouseCoords);
  float distanceFactor = -1.0 * pow(0.04 * 640.0 / uni.iResolution.x * distanceFromLensCenter, 5.0) + uni.iResolution.x;
  distanceFactor = max(1.0, distanceFactor);

  float2 textureDisplacement = float2(0.0, 0.0);
  if (distanceFactor > 1.0)
  {
    float displacementFactor = distanceFromLensCenter / 2.0;
    textureDisplacement = normalize(mouseCoords - thisVertex.where.xy) * displacementFactor;
  }

  float standardDeviation = 40.0/distanceFactor;

  float divisor = (normalDistribution(mean, standardDeviation, 0.0) + 1.0) * distanceFactor;
  float4 accumulator = sampleTexture(tex, thisVertex.where.xy, textureDisplacement, uni.iResolution) * divisor;

  float2 polarityArray[4];
  polarityArray[0] = float2(1.0, 1.0);
  polarityArray[1] = float2(-1.0, 1.0);
  polarityArray[2] = float2(1.0, -1.0);
  polarityArray[3] = float2(-1.0, -1.0);

  for (float y = 1.0; y < textureSamplesCount; ++y)
  {
    for (float x = 1.0; x < textureSamplesCount; ++x)
    {
      float multiplier = normalDistribution(mean, standardDeviation, distance(float2(0.0), float2(x, y))) + 1.0;

      for (int p = 0; p < 4; ++p)
      {
        float2 offset = float2(x, y) * polarityArray[p];
        accumulator += sampleTexture(tex, thisVertex.where.xy, offset, uni.iResolution) * multiplier;
        divisor += (multiplier);
      }
    }
  }

  return accumulator / divisor;
}

