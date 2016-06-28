// Alloy Physical Shader Framework
// Copyright 2013-2016 RUST LLC.
// http://www.alloy.rustltd.com/

/////////////////////////////////////////////////////////////////////////////////
/// @file OrientedTextures.cginc
/// @brief Secondary set of textures using world/object position XZ as their UVs.
/////////////////////////////////////////////////////////////////////////////////

#ifndef A_FEATURES_ORIENTED_TEXTURES_CGINC
#define A_FEATURES_ORIENTED_TEXTURES_CGINC

#include "Assets/Alloy/Shaders/Framework/Feature.cginc"

#ifdef A_ORIENTED_TEXTURES_ON
    /// The world-oriented tint color.
    /// Expects a linear LDR color with alpha.
    half4 _OrientedColor;
    
    /// The world-oriented color map.
    /// Expects an RGB(A) map with sRGB sampling.
    A_SAMPLER2D(_OrientedMainTex);

    #ifndef _ORIENTEDROUGHNESSSOURCE_BASECOLORALPHA
        /// The world-oriented packed material map.
        /// Expects an RGBA data map.
        sampler2D _OrientedMaterialMap;
    #endif

    /// The world-oriented normal map.
    /// Expects a compressed normal map.
    sampler2D _OrientedBumpMap;
    
    /// Toggles tinting the world-oriented color by the vertex color.
    /// Expects values in the range [0,1].
    half _OrientedColorVertexTint;

    /// The world-oriented metallic scale.
    /// Expects values in the range [0,1].
    half _OrientedMetallic;

    /// The world-oriented specularity scale.
    /// Expects values in the range [0,1].
    half _OrientedSpecularity;
    
    /// The world-oriented roughness scale.
    /// Expects values in the range [0,1].
    half _OrientedRoughness;

    /// Ambient Occlusion strength.
    /// Expects values in the range [0,1].
    half _OrientedOcclusion;
    
    /// Normal map XY scale.
    half _OrientedNormalMapScale;
#endif

/// Applies the Emission feature to the given material data.
/// @param[in,out] s Material surface data.
void aOrientedTextures(
    inout ASurface s)
{
#ifdef A_ORIENTED_TEXTURES_ON
    // Unity uses a Left-handed axis, so it requires clumsy remapping.
    const half3x3 yTangentToWorld = half3x3(half3(1.0h, 0.0h, 0.0h), half3(0.0h, 0.0h, 1.0h), s.vertexNormalWorld);
    
    float2 orientedUv = A_TRANSFORM_SCROLL(_OrientedMainTex, s.positionWorld.xz);
    half mask = s.mask;
    half4 material2 = half4(_OrientedMetallic, 1.0h, _OrientedSpecularity, _OrientedRoughness);
    half4 base2 = _OrientedColor * tex2D(_OrientedMainTex, orientedUv);
    
    base2.rgb *= aLerpWhiteTo(s.vertexColor.rgb, _OrientedColorVertexTint);

    #ifdef _ORIENTEDROUGHNESSSOURCE_BASECOLORALPHA
        material2.w *= base2.a;
        base2.a = 1.0h;
    #else
        #ifndef A_ORIENTED_TEXTURES_ALPHA_BLEND_OFF
            mask *= base2.a;
            base2.a = 1.0h;
        #endif

        material2 *= tex2D(_OrientedMaterialMap, orientedUv);
        material2.y = aLerpOneTo(GammaToLinearSpace(material2.yyy).x, _OrientedOcclusion);
    #endif

    s.baseColor = lerp(s.baseColor, base2.rgb, mask);
    s.opacity = lerp(s.opacity, base2.a, mask);

    s.metallic = lerp(s.metallic, material2.x, mask);
    s.ambientOcclusion = lerp(s.ambientOcclusion, material2.y, mask);
    s.specularity = lerp(s.specularity, material2.z, mask);
    s.roughness = lerp(s.roughness, material2.w, mask);
    
    s.emission *= (1.0h - mask);

    half3 normal = UnpackScaleNormal(tex2D(_OrientedBumpMap, orientedUv), _OrientedNormalMapScale);
    normal = mul(normal, yTangentToWorld);
    s.normalWorld = normalize(lerp(s.normalWorld, normal, mask));
#endif
}

#endif // A_FEATURES_ORIENTED_TEXTURES_CGINC
