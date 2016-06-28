// Alloy Physical Shader Framework
// Copyright 2013-2016 RUST LLC.
// http://www.alloy.rustltd.com/

/////////////////////////////////////////////////////////////////////////////////
/// @file Oriented.cginc
/// @brief Oriented Blend & Core shader definition.
/////////////////////////////////////////////////////////////////////////////////

#ifndef A_DEFINITIONS_ORIENTED_CGINC
#define A_DEFINITIONS_ORIENTED_CGINC

#define A_ORIENTED_TEXTURES_ON

#include "Assets/Alloy/Shaders/Lighting/Standard.cginc"
#include "Assets/Alloy/Shaders/Models/Standard.cginc"
    
void aSurface(
    inout ASurface s)
{	
    // Set so that world textures blend can control opacity.
    s.opacity = 0.0h;
    
    aOrientedTextures(s);
    aCutout(s); 
    aUpdateViewData(s);
}

#endif // A_DEFINITIONS_ORIENTED_CGINC
