// Alloy Physical Shader Framework
// Copyright 2013-2016 RUST LLC.
// http://www.alloy.rustltd.com/

/////////////////////////////////////////////////////////////////////////////////
/// @file Multiplicative.cginc
/// @brief Multiplicative deferred decal surface shader definition.
/////////////////////////////////////////////////////////////////////////////////

#ifndef A_DEFINITIONS_DECAL_MULTIPLICATIVE_CGINC
#define A_DEFINITIONS_DECAL_MULTIPLICATIVE_CGINC

#include "Assets/Alloy/Shaders/Lighting/Unlit.cginc"
#include "Assets/Alloy/Shaders/Models/DecalMultiplicative.cginc"

void aSurface(
    inout ASurface s)
{
    half4 base = aBaseColor(s);

    s.baseColor = aLerpWhiteTo(base.rgb, base.a);
    aTeamColor(s);
}

#endif // A_DEFINITIONS_DECAL_MULTIPLICATIVE_CGINC
