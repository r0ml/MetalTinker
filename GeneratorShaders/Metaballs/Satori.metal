
#define shaderName Satori

#include "Common.h"

static float2 center ( float2 border , float2 offset , float2 vel, float2 mouse, float time ) {
  float2 c;
  if ( vel.x == 0.0 && vel.y == 0.0 ) {
    c = mouse;
  }
  else {
    c = offset + vel * time * 0.5;
    c = mod ( c , 2. - 4. * border );
    if ( c.x > 1. - border.x ) c.x = 2. - c.x - 2. * border.x;
    if ( c.x < border.x ) c.x = 2. * border.x - c.x;
    if ( c.y > 1. - border.y ) c.y = 2. - c.y - 2. * border.y;
    if ( c.y < border.y ) c.y = 2. * border.y - c.y;
  }
  return c;
}

static void circle ( float r , float3 col , float2 offset , float2 vel, float2 coord, float2 aspect, thread float& field, float k, float2 mouse, float time ) {
  float2 pos = coord;
  float2 c = aspect * center (  r / aspect , offset , vel, mouse, time );

  float d = distance ( pos , c );
  field += ( k * r ) / ( d*d );
}

static float3 band ( float shade, float low, float high, float3 col1, float3 col2 ) {
  
  if ( (shade >= low) && (shade <= high) ) {
    float delta = (shade - low) / (high - low);
    float3 colDiff = col2 - col1;
    return col1 + (delta * colDiff);
  }
  else
    return float3(0.0,0.0,0.0);
}

static float3 gradient ( float shade , float time, float2 mouse) {
  float3 colour = float3( (sin(time/2.0)*0.25)+0.25,0.0,(cos(time/2.0)*0.25)+0.25);
  
  float2 mouseScaled = mouse;
  float3 col1 = float3(mouseScaled.x, 0.0, 1.0-mouseScaled.x);
  float3 col2 = float3(1.0-mouseScaled.x, 0.0, mouseScaled.x);
  float3 col3 = float3(mouseScaled.y, 1.0-mouseScaled.y, mouseScaled.y);
  float3 col4 = float3((mouseScaled.x+mouseScaled.y)/2.0, (mouseScaled.x+mouseScaled.y)/2.0, 1.0 - (mouseScaled.x+mouseScaled.y)/2.0);
  float3 col5 = float3(mouseScaled.y, mouseScaled.y, mouseScaled.y);
  
  colour += band ( shade, 0.0, 0.3, colour, col1 );
  colour += band ( shade, 0.3, 0.6, col1, col2 );
  colour += band ( shade, 0.6, 0.8, col2, col3 );
  colour += band ( shade, 0.8, 0.9, col3, col4 );
  colour += band ( shade, 0.9, 1.0, col4, col5 );
  
  return colour;
}

fragmentFunc(constant float2& mouse) {
  
  float k = 20.0;
  float field = 0.0;
  float t = scn_frame.time;
  float2 aspect = nodeAspect;

  float2 coord = textureCoord;
  
  circle ( .03 , float3 ( 0.7 , 0.2 , 0.8 ) , float2 ( .6 ) , float2 ( .30 , .70 ), coord, aspect, field, k, mouse, t );
  circle ( .05 , float3 ( 0.7 , 0.9 , 0.6 ) , float2 ( .1 ) , float2 ( .02 , .20 ), coord, aspect, field, k, mouse, t );
  circle ( .07 , float3 ( 0.3 , 0.4 , 0.1 ) , float2 ( .1 ) , float2 ( .10 , .04 ), coord, aspect, field, k, mouse, t );
  circle ( .10 , float3 ( 0.2 , 0.5 , 0.1 ) , float2 ( .3 ) , float2 ( .10 , .20 ), coord, aspect, field, k, mouse, t );
  circle ( .20 , float3 ( 0.1 , 0.3 , 0.7 ) , float2 ( .2 ) , float2 ( .40 , .25 ), coord, aspect, field, k, mouse, t );
  circle ( .30 , float3 ( 0.9 , 0.4 , 0.2 ) , float2 ( .0 ) , float2 ( .15 , .20 ), coord, aspect, field, k, mouse, t );
  circle ( .30 , float3 ( 0.0 , 0.0 , 0.0 ) , float2 ( .0 ),  float2 (  0.0, 0.0 ), coord, aspect, field, k, mouse, t );
  
  float shade = min ( 1.0, max ( field/256.0, 0.0 ) );
  
  return float4( gradient(shade, scn_frame.time, mouse), 1.0 );
}
