
#define shaderName basic_conway_game_of_life

#include "Common.h" 

#define pixel (1.0 / uni.iResolution.xy)
#define brushSize 20.0

// process keyboard input
static bool ReadKey( uint2 k, uint key )//, bool toggle )
{
  // bool toggle = false;
  return k.x == key;
}

fragmentFn(texture2d<float> lastFrame) {

  // retrieve the texture coordinate
  float2 c = thisVertex.where.xy / uni.iResolution.xy;
  // and the current pixel
  float3 current = lastFrame.sample(iChannel0, c).rgb;
  // set the neighbours value to 0
  float3 neighbours = float3(0.0);
  
  // check to seee if we are at the start of the timeline or if the R key is pressed.
  if(uni.iTime > 0.1 && !ReadKey( uni.keyPress, 'r'))
  {
    // draw a circle if the mouse is clicked
    if(distance(uni.iMouse.xy * uni.iResolution, thisVertex.where.xy) < brushSize && uni.wasMouseButtons)
    {
      return float4(1.);
    }
    else
    {
      // count the neightbouring pixels with a value greater than zero
      neighbours += float3( (lastFrame.sample(iChannel0, c + pixel*float2(-1,-1)).rgb > float3(0.0)));
      neighbours += float3( (lastFrame.sample(iChannel0, c + pixel*float2(-1, 0)).rgb > float3(0.0)));
      neighbours += float3( (lastFrame.sample(iChannel0, c + pixel*float2(-1, 1)).rgb > float3(0.0)));
      neighbours += float3( (lastFrame.sample(iChannel0, c + pixel*float2( 0,-1)).rgb > float3(0.0)));
      neighbours += float3( (lastFrame.sample(iChannel0, c + pixel*float2( 0, 1)).rgb > float3(0.0)));
      neighbours += float3( (lastFrame.sample(iChannel0, c + pixel*float2( 1,-1)).rgb > float3(0.0)));
      neighbours += float3( (lastFrame.sample(iChannel0, c + pixel*float2( 1, 0)).rgb > float3(0.0)));
      neighbours += float3( (lastFrame.sample(iChannel0, c + pixel*float2( 1, 1)).rgb > float3(0.0)));
      
      // check if the current pixel is alive
      float3 live = float3( (current > float3(0.0)));
      
      // resurect if we are not live, and have 3 live neighrbours
      current += (1.0-live) * float3( (neighbours == float3(3.0)));
      
      // kill if we do not have either 3 or 2 neighbours
      current *= float3( (neighbours ==  float3(2.0))) + float3( (neighbours == float3(3.0)));
      
      // fade the current pixel as it ages
      current -= float3( (current >  float3(0.4)))*0.05;
      
      // write out the pixel
      return float4(current, 1.0);
    }
  }
  //Generate some noise to get things going
  else
  {
    return float4(rand(thisVertex.where.xy) > 0.8 ? 1.0 : 0.0);
  }
  return 0;
}
