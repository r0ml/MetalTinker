
#define shaderName touch_pressure

#include "Common.h" 

struct InputBuffer {
};

initialize() {
}

constant const int ITERATION = 3;

fragmentFn(texture2d<float> tex) {
	// Inputs
	float touchPressure = (uni.mouseButtons > 0) * (0.6 + 0.4 * cos (uni.iTime * 4.0));
	const float touchRadius = 0.3;
	const float gridRadius = 0.5;
	const float gridResolution = 30.0;
	float4 gridColor = float4 (1.0, 1.0 - touchPressure, 0.0, 1.0);

	// Get the position of this fragment
	float3 frag = float3 (textureCoord * aspectRatio, 0.0);

	// Get the touch information
	float2 touchPosition = uni.iMouse.xy ;
  touchPosition.x = touchPosition.x * uni.iResolution.x / uni.iResolution.y;
  touchPosition.y = 1 - touchPosition.y;

	float touchDistance = length (frag.xy - touchPosition);

	// Raymarching
	float3 ray = normalize (frag - float3 (0.5 * uni.iResolution.x / uni.iResolution.y, 0.5, -10.0));
//  float3 ray = normalize (frag - float3(0, 0, -10) );

	for (int i = 0; i < ITERATION; ++i)
	{
		float deformation = 0.5 + 0.5 * cospi ( min (touchDistance / touchRadius, 1.0));
		frag += (touchPressure * deformation - frag.z) * ray;
		touchDistance = length (frag.xy - touchPosition);
	}

	// Get the color from the texture
	float4 color = tex.sample(iChannel0, float2 (frag.x * uni.iResolution.y / uni.iResolution.x, -frag.y));

	// Add the grid
	float2 gridPosition = smoothstep (0.05, 0.1, abs (fract (frag.xy * gridResolution) - 0.5));
	color = mix (color, gridColor, (1.0 - gridPosition.x * gridPosition.y) * smoothstep (gridRadius * touchPressure, 0.0, touchDistance));

	// Set the fragment color
	return color;
}
