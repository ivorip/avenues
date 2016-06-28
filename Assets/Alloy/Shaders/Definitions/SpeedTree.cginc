// Alloy Physical Shader Framework
// Copyright 2013-2016 RUST LLC.
// http://www.alloy.rustltd.com/

/////////////////////////////////////////////////////////////////////////////////
/// @file SpeedTree.cginc
/// @brief SpeedTree surface shader definition.
/////////////////////////////////////////////////////////////////////////////////

#ifndef A_DEFINITIONS_SPEED_TREE_CGINC
#define A_DEFINITIONS_SPEED_TREE_CGINC

#define A_SPECULAR_TINT_ON

#if defined(GEOM_TYPE_FROND) || defined(GEOM_TYPE_LEAF) || defined(GEOM_TYPE_FACING_LEAF)
    #define _ALPHATEST_ON
    #define A_TWO_SIDED_ON
    //#include "Assets/Alloy/Shaders/Lighting/Transmission.cginc"
    #include "Assets/Alloy/Shaders/Lighting/Standard.cginc"
#else
    #include "Assets/Alloy/Shaders/Lighting/Standard.cginc"
#endif

#include "Assets/Alloy/Shaders/Models/SpeedTree.cginc"

#if defined(GEOM_TYPE_FROND) || defined(GEOM_TYPE_LEAF) || defined(GEOM_TYPE_FACING_LEAF)
    /// Transmission color * thickness texture.
    /// Expects an RGB map with sRGB sampling.
    sampler2D _TransTex;

    /// Weight of the transmission effect.
    /// Expects linear-space values in the range [0,1].
    half _TransScale;
#endif

void aSurface(
    inout ASurface s)
{
    aParallax(s);
    aDissolve(s);
    aSpeedTree(s);
    s.specularity = _Specularity;
    s.specularTint = _SpecularTint;
    s.roughness = _Roughness;

    aTeamColor(s);
    aDecal(s);

#if defined(GEOM_TYPE_FROND) || defined(GEOM_TYPE_LEAF) || defined(GEOM_TYPE_FACING_LEAF)
    s.transmission = LinearToGammaSpace(_TransScale.rrr).r * tex2D(_TransTex, s.baseUv).a;
#endif
#ifdef EFFECT_BUMP
    aUpdateNormalData(s);
#endif
    aRim(s);
    aEmission(s);
}

#endif // A_DEFINITIONS_SPEED_TREE_CGINC
