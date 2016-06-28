// Alloy Physical Shader Framework
// Copyright 2013-2016 RUST LLC.
// http://www.alloy.rustltd.com/

/////////////////////////////////////////////////////////////////////////////////
/// @file Emission2.cginc
/// @brief Secondary emission effects.
/////////////////////////////////////////////////////////////////////////////////

#ifndef A_FEATURES_EMISSION2_CGINC
#define A_FEATURES_EMISSION2_CGINC

#include "Assets/Alloy/Shaders/Framework/Feature.cginc"

#ifdef _EMISSION2_ON
    /// Secondary emission tint color.
    /// Expects a linear LDR color.
    half3 _Emission2Color;
    
    #ifndef A_EMISSION2_COLOR_MAP_OFF
        //// Secondary emission mask texture.
        /// Expects an RGB map with sRGB sampling.
        sampler2D _EmissionMap2;
    #endif

    #ifndef A_EMISSION2_EFFECTS_MAP_OFF
        /// Secondary emission effect texture.
        /// Expects an RGB map with sRGB sampling.
        A_SAMPLER2D(_IncandescenceMap2);
    #endif
    
    /// The weight of the secondary emission effect.
    /// Expects linear space value in the range [0,1].
    half _Emission2Weight;
#endif

/// Applies the Emission feature to the given material data.
/// @param[in,out] s Material surface data.
void aEmission2(
    inout ASurface s)
{
#ifdef _EMISSION2_ON
    half3 emission = _Emission2Color;

    #ifndef A_EMISSION2_COLOR_MAP_OFF
        emission *= tex2D(_EmissionMap2, s.baseUv).rgb; 
    #endif

    #ifndef A_EMISSION2_EFFECTS_MAP_OFF
        float2 incandescenceUv2 = A_TRANSFORM_UV_SCROLL(s, _IncandescenceMap2);
        emission *= tex2D(_IncandescenceMap2, incandescenceUv2).rgb;
    #endif
    
    s.emission += _Emission2Weight * (emission * GammaToLinearSpace(s.mask.rrr));
#endif
} 

#endif // A_FEATURES_EMISSION2_CGINC
