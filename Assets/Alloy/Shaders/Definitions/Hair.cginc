// Alloy Physical Shader Framework
// Copyright 2013-2016 RUST LLC.
// http://www.alloy.rustltd.com/

/////////////////////////////////////////////////////////////////////////////////
/// @file Hair.cginc
/// @brief Hair surface shader definition.
/////////////////////////////////////////////////////////////////////////////////

#ifndef A_DEFINITIONS_HAIR_CGINC
#define A_DEFINITIONS_HAIR_CGINC

#include "Assets/Alloy/Shaders/Lighting/Hair.cginc"
#include "Assets/Alloy/Shaders/Models/Standard.cginc"

/// Amount that diffuse lighting should wrap around.
/// Expects values in the range [0,1].
half _HairDiffuseWrapAmount;

/// Overall hair specularity.
/// Expects values in the range [0,1].
half _HairSpecularity;

/// Rotation of the hair highlight
/// Expects rotation values in degrees.
half _AnisoAngle;

/// Primary highlight tint color.
/// Expects a linear LDR color.
half3 _HighlightTint0;

/// Primary highlight position shift along normal.
/// Expects values in the range [-n,n].
half _HighlightShift0;

/// Primary highlight width.
/// Expects values in the range [0,1].
half _HighlightWidth0;

/// Secondary highlight tint color.
/// Expects a linear LDR color.
half3 _HighlightTint1;

/// Secondary highlight position shift along normal.
/// Expects values in the range [-n,n].
half _HighlightShift1;

/// Secondary highlight width.
/// Expects values in the range [0,1].
half _HighlightWidth1;

void aSurface(
    inout ASurface s)
{
    aDissolve(s);

    half4 base = aBaseColor(s);
    s.baseColor = base.rgb;
    s.opacity = base.a;
    s.diffuseWrap = _HairDiffuseWrapAmount;
    
    aCutout(s);

    half4 material = aSampleMaterial(s);
    s.ambientOcclusion = aAmbientOcclusion(material);
    s.specularity = _HairSpecularity;
    s.roughness = material.w;
    
    // Preshift down so a middle-gray texture can push the highlight up or down!
    half shift = material.x - 0.5h;
    s.highlightTint0 = _HighlightTint0 * material.z; // Noise
    s.highlightShift0 = _HighlightShift0 + shift;
    s.highlightWidth0 = _HighlightWidth0;
    s.highlightTint1 = _HighlightTint1;
    s.highlightShift1 = _HighlightShift1 + shift;
    s.highlightWidth1 = _HighlightWidth1;
    
    half theta = radians(_AnisoAngle);
    s.highlightTangent = half3(cos(theta), sin(theta), 0.0h);
    s.normalTangent = aSampleBump(s);
     
    aDecal(s); 
    aUpdateNormalData(s);
    aRim(s);
    aEmission(s);
}

#endif // A_DEFINITIONS_HAIR_CGINC
