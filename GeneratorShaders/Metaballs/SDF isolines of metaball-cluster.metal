
#define shaderName SDF_isolines_of_metaball_cluster

#include "Common.h"

constant const int MAX_STEPS = 64;
constant const float EPSILON = .0001;
constant const float STEP_SIZE = .975;

static float opCombine (const float d1, const float d2, const float r) {
  float h = clamp (.5 + .5 * (d2 - d1) / r, .0, 1.);
  return mix (d2, d1, h) - r * h * (1. - h);
}

static float metaBalls (const float3 p, float time) {
  float r1 = .1 + .3 * (.5 + .5 * sin (2. * time));
  float r2 = .15 + .2 * (.5 + .5 * sin (3. * time));
  float r3 = .2 + .2 * (.5 + .5 * sin (4. * time));
  float r4 = .25 + .1 * (.5 + .5 * sin (5. * time));
  
  float t = 2. * time;
  float3 offset1 = float3 (-.1*cos(t), .1, -.2*sin(t));
  float3 offset2 = float3 (.2, .2*cos(t), .3*sin(t));
  float3 offset3 = float3 (-.2*cos(t), -.2*sin(t), .3);
  float3 offset4 = float3 (.1, -.4*cos(t), .4*sin(t));
  float3 offset5 = float3 (.4*cos(t), -.2, .3*sin(t));
  float3 offset6 = float3 (-.2*cos(t), -.4, -.4*sin(t));
  float3 offset7 = float3 (.3*sin(t), -.6*cos(t), .6);
  float3 offset8 = float3 (-.3, .5*sin(t), -.4*cos(t));
  
  float ball1 = sdSphere (p + offset1, r4);
  float ball2 = sdSphere (p + offset2, r2);
  float metaBalls = opCombine (ball1, ball2, r1);
  
  ball1 = sdSphere (p + offset3, r1);
  ball2 = sdSphere (p + offset4, r3);
  metaBalls = opCombine (metaBalls, opCombine (ball1, ball2, .2), r2);
  
  ball1 = sdSphere (p + offset5, r3);
  ball2 = sdSphere (p + offset6, r2);
  metaBalls = opCombine (metaBalls, opCombine (ball1, ball2, .2), r3);
  
  ball1 = sdSphere (p + offset7, r3);
  ball2 = sdSphere (p + offset8, r4);
  metaBalls = opCombine (metaBalls, opCombine (ball1, ball2, .2), r4);
  
  return metaBalls;
}

static float map (const float3 p, float time, float2 mouse) {
  return min (metaBalls (p, time), p.y + 2. * (2. * (1. - mouse.y ) - 1.) );
}

static float march (const float3 ro, const float3 rd, float time, float2 mouse) {
  float t = .0;
  float d = .0;
  for (int i = 0; i < MAX_STEPS; ++i) {
    float3 p = ro + d * rd;
    t = map (p, time, mouse);
    if (t < EPSILON) break;
    d += t*STEP_SIZE;
  }
  
  return d;
}

// pbr, shading, shadows ///////////////////////////////////////////////////////
static float distriGGX (const float3 N, const float3 H, const float roughness) {
  float a2     = roughness * roughness;
  float NdotH  = max (dot (N, H), .0);
  float NdotH2 = NdotH * NdotH;
  
  float nom    = a2;
  float denom  = (NdotH2 * (a2 - 1.) + 1.);
  denom        = PI * denom * denom;
  
  return nom / denom;
}

static float geomSchlickGGX (const float NdotV, const float roughness) {
  float nom   = NdotV;
  float denom = NdotV * (1. - roughness) + roughness;
  
  return nom / denom;
}

static float geomSmith (const float3 N, const float3 V, const float3 L, const float roughness) {
  float NdotV = max (dot (N, V), .0);
  float NdotL = max (dot (N, L), .0);
  float ggx1 = geomSchlickGGX (NdotV, roughness);
  float ggx2 = geomSchlickGGX (NdotL, roughness);
  
  return ggx1 * ggx2;
}

static float3 fresnelSchlick (const float cosTheta, const float3 F0, float roughness) {
  return F0 + (max (F0, float3(1. - roughness)) - F0) * pow (1. - cosTheta, 5.);
}

static float3 normal (const float3 p, float time, float2 mouse) {
  float d = map (p, time, mouse);
  float3 e = float3 (.001, .0, .0);
  return normalize (float3 (map (p + e.xyy, time, mouse) - d,
                            map (p + e.yxy, time, mouse) - d,
                            map (p + e.yyx, time, mouse) - d));
}

static float shadow (const float3 p, const float3 lPos, float time, float2 mouse) {
  float lDist = distance (p, lPos);
  float3 lDir = normalize (lPos - p);
  float dist = march (p, lDir, time, mouse);
  return dist < lDist ? .1 : 1.;
}

static float3 shade (const float3 ro, const float3 rd, const float d, float time, float2 mouse) {
  float3 p = ro + d * rd;
  float3 nor = normal (p, time, mouse);
  
  // "material" hard-coded for the moment
  float mask = smoothstep (1., .05, 30.*cos (50.*p.y)+sin (50.*p.x)+ cos (50.*p.z));
  float3 albedo = mix (float3 (.5), float3 (.2), mask);
  float metallic = .5;
  float roughness = mix (.45, .175, mask);
  float ao = 1.;
  
  // lights hard-coded as well atm
  float3 lightColors[2];
  lightColors[0] = float3 (.7, .8, .9)*2.;
  lightColors[1] = float3 (.9, .8, .7)*2.;
  
  float3 lightPositions[2];
  lightPositions[0] = float3 (-1.5, 1.0, -3.);
  lightPositions[1] = float3 (2., -.5, 3.);
  
  float3 N = normalize (nor);
  float3 V = normalize (ro - p);
  
  float3 F0 = float3 (0.04);
  F0 = mix (F0, albedo, metallic);
  float3 kD = float3(.0);
  
  // reflectance equation
  float3 Lo = float3 (.0);
  for(int i = 0; i < 2; ++i)
  {
    // calculate per-light radiance
    float3 L = normalize(lightPositions[i] - p);
    float3 H = normalize(V + L);
    float distance    = length(lightPositions[i] - p);
    float attenuation = 20. / (distance * distance);
    float3 radiance     = lightColors[i] * attenuation;
    
    // cook-torrance brdf
    //        float aDirect = pow (roughness + 1., 2.);
    //        float aIBL =  roughness * roughness;
    float NDF = distriGGX(N, H, roughness);
    float G   = geomSmith(N, V, L, roughness);
    float3 F    = fresnelSchlick(max(dot(H, V), 0.0), F0, roughness);
    
    float3 kS = F;
    kD = float3(1.) - kS;
    kD *= 1. - metallic;
    
    float3 nominator    = NDF * G * F;
    float denominator = 4. * max(dot(N, V), 0.0) * max(dot(N, L), 0.0);
    float3 specular     = nominator / max(denominator, .001);
    
    // add to outgoing radiance Lo
    float NdotL = max(dot(N, L), 0.0);
    Lo += (kD * albedo / PI + specular) * radiance * NdotL;
    Lo *= shadow (p+.01*N, L, time, mouse);
  }
  
  float3 irradiance = float3 (1.);
  float3 diffuse    = irradiance * albedo;
  float3 ambient    = (kD * diffuse) * ao;
  
  return ambient + Lo;
}

// create view-ray /////////////////////////////////////////////////////////////
static float3 camera (const float2 uv, const float3 ro, const float3 aim, const float zoom) {
  float3 camForward = normalize (float3 (aim - ro));
  float3 worldUp = float3 (.0, 1., .0);
  float3 camRight = normalize (cross (worldUp, camForward));
  float3 camUp = normalize (cross (camForward, camRight));
  float3 camCenter = ro + camForward * zoom;
  
  return normalize (camCenter + uv.x * camRight + uv.y * camUp - ro);
}

// bringing it all together ////////////////////////////////////////////////////
fragmentFunc(constant float2& mouse) {
  float2 uv = worldCoordAdjusted;
  float2 uvRaw = textureCoord;

  // set up "camera", view origin (ro) and view direction (rd)
  float t = scn_frame.time + 5.;
  float angle = radians (300. + 55. * t);
  float dist = 1.25 + cos (1.5 * t);
  float3 ro = float3 (dist * cos (angle), 2., dist * sin (angle));
  float3 aim = float3 (.0);
  float zoom = 2.;
  float3 rd = camera (uv, ro, aim, zoom);
  
  float d = march (ro, rd, scn_frame.time, mouse);
  float3 p = ro + d * rd;
  
  //    float3 n = normal (p);
  float3 col = shade (ro, rd, d, scn_frame.time, mouse);
  col = mix (col, float3 (.0), pow (1. - 1. / d, 5.));
  
  // painting the isolines
  float isoLines = metaBalls (p, scn_frame.time);
  float density = 4.;
  float thickness = 260.;
  if (isoLines > EPSILON) {
    col = mix (col, float3 (.1, .2, .5), pow (1. - 1. / d, 5.));
    col.rgb *= saturate (abs (fract (isoLines*density)*2.-1.)*thickness/(d*d));
  }
  
  // tone-mapping, gamme-correction, vignette
  col = col / (1. + col);
  col = sqrt (col);
  col *= .2 + .8 * pow (16. * uvRaw.x * uvRaw.y * (1. - uvRaw.x) * (1. - uvRaw.y), .15);
  
  return float4 (col, 1.);
}
