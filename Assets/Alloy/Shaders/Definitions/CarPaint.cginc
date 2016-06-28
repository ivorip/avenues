// Alloy Physical Shader Framework
// Copyright 2013-2016 RUST LLC.
// http://www.alloy.rustltd.com/

/////////////////////////////////////////////////////////////////////////////////
/// @file CarPaint.cginc
/// @brief Car Paint surface shader definition.
/////////////////////////////////////////////////////////////////////////////////

#ifndef A_DEFINITIONS_CAR_PAINT_CGINC
#define A_DEFINITIONS_CAR_PAINT_CGINC

#define A_MAIN_TEXTURES_ON
#define A_CAR_PAINT_ON

#include "Assets/Alloy/Shaders/Lighting/Standard.cginc"
#include "Assets/Alloy/Shaders/Models/Standard.cginc"

void aSurface(
    inout ASurface s)
{
    aParallax(s);
    aDissolve(s);
    aMainTextures(s);
    aAo2(s);
    aDetail(s);	
    aTeamColor(s);
    
    aOpacityBlend(s);
    aUpdateNormalData(s);
    aCarPaint(s);

    aNoBlend(s);
    aDecal(s);
    aEmission(s);
    aRim(s);
}

#endif // A_DEFINITIONS_CAR_PAINT_CGINC
