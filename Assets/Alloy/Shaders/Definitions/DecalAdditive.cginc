// Alloy Physical Shader Framework
// Copyright 2013-2016 RUST LLC.
// http://www.alloy.rustltd.com/

/////////////////////////////////////////////////////////////////////////////////
/// @file Multiplicative.cginc
/// @brief Multiplicative deferred decal surface shader definition.
/////////////////////////////////////////////////////////////////////////////////

#ifndef A_DEFINITIONS_DECAL_ADDITIVE_CGINC
#define A_DEFINITIONS_DECAL_ADDITIVE_CGINC

#define A_DETAIL_MATERIAL_MAP_OFF

#include "Assets/Alloy/Shaders/Lighting/Unlit.cginc"
#include "Assets/Alloy/Shaders/Models/DecalAdditive.cginc"

void aSurface(
    inout ASurface s)
{
    aParallax(s);
    aDissolve(s);

    s.baseColor = aBaseColor(s).rgb;
    s.normalTangent = aSampleBump(s);

    aDetail(s);
    aTeamColor(s);
    aDecal(s);
    aUpdateNormalData(s);
    aRim(s);
    aEmission(s);

    s.emission += s.baseColor;
}

#endif // A_DEFINITIONS_DECAL_ADDITIVE_CGINC
