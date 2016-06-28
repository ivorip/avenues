// Alloy Physical Shader Framework
// Copyright 2013-2016 RUST LLC.
// http://www.alloy.rustltd.com/

/////////////////////////////////////////////////////////////////////////////////
/// @file HeightmapBlend.cginc
/// @brief Blending with a heightmap, a cutoff value, and the vertex color alpha.
/////////////////////////////////////////////////////////////////////////////////

#ifndef A_FEATURES_HEIGHTMAP_BLEND_CGINC
#define A_FEATURES_HEIGHTMAP_BLEND_CGINC

#include "Assets/Alloy/Shaders/Framework/Feature.cginc"

#ifdef A_HEIGHTMAP_BLEND_ON
    /// Heightmap used for blending.
    /// Expects an RGB data map.
    A_SAMPLER2D(_BlendMap);
    
    /// Heightmap Blend weight.
    /// Expects values in the range [0,1].
    half _BlendScale;
    
    /// Height cutoff where blend begins.
    /// Expects values in the range [0,1].
    half _BlendCutoff;
    
    /// Offset from cutoff where smooth blending occurs.
    /// Expects values in the range [0,1].
    half _Blend; 
    
    /// Controls how much the vertex color alpha influences the cutoff.
    /// Expects values in the range [0,1].
    half _BlendAlphaVertexTint;
#endif

/// Applies the Detail feature to the given material data.
/// @param[in,out] s Material surface data.
void aHeightmapBlend(
    inout ASurface s)
{
#ifdef A_HEIGHTMAP_BLEND_ON
    float2 blendUv = A_TRANSFORM_UV(s, _BlendMap);
    half blendCutoff = 1.0h - 1.01h * lerp(_BlendCutoff, 1.0h, s.vertexColor.a * _BlendAlphaVertexTint);
    half mask = 1.0h - tex2D(_BlendMap, blendUv).g;
    mask = smoothstep(blendCutoff - _Blend, blendCutoff, mask);
    s.mask *= mask * _BlendScale;
#endif
}

#endif // A_FEATURES_HEIGHTMAP_BLEND_CGINC
