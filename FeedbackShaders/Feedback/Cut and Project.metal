/// Idea form this paper https://arxiv.org/pdf/math-ph/0603065.pdf

#define shaderName Cut_and_Project

#include "Common.h"

struct InputBuffer {
  bool fourD = 0;
  float3 inverse_dot_intensity;
  float3 screen_scale;
};

initialize() {
  in.inverse_dot_intensity = { 10, 50, 100}; //make this smaller for bigger dots
  in.screen_scale = {1, 5, 10}; //make this larger to make the screen encompass more space
}
/*
 Given a basis for a vector space, a lattice in that space generated by the basis is the set of all
 integral linear combinations of those vectors. Lattices that are invariant under discrete subgroups
 of translations can be used as mathematical models for crystals. Quasicrystals are aperiodics sets
 of points with discrete rotational symmetry. Quasicrystals can be modeled as cut & project sets,
 where you take two subspaces of your vector space whose direct product is the whole space, project
 the lattice onto one of the subspaces, determine whether or not it falls into a subset of the space
 called the "acceptance window", if it does project it onto the other subspace and that's a part of
 your C&P set. Unfortuantely, I couldn't figure out what kind of lattices/acceptance windows give
 quasicrystals, so I decided to just publish this for people to play with. The shader can do 3 and
 4 dimensional lattices, uncomment line 14 and re-initialize to see the 4D version.
 */


//3D basis vectors
// constant const float3 b0 = float3(0.5, 0.5 / isqrt3, 0);
// constant const float3 b1 = float3(-0.5, 0.5 / isqrt3, 0);
// constant const float3 b2 = float3(0, -0.5 / isqrt3, .5);
//4D basis vectors
constant const float4 c0 = float4(1, 0, 0, 0);
constant const float4 c1 = float4(0.5);
constant const float4 c2 = float4(0, 1, 0, 0);

//go from integer coefficients to position in the lattice
static float3 calcPos3(int3 n){
  float3 v = float3(n);

  float isqrt3 = inversesqrt(3.0);
  const float3 b0 = float3(0.5, 0.5 / isqrt3, 0);
  const float3 b1 = float3(-0.5, 0.5 / isqrt3, 0);
  const float3 b2 = float3(0, -0.5 / isqrt3, .5);

  return v.x * b0 + v.y * b1 + v.z * b2;
}

static float4 calcPos4(int4 n){
  float4 v = float4(n);

  const float4 c3 = float4(0, 0.5, 0.5 / phi, -0.5 * phi);

  return v.x * c0 + v.y * c1 + v.z * c2 + v.w * c3;
}

static float firstProjection3(float3 v){
  return v.z;
}

static float2 firstProjection4(float4 v){
  return float2(dot(normalize(float4(0.5, 1.3, 8.6, -7.1)), v),
                dot(normalize(float4(-3.9, 7.668, 3.051, -7.8)), v));
  return v.zw;
}

static float2 secondProjection3(float3 v){
  return v.xy;
}

static float2 secondProjection4(float4 v){
  return float2(dot(normalize(float4(-31.8, 36.4, 47.1, 88.89)), v),
                dot(normalize(float4(90, 7.1, -9, -2)), v));
}

static bool fitsAcceptanceWindow3(float3 v){
  float projectedVector = firstProjection3(v);
  bool result = abs(projectedVector) < 1.0;
  return result;
}

static bool fitsAcceptanceWindow4(float4 v){
  float2 projectedVector = firstProjection4(v);
  bool result = length(projectedVector) < 4.0;
  return result;
}

//the functions below are for generating a tuple of integers from a single one in a way that covers
//the entire lattice.

//rodolphito came up with the 3D version and I generalized it to 4D
static int condense3(int level0){

  //three ones, six zeroes, three ones, six zeroes, etc.
  int three = 941362695;
  //six ones, twelve zeroes, etc.
  int six = 16515135;
  //twelve ones
  int twelve = 4095;

  //group all bits into groups of three with 6 unnecessary bits between them,
  //extract them by 'and'ing with three
  int level1 = three & (
                        (level0 >> 0) |
                        (level0 >> 2) |
                        (level0 >> 4)
                        );

  //put groups of three together to make groups of 6
  int level2 = six & (
                      (level1 >> 0) |
                      (level1 >> 6)
                      );

  //put two groups of 6 together
  int level3 = twelve & (
                         (level2 >> 0) |
                         (level2 >> 8)
                         );

  int sgn = ((level3 & 1) << 1) - 1;

  return sgn * level3 >> 1;
}

static int3 getLatticePos3(int t){
  //one, two zeroes, one, two zeroes, etc
  int helper = 1227133513;

  //the first digit in every triple of digits will be in x, the second in y, etc.
  int x0 = (t >> 0) & helper;
  int y0 = (t >> 1) & helper;
  int z0 = (t >> 2) & helper;

  //get rid of unnecessary bits
  int x = condense3(x0);
  int y = condense3(y0);
  int z = condense3(z0);

  return int3(x, y, z);
}

static int condense4(int level0){
  //four ones, eight zeroes, four ones
  int four = 218165519;
  //eight ones, 16 zeroes, eight ones
  int eight = 0xF00F; // 4278190335;
                      //sixteen ones
  int sixteen = 65535;

  int level1 = four & (
                       (level0 >> 0) |
                       (level0 >> 3) |
                       (level0 >> 6) );

  int level2 = eight & (
                        (level1 >> 0) |
                        (level1 >> 12) );

  int level3 = sixteen & (
                          (level2 >> 0) |
                          (level2 >> 15));

  int sgn = ((level3 & 1) << 1) - 1;

  return sgn * level3 >> 1;
}

static int4 getLatticePos4(int t){
  int helper = 286331153;

  int x0 = (t >> 0) & helper;
  int y0 = (t >> 1) & helper;
  int z0 = (t >> 2) & helper;
  int w0 = (t >> 3) & helper;

  int x = condense4(x0);
  int y = condense4(y0);
  int z = condense4(z0);
  int w = condense4(w0);

  return int4(x, y, z, w);
}


fragmentFn(texture2d<float> lastFrame) {

  float2 uv = thisVertex.where.xy / uni.iResolution.xy;
  float2 xy = (2.0 * thisVertex.where.xy - uni.iResolution.xy) / uni.iResolution.y;
  xy *= in.screen_scale.y;

  float4 fragColor = lastFrame.sample(iChannel0, uv);

  if(uni.iFrame > 30){
    if (in.fourD) {
      int4 coords = getLatticePos4(uni.iFrame - 30);
      float4 v = calcPos4(coords);
      if(fitsAcceptanceWindow4(v)){
        float2 p = secondProjection4(v);
        float d = distance(p, xy);
        fragColor += exp(-in.inverse_dot_intensity.y * d)
        * (.5 + .5 * sin(v));
      }
    } else {
      int3 coords = getLatticePos3(uni.iFrame - 30);
      float3 v = calcPos3(coords);
      if(fitsAcceptanceWindow3(v)){
        float2 p = secondProjection3(v);
        float d = distance(p, xy);
        fragColor.xyz += exp(-in.inverse_dot_intensity.y * d) * (.5 + .5 * sin(v));
      }
    }
  }
  fragColor.w = 1;
  return fragColor;
}