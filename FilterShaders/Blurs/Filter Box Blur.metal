
#define shaderName filter_box_blur

#include "Common.h" 

struct InputBuffer {
};

initialize() {
}

constant const float RADIUS = 0.03;
constant const int SAMPLES = 20;

fragmentFn(texture2d<float> tex) {
  float3 sum = 0;
  float2 b = textureCoord;

	for (int i = -SAMPLES; i < SAMPLES; i++) {
		for (int j = -SAMPLES; j < SAMPLES; j++) {
      float2 offset = float2(i, j) * (RADIUS/float(SAMPLES));
			sum += tex.sample(iChannel0, b + offset ).xyz / pow(float(SAMPLES) * 2., 2.);
    }
  }
	return float4(sum, 1.0);
}
