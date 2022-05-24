
#define shaderName BiCapsule

#include "Common.h"

struct InputBuffer { };
initialize() {}

#define MAX_ITERATIONS 128
#define MIN_DISTANCE .001
#define NEAR_PLANE    1.
#define FAR_PLANE    5.

static float3 closestPointToBiCapsule(float3 pos, float3 a, float3 b, float r1, float r2) {
  //Standard line segment closest point
  float3 ba = b - a; float baMagnitude = length(ba);
  float alpha = (dot(pos - a, ba) / dot(ba, ba));
  float3 capsuleSegmentPos = mix(a, b, alpha);
  
  //Calculate the offset along segment according to the slope of the bicapsule
  float pointSphereRadius = r1 - r2; //This collapses the problem into finding the tangent angle for a point/sphere
  float exsecantLength = ((baMagnitude / abs(pointSphereRadius)) - 1.0) * baMagnitude;
  float tangentAngle =  acos(1.0 / (exsecantLength + 1.0)); //This is also known as the "arcexsecant" function
  float tangentOffset = length(capsuleSegmentPos - pos) / tan(tangentAngle); //This is adjacent / tan(theta) = opposite
  tangentOffset *= sign(pointSphereRadius); //Allows it to handle r2 > r1 as well
  
  //And back to classic capsule closest point (with lerped radii)
  float clampedOffsetAlpha = saturate(alpha - tangentOffset);
  float3 bicapsuleSegmentPos = mix(a, b, clampedOffsetAlpha); float bicapsuleRadius = mix(r1, r2, clampedOffsetAlpha);
  return bicapsuleSegmentPos + (normalize(pos - bicapsuleSegmentPos) * bicapsuleRadius);
}


static float3 offsetToSurface(float3 pos, float time) {
  float3 a = float3(-0.5, 0.0, 2.0);
  float3 b = float3(0.5 + (sin(time)*0.5), (cos(time)*0.5), 2.0);
  
  float3 closestPoint = closestPointToBiCapsule(pos, a, b, (sin(time*3.0)*0.3)+0.3, 0.2);
  return closestPoint - pos;
}

fragmentFn() {
  float2 uv = thisVertex.where.xy.xy / uni.iResolution.xy;
  float3 rayDir = float3( uv.x - 0.5, (uv.y - 0.5) * uni.iResolution.y / uni.iResolution.x, 0.5 );
  float3 toSurfaceOffset;
  
  float depth = NEAR_PLANE; float curDist = MIN_DISTANCE;
  for(int i = 0; i < MAX_ITERATIONS; i++) {
    depth += curDist;
    toSurfaceOffset = offsetToSurface(rayDir * depth, uni.iTime);
    curDist = length(toSurfaceOffset);
    
    if (curDist <= MIN_DISTANCE || depth > FAR_PLANE)
      break;
  }
  
  if(depth < FAR_PLANE){
    return float4(saturate(dot(float3(1.0, 1.0, -1.0), -toSurfaceOffset/curDist)*0.5)+0.1);
  }else{
    return float4(0);
  }
}
