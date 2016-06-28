// Alloy Physical Shader Framework
// Copyright 2013-2016 RUST LLC.
// http://www.alloy.rustltd.com/

/////////////////////////////////////////////////////////////////////////////////
/// @file Alpha.cginc
/// @brief Alpha deferred decal surface shader definition.
/////////////////////////////////////////////////////////////////////////////////

#ifndef A_DEFINITIONS_DECAL_ALPHA_CGINC
#define A_DEFINITIONS_DECAL_ALPHA_CGINC

#define A_MAIN_TEXTURES_ON

#include "Assets/Alloy/Shaders/Lighting/Standard.cginc"
#include "Assets/Alloy/Shaders/Models/DecalAlpha.cginc"

void aSurface(
    inout ASurface s)
{
    aParallax(s);
    aDissolve(s);
    aMainTextures(s);
    aAo2(s);
    aDetail(s);
    aTeamColor(s);
    aDecal(s);
    aUpdateNormalData(s);
    aRim(s);
    aEmission(s);
}

#endif // A_DEFINITIONS_DECAL_ALPHA_CGINC
