// Alloy Physical Shader Framework
// Copyright 2013-2016 RUST LLC.
// http://www.alloy.rustltd.com/

/////////////////////////////////////////////////////////////////////////////////
/// @file Skin.cginc
/// @brief Skin surface shader definition.
/////////////////////////////////////////////////////////////////////////////////

#ifndef A_DEFINITIONS_SKIN_CGINC
#define A_DEFINITIONS_SKIN_CGINC

#define A_MAIN_TEXTURES_ON
#define A_MAIN_TEXTURES_CUTOUT_OFF
#define A_DETAIL_FALLOFF_ON

#include "Assets/Alloy/Shaders/Lighting/Skin.cginc"
#include "Assets/Alloy/Shaders/Models/Standard.cginc"

void aSurface(
    inout ASurface s)
{
    aDissolve(s);
    aMainTextures(s);

    s.transmission = s.opacity;
    s.blurredNormalTangent = aSampleBumpBias(s, A_SKIN_BUMP_BLUR_BIAS);
    
    aDetail(s);
    aTeamColor(s);
    aDecal(s);
    aUpdateNormalData(s);	
    aRim(s);
    aEmission(s);
}

#endif // A_DEFINITIONS_SKIN_CGINC
