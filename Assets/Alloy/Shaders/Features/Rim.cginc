// Alloy Physical Shader Framework
// Copyright 2013-2016 RUST LLC.
// http://www.alloy.rustltd.com/

/////////////////////////////////////////////////////////////////////////////////
/// @file Rim.cginc
/// @brief Rim lighting effects.
/////////////////////////////////////////////////////////////////////////////////

#ifndef A_FEATURES_RIM_CGINC
#define A_FEATURES_RIM_CGINC

#include "Assets/Alloy/Shaders/Framework/Feature.cginc"

#ifdef _RIM_ON
    /// Rim lighting tint color.
    /// Expects a linear HDR color.
    half3 _RimColor;

    #ifndef A_RIM_EFFECTS_MAP_OFF
        /// Rim effect texture.
        /// Expects an RGB map with sRGB sampling.
        A_SAMPLER2D(_RimTex);
    #endif
    
    /// The weight of the rim lighting effect.
    /// Expects linear space value in the range [0,1].
    half _RimWeight;
    
    /// Fills in the center of the rim lighting effect.
    /// Expects linear-space values in the range [0,1].
    half _RimBias;
    
    /// Controls the falloff of the rim lighting effect.
    /// Expects values in the range [0.01,n].
    half _RimPower;
#endif

/// Applies the Rim Lighting feature to the given material data.
/// @param[in,out] s Material surface data.
void aRim(
    inout ASurface s)
{	
#ifdef _RIM_ON 
    half3 rim = _RimColor;

    #ifndef A_RIM_EFFECTS_MAP_OFF
        float2 rimUv = A_TRANSFORM_UV_SCROLL(s, _RimTex);
        rim *= tex2D(_RimTex, rimUv).rgb;
    #endif
    
    s.emission += (rim * GammaToLinearSpace(s.mask.rrr)) * (_RimWeight * aRimLight(_RimBias, _RimPower, s.NdotV));
#endif
} 

#endif // A_FEATURES_RIM_CGINC
