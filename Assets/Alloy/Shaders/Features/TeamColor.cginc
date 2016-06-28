// Alloy Physical Shader Framework
// Copyright 2013-2016 RUST LLC.
// http://www.alloy.rustltd.com/

/////////////////////////////////////////////////////////////////////////////////
/// @file TeamColor.cginc
/// @brief Team Color via texture color component masks and per-mask tint colors.
/////////////////////////////////////////////////////////////////////////////////

#ifndef A_FEATURES_TEAMCOLOR_CGINC
#define A_FEATURES_TEAMCOLOR_CGINC

#include "Assets/Alloy/Shaders/Framework/Feature.cginc"

#ifdef _TEAMCOLOR_ON
    /// Mask map that stores a tint mask in each channel.
    /// Expects an RGB(A) data map.
    sampler2D _TeamColorMaskMap;

    /// Use the mask texture as a color tint.
    /// Expects either 0 or 1.
    half _TeamColorMasksAsTint;
    
    /// Toggles which channels to use from the masks map.
    /// Expects a vector where each component is either 0 or 1;
    half4 _TeamColorMasks;
    
    /// The red channel mask tint color.
    /// Expects a linear LDR color.
    half3 _TeamColor0;
    
    /// The green channel mask tint color.
    /// Expects a linear LDR color.
    half3 _TeamColor1;
    
    /// The blue channel mask tint color.
    /// Expects a linear LDR color.
    half3 _TeamColor2;
    
    /// The alpha channel mask tint color.
    /// Expects a linear LDR color.
    half3 _TeamColor3;
#endif

/// Applies the TeamColor feature to the given material data.
/// @param[in,out] s Material surface data.
void aTeamColor(
    inout ASurface s) 
{
#ifdef _TEAMCOLOR_ON
    half4 masksColor = tex2D(_TeamColorMaskMap, s.baseUv);
    half4 masks = s.mask * (_TeamColorMasks * masksColor);
    half weight = dot(masks, half4(1.0h, 1.0h, 1.0h, 1.0h));
    
    // Renormalize masks when their combined weight sums to greater than one.
    masks /= max(1.0h, weight);
    
    // Combine colors, then fill to white where weights sum to less than one.
    half3 teamColor = _TeamColor0 * masks.r 
                    + _TeamColor1 * masks.g 
                    + _TeamColor2 * masks.b 
                    + _TeamColor3 * masks.a 
                    + saturate(1.0h - weight).rrr;

    s.baseColor *= lerp(teamColor, masksColor.rgb, _TeamColorMasksAsTint);
#endif
} 

#endif // A_FEATURES_TEAMCOLOR_CGINC
