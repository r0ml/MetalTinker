
// FIXME: do this with vertex shader

#define shaderName verbose_raytrace_quad

#include "Common.h" 

struct InputBuffer {
};

initialize() {
}

static float plane( float3 norm, float3 po, float3 ro, float3 rd ) {
  float de = dot(norm, rd);
  de = sign(de)*max( abs(de), 0.001);
  return dot(norm, po-ro)/de;
}

static float2 raytraceTexturedQuad( float3 rayOrigin, float3 rayDirection, float3 quadCenter, float3 quadRotation, float2 quadDimensions) {
  //Rotations ------------------
  float a = sin(quadRotation.x); float b = cos(quadRotation.x);
  float c = sin(quadRotation.y); float d = cos(quadRotation.y);
  float e = sin(quadRotation.z); float f = cos(quadRotation.z);
  float ac = a*c;   float bc = b*c;

  float3x3 RotationMatrix  =
  float3x3(	  d*f,      d*e,  -c,
           ac*f-b*e, ac*e+b*f, a*d,
           bc*f+a*e, bc*e-a*f, b*d );
  //--------------------------------------

  float3 right = RotationMatrix * float3(quadDimensions.x, 0.0, 0.0);
  float3 up = RotationMatrix * float3(0, quadDimensions.y, 0);
  float3 normal = cross(right, up);
  normal /= length(normal);

  //Find the plane hit point in space
  float3 pos = (rayDirection * plane(normal, quadCenter, rayOrigin, rayDirection)) - quadCenter;

  //Find the texture UV by projecting the hit point along the plane dirs
  return float2(dot(pos, right) / dot(right, right),
                dot(pos, up)    / dot(up,    up)) + 0.5;
}

fragmentFn(texture2d<float> tex) {
  //Screen UV goes from 0 - 1 along each axis
  float2 p = worldCoordAspectAdjusted;
  float screenAspect = uni.iResolution.x/uni.iResolution.y;

  //Normalized Ray Dir
  float3 dir = float3(p.x, p.y, 1.0);
  dir /= length(dir);

  //Define the plane
  float3 planePosition = float3(0.0, 0.0, 0.5);
  float3 planeRotation = float3(0.4*cos(0.3*uni.iTime), 0.4*sin(0.6*uni.iTime), 0.0);
  float2 planeDimension = float2(-screenAspect, 1.0);

  float2 uv = raytraceTexturedQuad(float3(0), dir, planePosition, planeRotation, planeDimension);

  //If we hit the rectangle, sample the texture
  if(abs(uv.x - 0.5) < 0.5 && abs(uv.y - 0.5) < 0.5) {
    return float4(tex.sample(iChannel0, uv).xyz, 1.0);
  }
  return 0;
}
