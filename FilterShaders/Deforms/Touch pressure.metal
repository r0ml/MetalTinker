
#define shaderName touch_pressure

#include "Common.h" 

constant const int ITERATION = 3;

fragmentFunc(texture2d<float> tex, constant float2& mouse) {
	// Inputs
	float touchPressure = // (uni.mouseButtons > 0) *
  (0.6 + 0.4 * cos ( scn_frame.time * 4.0));
	const float touchRadius = 0.3;
	const float gridRadius = 0.5;
	const float gridResolution = 30.0;
	float4 gridColor = float4 (1.0, 1.0 - touchPressure, 0.0, 1.0);

	// Get the position of this fragment
	float3 frag = float3 (textureCoord * nodeAspect, 0.0);

	// Get the touch information
	float2 touchPosition = mouse ;
  touchPosition.x = touchPosition.x * nodeAspect.x;
//  touchPosition.y = 1 - touchPosition.y;

	float touchDistance = length (frag.xy - touchPosition);

	// Raymarching
	float3 ray = normalize (frag - float3 (0.5 * nodeAspect.y, 0.5, -10.0));
//  float3 ray = normalize (frag - float3(0, 0, -10) );

	for (int i = 0; i < ITERATION; ++i)
	{
		float deformation = 0.5 + 0.5 * cospi ( min (touchDistance / touchRadius, 1.0));
		frag += (touchPressure * deformation - frag.z) * ray;
		touchDistance = length (frag.xy - touchPosition);
	}

	// Get the color from the texture
	float4 color = tex.sample(iChannel0, frag.xy / nodeAspect);

	// Add the grid
	float2 gridPosition = smoothstep (0.05, 0.1, abs (fract (frag.xy * gridResolution) - 0.5));
	color = mix (color, gridColor, (1.0 - gridPosition.x * gridPosition.y) * smoothstep (gridRadius * touchPressure, 0.0, touchDistance));

	// Set the fragment color
	return color;
}
