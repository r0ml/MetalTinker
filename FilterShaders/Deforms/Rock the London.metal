
// FIXME: can I do this by rotating the plane? (vertex shader)
#define shaderName rock_the_london

#include "Common.h" 

struct C_Ray {
  float3 vOrigin;
  float3 vDir;
};

static void GetCameraRay( const float3 vPos, const float3 vForwards, const float3 vWorldUp, const float2 vUV, thread C_Ray& ray)
{
  float2 vViewCoord = vUV * 2.0 - 1.0;

  ray.vOrigin = vPos;

  float3 vRight = normalize(cross(vWorldUp, vForwards));
  float3 vUp = cross(vRight, vForwards);

  ray.vDir = normalize( vRight * vViewCoord.x + vUp * vViewCoord.y + vForwards);
}

static void GetCameraRayLookat( const float3 vPos, const float3 vInterest, const float2 winCoord, thread C_Ray& ray)
{
  float3 vForwards = normalize(vInterest - vPos);
  float3 vUp = float3(0.0, 1.0, 0.0);

  GetCameraRay(vPos, vForwards, vUp, winCoord, ray);
}

fragmentFn(texture2d<float> tex) {
  C_Ray ray;
  // adjust this for distance and edge distrotion.

  float zPosition = 3.0;
  float3 vCameraPos = float3(0.0, 0.0, zPosition);
  vCameraPos.x += sin(uni.iTime * 5.0) * 0.5;

  float3 vCameraIntrest = float3(0.0, 0.0, 20.0);
  GetCameraRayLookat( vCameraPos, vCameraIntrest, textureCoord, ray);

  float fHitDist = 100.0; // Raymarch(ray);
  float3 vHitPos = ray.vOrigin + ray.vDir * fHitDist;
  float3 vProjPos = vHitPos;

  float fProjectionDist = 0.5;
  float2 vUV = float2(((vProjPos.xy) * fProjectionDist) / vProjPos.z);

  float2 vProjectionOffset = float2(0.5, 0.5);
  vUV += vProjectionOffset;

  // flip the texture coordinates
  vUV.y = 1.0 - vUV.y;
  //float scale = 0.9;
  //vUV = (((vUV * 2.0) - 1.0) * scale + scale) * 0.5;

  float3 vResult = tex.sample(iChannel0, vUV).rgb;

  return float4(vResult, 1.0);
}
