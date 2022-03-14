
#define shaderName magnify_shader

#include "Common.h" 

struct InputBuffer {
    float3 magnification;
    float3 lens_radius;
    float3 border_thickness;
};

initialize() {
  in.magnification = {1.5, 2, 5};
  in.lens_radius = { 0.1, 0.3, 0.5};
  in.border_thickness = {0, 0.01, 0.05};
}

fragmentFn(texture2d<float> tex) {
  //Convert to UV coordinates, accounting for aspect ratio
  float2 uv = textureCoord;
  
  //at the beginning of the sketch, center the magnifying glass.
  //Thanks to FabriceNeyret2 for the suggestion
  float2 mouse = uni.iMouse.xy ;

  uv *= aspectRatio;
  mouse *= aspectRatio;


  //UV coordinates of mouse
//  float2 mouse_uv = mouse / uni.iResolution.y;
  
  //Distance to mouse
  float mouse_dist = distance(uv, mouse);
  
  //Draw the texture
  float4 fragColor = tex.sample(iChannel0, uv);
  
  //Draw the outline of the glass
  if (mouse_dist < in.lens_radius.y + in.border_thickness.y) {
    fragColor = float4(0.1, 0.1, 0.1, 1.0);
  }
  
  //Draw a zoomed-in version of the texture
  if (mouse_dist < in.lens_radius.y) {
    fragColor = tex.sample(iChannel0, mouse + (uv - mouse) / in.magnification.y);
  }
  return fragColor;
}
