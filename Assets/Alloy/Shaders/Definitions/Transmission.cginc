// Alloy Physical Shader Framework
// Copyright 2013-2016 RUST LLC.
// http://www.alloy.rustltd.com/

/////////////////////////////////////////////////////////////////////////////////
/// @file Transmission.cginc
/// @brief Transmission surface shader definition.
/////////////////////////////////////////////////////////////////////////////////

#ifndef A_DEFINITIONS_TRANSMISSION_CGINC
#define A_DEFINITIONS_TRANSMISSION_CGINC

#define A_MAIN_TEXTURES_ON

#include "Assets/Alloy/Shaders/Lighting/Transmission.cginc"
#include "Assets/Alloy/Shaders/Models/Standard.cginc"

/// Transmission tint color.
/// Expects a linear LDR color.
half3 _TransColor;

/// Transmission color * thickness texture.
/// Expects an RGB map with sRGB sampling.
sampler2D _TransTex;

/// Weight of the transmission effect.
/// Expects linear-space values in the range [0,1].
half _TransScale;

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

    aSetTransmission(s, _TransColor, _TransScale * tex2D(_TransTex, s.baseUv).rgb);
    aTwoSided(s);
    aUpdateNormalData(s);
    aRim(s);
    aEmission(s);
}

#endif // A_DEFINITIONS_TRANSMISSION_CGINC
