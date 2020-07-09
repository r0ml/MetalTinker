//  Copyright © 1887 Sherlock Holmes. All rights reserved.
//  Found amongst his effects by r0ml

#ifndef constants_h
#define constants_h

constant int numberOfTextures = 6;
constant int numberOfPasses = 6;
constant int numberOfCubes = 3;
constant int numberOfTexts = 10;

namespace global {
  extern constant uint KEY_LEFT;
  extern constant uint KEY_UP;
  extern constant uint KEY_RIGHT;
  extern constant uint KEY_DOWN;
  extern constant float e;
  extern constant float tau;
  extern constant float pi;
  extern constant float epsilon;
  extern constant float goldenRatio;
  extern constant float PI;
  extern constant float TAU;
  extern constant float E;
  extern constant float phi;
  extern constant float PHI;
}

namespace asset {
  constant char amelia_earhart[] = "amelia earhart.m4v";
  constant char dancing[] = "dancing.m4v";
  constant char diving[] = "diving.m4v";
  constant char galloping_gertie[] = "galloping gertie.m4v";
  constant char kinetic_art[] = "kinetic art.mp4";
  constant char space_ship[] = "space ship.m4v";
  constant char surfing[] = "surfing.m4v";
}

namespace asset {
  constant char arid_mud[] = "arid_mud";
  constant char beach_sand[] = "beach_sand";
  constant char brick[] = "brick";
  constant char bubbles[] = "bubbles";

  constant char flagstones[] = "flagstones";
  constant char granite[] = "granite";

  constant char lava[] = "lava";
  constant char leaves[] = "leaves";
  constant char lichen[] = "lichen";
  constant char london[] = "london";

  constant char milky_way[] = "milky_way";

  constant char palace[] = "palace";
  constant char pebbles[] = "pebbles";

  constant char rust[] = "rust";
  constant char stars[] = "stars";
  constant char still_life[] = "still_life";
  constant char straw[] = "straw";
  constant char stump[] = "stump";
  constant char water[] = "water";
  constant char wood[] = "wood";
}

namespace asset {
  constant char cathedral_cube[] = "cathedral_cube";
  constant char cave_cube[] = "cave_cube";
  constant char forest_cube[] = "forest_cube";
  constant char piazza_cube[] = "piazza_cube";
}

namespace asset {
  constant char cantate_domino[] = "Cantate Domino.mp3";
  constant char charleston[] = "Charleston.mp3";
  constant char frog_legs[] = "Frog Legs.mp3";
  constant char futuristic[] = "futuristic.mp3";
  constant char mozart_41[] = "Mozart Symphony 41 Finale.mp3";
  constant char mozart_turkish[] = "Mozart Turkish March.mp3";
  constant char soviet[] = "Soviet.mp3";
  constant char squinch[] = "Squinch Machine.mp3";
  constant char surprising_encounter[] = "Surprising Encounter.mp3";
  constant char tchaikovsky_violin_concerto[] = "Tchaikovsky Violin Concerto Finale.mp3";
}

constant float2x2 bayer2 = { 0, 2, 3, 1};
constant float3x3 bayer3 = {0,7,3,6,5,2,4,1,8};
constant float4x4 bayer4 = {0,8,2,10,12,4,14,6,3,11,1,9,15,7,13,5};
constant float bayer8[8][8] = {
  {0, 48, 12, 60 ,3, 51, 15, 63},
  {32, 16, 44, 28, 35, 19, 47, 31},
  {8, 56, 4, 52, 11, 59, 7, 55},
  {40, 24, 36, 20, 43, 27, 39, 23},
  { 2, 50, 14, 62,  1, 49, 13, 61},
  {34, 18, 46, 30, 33, 17, 45, 29},
  {10, 58,  6, 54,  9, 57,  5, 53},
  {42, 26, 38, 22, 41, 25, 37, 21}
};


#endif /* constants_h */
