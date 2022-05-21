
#define shaderName Blobs_DistanceMergingTheory

#include "Common.h"

//Input [d1,d2,d3] : the 3 distances to the 3blobs.
static float mergeBlobs(float d1, float d2, float d3)
{
  float k = 22.0;
  return -log(exp(-k*d1)+exp(-k*d2)+exp(-k*d3))/k;
}

static float2 randomizePos(float2 amplitude, float fTime)
{
  return amplitude*float2(sin(fTime*1.00)+cos(fTime*0.51),
                          sin(fTime*0.71)+cos(fTime*0.43));
}

static float3 computeColor(float d1, float d2, float d3)
{
  float blobDist = mergeBlobs(d1,d2,d3);
  float k = 7.0; //k=Color blend distance.
  float w1 = exp(k*(blobDist-d1)); //R Contribution : highest value when no blending occurs
  float w2 = exp(k*(blobDist-d2)); //G Contribution
  float w3 = exp(k*(blobDist-d3)); //b Contribution
  
  //Color weighting & normalization
  float3 pixColor = float3(w1,w2,w3)/(w1+w2+w3);
  
  //2.5 = lightness adjustment.
  return 2.5*pixColor;
}

static float distanceToBlobs(float2 p, thread float3& color, float time)
{
  //Blob movement range.
  float mvtAmplitude = 0.15;
  
  //Randomized positions.
  float2 blob1pos = float2(-0.250, -0.020)+randomizePos(float2(0.35,0.45)*mvtAmplitude,time*1.50);
  float2 blob2pos = float2( 0.050,  0.100)+randomizePos(float2(0.60,0.10)*mvtAmplitude,time*1.23);
  float2 blob3pos = float2( 0.150, -0.100)+randomizePos(float2(0.70,0.35)*mvtAmplitude,time*1.86);
  
  //Distance from pixel "p" to each blobs
  float d1 = length(p-blob1pos);
  float d2 = length(p-blob2pos);
  float d3 = length(p-blob3pos);
  
  //Merge distances, return the distorted distance field to the closest blob.
  float distTotBlob = mergeBlobs(d1,d2,d3);
  
  //Compute color, approximating the contribution of each one of the 3 blobs.
  color = computeColor(d1,d2,d3);
  
  return abs(distTotBlob);
}

fragmentFunc()
{
  float2 uv = worldCoordAdjusted / 2;
  float3 blobColor;
  
  //Distance from this pixel to the blob (range ~= [0-0.5] )
  float dist = distanceToBlobs(uv,blobColor, scn_frame.time);
  
  float stripeHz = 20.0;//BW Stripe frequency : 20 Hz frequency (cycles/image unit)
  float stripeTh = 0.25; //Switchover value, in the [0.-0.5] range. (0.25 = right const the middle)
  float aa = 0.001; //aa = transition width (pixel "antialiazing" or smoothness)
  float stripeIntensity = smoothstep(stripeTh-aa*stripeHz,stripeTh+aa*stripeHz,abs(fract(dist*stripeHz)-0.5));
  float blobContourIsovalue = 0.113; //Arbitrary distance from center at which we decide to set the blob boundary.
  float fBlobLerp = smoothstep(blobContourIsovalue-aa,blobContourIsovalue+aa,dist);
  
  return mix(float4(blobColor,1),float4(stripeIntensity),fBlobLerp);
}
