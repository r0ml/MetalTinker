
#define shaderName solar_system

#include "Common.h" 

static float4 C( float2 U, float D, float d, float e, float a, float T, float r, int iR,int iG,int iB, float time, float2 reso ) {
  float Rx = (D+d)/2.;               // major radius
  float t = TAU*time/T/2.;
  a = radians(a);
  r = .03*r;                                 // click: sizes
  float2   A = float2( 1, sqrt(1.-e*e) ),  // A*Rx = major and minor radius
  C = float2( (D-d)/2., 0 );      // ellipse center
  return .15*smoothstep( 3*40./reso.y, 0, abs( length( ( rot2d(-a) * U - C ) / A ) - Rx) )               // orbit
  + smoothstep( 3*40./reso.y, 0, abs(length( rot2d(a)*( float2(cos(t),sin(t))*Rx*A + C ) - U)) - r)  // planet
  * float4(iR,iG,iB,0)/255.;
}

fragmentFunc() {
  float2 R = scn_frame.viewportSize.xy; // float2(1000, 1000);
  float t = scn_frame.time;
  float2 U = worldCoordAdjusted * 40.; U.y -= 7.;
  float4 fragColor = 0;
  //             perihelion,   ascending+arg_p,       radius,
  //        aphelion, | eccentricity, |       period,   |      color
  //          (UA)   (UA)   (1)   (degrees)    (years)(k.km) (iR,iG,iB)
  fragColor += C( U,  0.47,  0.31, .206,  48.3+ 29.1,   0.241, 2.4, 142,140,141, t, R); // Mercury
  fragColor += C( U,  0.73,  0.72, .007,  76.7+ 54.9,   0.62,  6.1, 244,243,240, t, R); // Venus
  fragColor += C( U,  1.02,  0.98, .017, -11.3+114.2,   1.,    6.4, 153,182,232, t, R); // Earth
  fragColor += C( U,  1.67,  1.38, .093,  49.6+286.5,   1.88,  3.4, 232,123, 85, t, R); // Mars
  fragColor += C( U,  5.46,  4.95, .049, 100.5+273.9,  11.86, 69.9, 203,162,134, t, R); // Jupiter
  fragColor += C( U, 10.12,  9.04, .057, 113.7+339.4,  29.4,  58.2, 154,146,110, t, R); // Saturn
  fragColor += C( U, 20.11, 18.33, .046,  74.0+ 97.0,  84.0,  25.4, 164,196,214, t, R); // Uranus
  fragColor += C( U, 30.33, 29.81, .010, 131.8+276.3, 164.8,  24.6,  99,175,251, t, R); // Neptune
  fragColor += C( U, 49.31, 29.66, .249, 110.3+113.8, 248.0,   1.2, 203,167,133, t, R); // Pluto
                                                                                                               // Sun rad: 696
  fragColor.w = 1;
  return fragColor;
}
