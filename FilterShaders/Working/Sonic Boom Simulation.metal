/** 
Author: tehsauce
Waves propagating through a 2D grid
Trying to make the edges act as if they continued infinitely, so waves do not reflect off, but simply are dissipated and disappear.
Anyone have an idea how to do this?
*/

#define shaderName sonic_boom_simulation

#include "Common.h" 

struct InputBuffer {
  string textures[1];
};

initialize() {
    setTex(0, asset::london);
}

 


fragmentFn1() {
  FragmentOutput fff;
    float4 color = float4( renderInput[0].sample( iChannel0, thisVertex.where.xy / uni.iResolution.xy ) );
	fff.fragColor = float4( color.x, color.b, -color.x, 1.0 );

 // ============================================== buffers ============================= 

    // Get normalized pixel coordinates
    float2 uv = -1.0 + 2.0 * thisVertex.where.xy / uni.iResolution.xy;
	uv.x *= uni.iResolution.x / uni.iResolution.y; 
    
    // Store time with shorter name
    float t = uni.iTime;
  //  float t2 = uni.iTime * uni.iTime;
      
    // Pixel color
    float4 col = float4(0.0);
    
    // First 5 frames or when "space" is pressed buffer set to initial conditions
	if ( uni.iFrame < 5 || uni.keyPress.x == ' ') {
     // Load texture as initial state
     //	col = float4( 2.0*texture( iChannel1,  thisVertex.where.xy / uni.iResolution.xy ).r - 1.0, 0.0, 0.0, 1.0);
     
     // Blank initial state 
        col = float4( 0.0, 0.0, 0.0, 1.0 );
    } else {
        
        // Get current tile value
    	col = renderInput[0].sample( iChannel0, thisVertex.where.xy / uni.iResolution.xy );
        
        // Get adjacent tile values
        float4 l = float4( renderInput[0].sample( iChannel0, ( thisVertex.where.xy + float2( -1.0,  0.0 ) ) / uni.iResolution.xy ) );
        float4 r = float4( renderInput[0].sample( iChannel0, ( thisVertex.where.xy + float2(  1.0,  0.0 ) ) / uni.iResolution.xy ) );
        float4 u = float4( renderInput[0].sample( iChannel0, ( thisVertex.where.xy + float2(  0.0,  1.0 ) ) / uni.iResolution.xy ) );
        float4 d = float4( renderInput[0].sample( iChannel0, ( thisVertex.where.xy + float2(  0.0, -1.0 ) ) / uni.iResolution.xy ) );
        
        // Get diagonal tile values
        float4 ul = float4( renderInput[0].sample( iChannel0, ( thisVertex.where.xy + float2( -1.0,  1.0 ) ) / uni.iResolution.xy ) );
        float4 ur = float4( renderInput[0].sample( iChannel0, ( thisVertex.where.xy + float2(  1.0,  1.0 ) ) / uni.iResolution.xy ) );
        float4 ll = float4( renderInput[0].sample( iChannel0, ( thisVertex.where.xy + float2( -1.0, -1.0 ) ) / uni.iResolution.xy ) );
        float4 lr = float4( renderInput[0].sample( iChannel0, ( thisVertex.where.xy + float2(  1.0, -1.0 ) ) / uni.iResolution.xy ) );
        
        // Tile data stored in pixel with following components:
        //
        // x - stores tile displacement
        // y - stores tiles velocity
        // z - absolute value of displacement ( for visualization )
        
        
        // Calculate weighted average displacement of neighbors using the kernel 
        //		| 1/12 | 1/6 | 1/12 |
		//		| 1/6  |  0  | 1/6  |
		//		| 1/12 | 1/6 | 1/12 |
        
        float avg = ( l.x + r.x + u.x + d.x + 0.5 * ( ul.x + ur.x + ll.x + lr.x ) ) / 6.0;
        
        // Calculate tiles difference from neighbors
        float force = avg - col.x;
        
        // Determine if tile is near edge
        float off = max(thisVertex.where.x + 50.0 - uni.iResolution.x, 0.0) + max(thisVertex.where.y + 50.0 - uni.iResolution.y, 0.0) + max( 50.0 - thisVertex.where.x, 0.0) + max( 50.0 - thisVertex.where.y, 0.0);
        if ( off > 0.0 ) {
            // Tiles near edge react less
        	force *= 1.0 / off;   
        }
        
        // Create periodic displacement at mouse clicks
        if ( uni.mouseButtons ) {       
        	col.x += 0.4*sin(t * 4.0) / ( 1.0 + pow( distance( thisVertex.where.xy, uni.iMouse.xy * uni.iResolution ), 1.0 ) ); 
        }
        
        // Update velocity
        col.y += force * 0.12;
        // Update position
        col.x += col.y;
        // Sort of measuring acceleration * amplitude
        col.z = 3.0 * abs( col.x * force );
        
        // Sonic Boom
        col.x += 2.2*sin(t * 3.0) / ( 1.0 + pow( distance( thisVertex.where.xy, float2( 0.4*t*t +100.0, uni.iResolution.y*0.5) ), 2.0 ) ); 
      
        
        // Circle
        // col += float4( sin(t * 16.0), 0.0, 0.0, 0.0 ) / ( 1.0 + 500.0 * distance( uv, 0.8 * float2( cos( t ), sin( t ) ) )  );  
        
      	// Some strange amplitude limiting attempts   
        
        // col = clamp( col, 0.0, 10.5 );
        // if ( any(  ( col > float4( 1.0 ) ) ) ) {
        	// col /= 2.0;   
       	// }
    }
    
    fff.pass1 = col;

  return fff;
}
