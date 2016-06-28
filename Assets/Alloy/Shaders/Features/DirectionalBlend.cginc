// Alloy Physical Shader Framework
// Copyright 2013-2016 RUST LLC.
// http://www.alloy.rustltd.com/

/////////////////////////////////////////////////////////////////////////////////
/// @file DirectionalBlend.cginc
/// @brief Allows blending based how much a normal faces a given direction.
/////////////////////////////////////////////////////////////////////////////////

#ifndef A_FEATURES_DIRECTIONAL_BLEND_CGINC
#define A_FEATURES_DIRECTIONAL_BLEND_CGINC

#include "Assets/Alloy/Shaders/Framework/Feature.cginc"

#if !defined(_DIRECTIONALBLENDMODE_WORLD) && !defined(_DIRECTIONALBLENDMODE_OBJECT)
    #define _DIRECTIONALBLENDMODE_WORLD
#endif

#ifdef A_DIRECTIONAL_BLEND_ON
    /// Direction around which the blending occurs.
    /// Expects a normalized direction vector.
    half3 _DirectionalBlendDirection;
    
    /// Directional Blend weight.
    /// Expects values in the range [0,1].
    half _OrientedScale;
    
    /// Hemispherical cutoff where blend begins.
    /// Expects values in the range [0,1].
    half _OrientedCutoff;
    
    /// Offset from cutoff where smooth blending occurs.
    /// Expects values in the range [0,1].
    half _OrientedBlend;
#endif

/// Applies the Rim Lighting feature to the given material data.
/// @param[in,out] s Material surface data.
void aDirectionalBlend(
    inout ASurface s)
{
#ifdef A_DIRECTIONAL_BLEND_ON
    half3 normal;
    half blendCutoff = 1.0h - 1.01h * _OrientedCutoff;

    s.normalWorld = aNormalWorld(s, s.normalTangent);

    #ifdef _DIRECTIONALBLENDMODE_WORLD
        normal = s.normalWorld;
    #else
        normal = UnityWorldToObjectDir(s.normalWorld);
    #endif	
    
    half mask = dot(normal, _DirectionalBlendDirection) * 0.5h + 0.5h;
    mask = smoothstep(blendCutoff - _OrientedBlend, blendCutoff, mask);
    s.mask *= mask * _OrientedScale;
#endif
}

#endif // A_FEATURES_DIRECTIONAL_BLEND_CGINC
