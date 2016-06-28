// Alloy Physical Shader Framework
// Copyright 2013-2016 RUST LLC.
// http://www.alloy.rustltd.com/

/////////////////////////////////////////////////////////////////////////////////
/// @file AO2.cginc
/// @brief Secondary Ambient Occlusion, possibly on a different UV.
/////////////////////////////////////////////////////////////////////////////////

#ifndef A_FEATURES_AO2_CGINC
#define A_FEATURES_AO2_CGINC

#include "Assets/Alloy/Shaders/Framework/Feature.cginc"

#ifdef _AO2_ON
    /// Secondary Ambient Occlusion map.
    /// Expects an RGB map with sRGB sampling
    A_SAMPLER2D(_Ao2Map);

    /// Ambient Occlusion strength.
    /// Expects values in the range [0,1].
    half _Ao2Occlusion;
#endif

/// Applies the Secondary Ambient Occlusion feature to the given material data.
/// @param[in,out] s Material surface data.
void aAo2(
    inout ASurface s) 
{
#ifdef _AO2_ON
    float2 ao2Uv = A_TRANSFORM_UV(s, _Ao2Map);
    s.ambientOcclusion *= aLerpOneTo(tex2D(_Ao2Map, ao2Uv).g, _Ao2Occlusion * s.mask);
#endif
} 

#endif // A_FEATURES_AO2_CGINC
