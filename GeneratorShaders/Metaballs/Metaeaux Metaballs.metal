
#define shaderName metaeaux_metaballs

#include "Common.h" 

constant const float4 ambientColor = float4(127./255.,199./255.,175./255., 1.0);
constant const float4 skyColor = 0.8 * float4(63./255.,184./255.,175./255., 1.0);

static float smoothMin( float a, float b, float k )
{
  float h = saturate( 0.5+0.5*(b-a)/k);
  return mix( b, a, h ) - k*h*(1.0-h);
}

static float sploosh(float3 p, float sizeFac, float distFac, float time) {
  float d = sdSphere(p, .4);
  const int n = 4;
  
  float size = 0.2 + 0.1 * abs(cos(time));
  float3 q1 = p;
  float3 q2 = p;
  float3 q3 = p;
  float3 q4 = p;
  
  for (int i = 1; i < n; i++){
    float distX = 0.3 + 0.3 * sin(time * 0.7429);
    float distY = 0.2 - 0.2 * cos(time * 1.242);
    
    q1 += float3(distX, distY, 0.);
    q2 += float3(-distX, distY, 0.);
    q3 += float3(sin(time * 0.342) * distX, sin(time)-distY, 0.);
    q4 += float3(cos(time) * distX, -distY, 0.);
    size = 0.2 + 0.3 * abs(cos(float(n) * size));
    float d1 = sdSphere(q1, size);
    size = 0.2 + 0.3 * abs(cos(float(n) * 0.14159 * size));
    float d2 = sdSphere(q2, size);
    size = 0.2 + 0.3 * abs(sin(float(n) * 0.014159 * size));
    float d3 = sdSphere(q3, size);
    float d4 = sdSphere(q4, size);
    float blendDistance = 0.4;
    
    d = smoothMin(d, smoothMin(d1, d2, blendDistance), blendDistance);
    d = smoothMin(d, smoothMin(d3, d4, blendDistance), blendDistance);
  }
  
  return d;
}

static float distanceField(float3 p, float time) {
  return sploosh(p, 0.01, .02, time);
}

static float3 getNormal(float3 p, float time)
{
  float h = 0.0001;
  
  return normalize(float3(
                          distanceField(p + float3(h, 0, 0), time) - distanceField(p - float3(h, 0, 0), time),
                          distanceField(p + float3(0, h, 0), time) - distanceField(p - float3(0, h, 0), time),
                          distanceField(p + float3(0, 0, h), time) - distanceField(p - float3(0, 0, h), time)));
}

// phong shading
static float4 phong(float3 p, float3 normal, float3 lightPos, float4 lightColor)
{
  float lightIntensity = 0.0;
  float3 lightDirection = normalize(lightPos - p);
  
  // lambert shading
  lightIntensity = max(0., dot(normal, lightDirection));
  
  // lambert shading
  float4 colour = lightColor * lightIntensity;
  
  // specular highlights
  colour += pow(lightIntensity, 16.0) * (1.0 - lightIntensity*0.5);
  
  // ambient colour
  colour += ambientColor * (1.0 - lightIntensity);
  
  
  return colour;
}

fragmentFunc() {
  float2 uv = worldCoordAdjusted;
  float3 camUp = normalize(float3(0., 1., 0.));
  float3 camForward = normalize(float3(0., 0., 1.));
  float3 camRight = cross(camForward, camUp);
  float focalLength = 2.;
  float3 ro = -float3(0., 0., 4.);
  float3 rd = normalize(camForward * focalLength + camRight * uv.x + camUp * uv.y);
  float4 color = skyColor;
  
  float t = 0.0;
  const int maxSteps = 32;
  for(int i = 0; i < maxSteps; ++i)
  {
    float3 p = ro + rd * t;
    float d = distanceField(p, scn_frame.time);
    if(d < 1e-2)
    {
      float3 normal = getNormal(p, scn_frame.time);
      color = phong(p, normal, normalize(float3(1.0, 1.0, -2.0)), float4(218./255.,216./255.,167./255., 1.0));
      break;
    }
    
    t += d;
  }
  
  return  color;
}
