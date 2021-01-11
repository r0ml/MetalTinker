// Copyright (c) 1868 Charles Babbage
// Found amongst his effects by r0ml

#ifndef shapes_h
#define shapes_h

using namespace metal;

#include <metal_stdlib>
#include "constants.h"

// returns the canonical co-ords for the vertex (at location .xy)
// returns the rotation of the point in radians (at location .z)
float2 polygon(uint vid, uint sides, float radius);
float2 annulus(uint vid, uint sides, float inner, float outer, float startAngle = 0, float endAngle = TAU);

// ============================================

#endif /* shapes_h */
