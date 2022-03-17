
#define shaderName Reprojection

#include "Common.h"

struct InputBuffer {
  bool ENABLE_SHADOW = false;
};

initialize() {
}


constant const int kMaxIterations = 64;

// Turn up iterations if you enable this
//#define ENABLE_SHADOW

struct C_Ray
{
  float3 vOrigin;
  float3 vDir;
};

float3 RotateY( const float3 vPos, const float s, const float c )
{
  float3 vResult = float3( c * vPos.x + s * vPos.z, vPos.y, -s * vPos.x + c * vPos.z);

  return vResult;
}

/////////////////////////////////////
// Scene Description 

float GetDistanceBox(const float3 vPos, const float3 vDimension)
{
  return length(max(abs(vPos)-vDimension,0.0));
}

// result is x=scene distance y=material or object id; zw are material specific parameters (maybe uv co-ordinates)
float GetDistanceScene( const float3 vPos )
{   
  float fResult = 1000.0;

  float fFloorDist = vPos.y + 3.2;
  fResult = min(fResult, fFloorDist);


  float3 vBuilding1Pos = float3(58.8, 0.0, 50.0);
  const float fBuilding1Radius = 50.0;
  float3 vBuilding1Offset = vBuilding1Pos - vPos;
  float fBuilding1Dist = length(vBuilding1Offset.xz) - fBuilding1Radius;

  fResult = min(fResult, fBuilding1Dist);



  float3 vBuilding2Pos = float3(60.0, 0.0, 55.0);
  const float fBuilding2Radius = 100.0;
  float3 vBuilding2Offset = vBuilding2Pos - vPos;
  float fBuilding2Dist = length(vBuilding2Offset.xz) - fBuilding2Radius;

  fBuilding2Dist = max(vBuilding2Offset.z - 16.0, -fBuilding2Dist); // back only

  fResult = min(fResult, fBuilding2Dist);


  float3 vBollardDomain = vPos;
  vBollardDomain -= float3(1.0, -2.0, 13.5);
  vBollardDomain = RotateY(vBollardDomain, sin(0.6), cos(0.6));
  float fBollardDist = GetDistanceBox(vBollardDomain, float3(0.2, 1.3, 0.2));

  fResult = min(fResult, fBollardDist);


  float3 vFenceDomain = vPos;
  vFenceDomain -= float3(-5.5, -2.5, 7.0);
  vFenceDomain = RotateY(vFenceDomain, sin(1.0), cos(1.0));
  float fFenceDist = GetDistanceBox(vFenceDomain, float3(0.5, 1.2, 0.2));

  fResult = min(fResult, fFenceDist);



  float3 vCabDomain = vPos;
  vCabDomain -= float3(-1.4, -1.5,29.5);
  vCabDomain = RotateY(vCabDomain, sin(0.01), cos(0.01));
  float fCabDist = GetDistanceBox(vCabDomain, float3(1.2, 1.5, 3.0));

  fResult = min(fResult, fCabDist);


  float3 vBusDomain = vPos;
  vBusDomain -= float3(-15.25, -2.0, 30.0);
  vBusDomain = RotateY(vBusDomain, sin(0.3), cos(0.3));
  float fBusDist = GetDistanceBox(vBusDomain, float3(1.0, 3.0, 3.0));

  fResult = min(fResult, fBusDist);


  float3 vBusShelter = vPos;
  vBusShelter -= float3(7.5, -2.0, 30.0);
  vBusShelter = RotateY(vBusShelter, sin(0.3), cos(0.3));
  float fBusShelterDist = GetDistanceBox(vBusShelter, float3(1.0, 5.0, 2.0));

  fResult = min(fResult, fBusShelterDist);

  float3 vRailings = vPos;
  vRailings -= float3(12.0, -2.0, 18.0);
  vRailings = RotateY(vRailings, sin(0.3), cos(0.3));
  float fRailings = GetDistanceBox(vRailings, float3(1.0, 1.0, 2.0));

  fResult = min(fResult, fRailings);


  float3 vCentralPavement = vPos;
  vCentralPavement -= float3(5.3, -3.0, 8.0);
  vCentralPavement = RotateY(vCentralPavement, sin(0.6), cos(0.6));
  float fCentralPavementDist = GetDistanceBox(vCentralPavement, float3(0.8, 0.2, 8.0));

  fResult = min(fResult, fCentralPavementDist);



  return fResult;
}

/////////////////////////////////////
// Raymarching 


// This is an excellent resource on ray marching -> http://www.iquilezles.org/www/articles/distfunctions/distfunctions.htm
float Raymarch( const C_Ray ray )
{        
  float fDistance = 0.1;

  for(int i=0;i<=kMaxIterations;i++)
  {
    float fSceneDist = GetDistanceScene( ray.vOrigin + ray.vDir * fDistance );

    if((fSceneDist <= 0.01) || (fDistance >= 1000.0))
    {
      break;
    }

    fDistance = fDistance + fSceneDist;
  }

  fDistance = min(fDistance, 1000.0);

  return fDistance;
}


void GetCameraRay( const float3 vPos, const float3 vForwards, const float3 vWorldUp, const float2 vUV, thread C_Ray& ray)
{
  float2 vViewCoord = vUV * 2.0 - 1.0;

  //	vViewCoord.y *= -1.0;

  ray.vOrigin = vPos;

  float3 vRight = normalize(cross(vWorldUp, vForwards));
  float3 vUp = cross(vRight, vForwards);

  ray.vDir = normalize( vRight * vViewCoord.x + vUp * vViewCoord.y + vForwards);
}

void GetCameraRayLookat( const float3 vPos, const float3 vInterest, const float2 winCoord, thread C_Ray& ray)
{
  float3 vForwards = normalize(vInterest - vPos);
  float3 vUp = float3(0.0, 1.0, 0.0);

  GetCameraRay(vPos, vForwards, vUp, winCoord, ray);
}

float3 GetColor( C_Ray ray, texture2d<float> tex0, const int buttons, const bool shadow )
{
  float fHitDist = Raymarch(ray);
  float3 vHitPos = ray.vOrigin + ray.vDir * fHitDist;

  float3 vProjPos = vHitPos;

  float fProjectionDist = 0.5;
  float2 vUV = float2(((vProjPos.xy) * fProjectionDist) / vProjPos.z);

  float2 vProjectionOffset = float2(-0.5, -0.61);
  vUV += vProjectionOffset;

  vUV.y = 1.0 - vUV.y;

  float3 vResult = tex0.sample(iChannel0, vUV).rgb;

  if (buttons)
  {
    float3 vGrid =  step(fract(vHitPos / 5.0), float3(0.9));
    vResult = mix(float3(1.0, 1.0, 1.0), vResult, vGrid);
  }

  if (shadow) {
  C_Ray shadowRay;
  shadowRay.vOrigin = float3(0.0, 0.0, 0.0);
  shadowRay.vDir = normalize(vHitPos);

  float fLength = length(vHitPos);
  float fShadowDist = Raymarch(shadowRay);

  vResult *= 0.2 + 0.8 * step(fLength, fShadowDist + 0.1);
  }

  return vResult;
}

fragmentFn(texture2d<float> tex)
{
  C_Ray ray;

  float3 vCameraPos = float3(0.0, 0.0, 0.0);

  vCameraPos.x += sin(uni.iTime * 5.0) * 1.5;
  vCameraPos.z += (sin(uni.iTime * 3.0) + 1.2) * 3.0;

  float3 vCameraIntrest = float3(0.0, 1.0, 20.0);

  GetCameraRayLookat( vCameraPos, vCameraIntrest, textureCoord, ray);

  float3 vResult = GetColor( ray , tex, uni.mouseButtons, in.ENABLE_SHADOW);

  return float4(vResult,1.0);
}
