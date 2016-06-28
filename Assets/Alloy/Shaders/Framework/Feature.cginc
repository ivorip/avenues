// Alloy Physical Shader Framework
// Copyright 2013-2016 RUST LLC.
// http://www.alloy.rustltd.com/

/////////////////////////////////////////////////////////////////////////////////
/// @file Feature.cginc
/// @brief Features uber-header.
/////////////////////////////////////////////////////////////////////////////////

#ifndef A_FRAMEWORK_FEATURE_CGINC
#define A_FRAMEWORK_FEATURE_CGINC

// NOTE: Config comes first to override Unity settings!
#include "Assets/Alloy/Shaders/Config.cginc"
#include "Assets/Alloy/Shaders/Framework/Surface.cginc"
#include "Assets/Alloy/Shaders/Framework/Utility.cginc"

#include "UnityCG.cginc"
#include "UnityStandardBRDF.cginc"
#include "UnityStandardUtils.cginc"

#if defined(_ALPHABLEND_ON) || defined(_ALPHAPREMULTIPLY_ON)
    #define A_ALPHA_BLENDING_ON 
#endif	

// NOTE: baseTiling is last in order to prevent compilation errors when using AT.
#ifdef _VIRTUALTEXTURING_ON
    #define A_SET_BASE_UV(s, TEX) \
        s.baseUv = A_TRANSFORM_UV(s, TEX); \
        s.baseVirtualCoord = VTComputeVirtualCoord(s.baseUv); \
        s.baseTiling = TEX##_ST.xy;

    #define A_SET_BASE_UV_SCROLL(s, TEX) \
        s.baseUv = A_TRANSFORM_UV_SCROLL(s, TEX); \
        s.baseVirtualCoord = VTComputeVirtualCoord(s.baseUv); \
        s.baseTiling = TEX##_ST.xy;
#else
    #define A_SET_BASE_UV(s, TEX) \
        s.baseUv = A_TRANSFORM_UV(s, TEX); \
        s.baseTiling = TEX##_ST.xy;

    #define A_SET_BASE_UV_SCROLL(s, TEX) \
        s.baseUv = A_TRANSFORM_UV_SCROLL(s, TEX); \
        s.baseTiling = TEX##_ST.xy; 
#endif


/// Cutoff value that controls where cutout occurs over opacity.
/// Expects values in the range [0,1].
half _Cutoff;

#ifdef A_TWO_SIDED_ON
    /// Toggles inverting the backface normals.
    /// Expects the values 0 or 1.
    half _TransInvertBackNormal;
#endif

/// The base tint color.
/// Expects a linear LDR color with alpha.
half4 _Color;

/// Base color map.
/// Expects an RGB(A) map with sRGB sampling.
A_SAMPLER2D(_MainTex);

#ifndef A_EXPANDED_MATERIAL_MAPS
    /// Base packed material map.
    /// Expects an RGBA data map.
    A_SAMPLER2D(_SpecTex);
#else
    /// Metallic map.
    /// Expects an RGB map with sRGB sampling
    sampler2D _MetallicMap;

    /// Ambient Occlusion map.
    /// Expects an RGB map with sRGB sampling
    sampler2D _AoMap;

    /// Specularity map.
    /// Expects an RGB map with sRGB sampling
    sampler2D _SpecularityMap;

    /// Roughness map.
    /// Expects an RGB map with sRGB sampling
    sampler2D _RoughnessMap;
#endif

/// Base normal map.
/// Expects a compressed normal map.
sampler2D _BumpMap;

/// Toggles tinting the base color by the vertex color.
/// Expects values in the range [0,1].
half _BaseColorVertexTint;

/// The base metallic scale.
/// Expects values in the range [0,1].
half _Metal; 

/// The base specularity scale.
/// Expects values in the range [0,1].
half _Specularity;

#ifdef A_SPECULAR_TINT_ON
    // Amount that f0 is tinted by the base color.
    /// Expects values in the range [0,1].
    half _SpecularTint;
#endif

/// The base roughness scale.
/// Expects values in the range [0,1].
half _Roughness;

/// Ambient Occlusion strength.
/// Expects values in the range [0,1].
half _Occlusion;

/// Normal map XY scale.
half _BumpScale;

/// Sets whether backface normals are inverted.
/// @param[in,out] s Material surface data.
void aTwoSided(
    inout ASurface s)
{
#ifdef A_TWO_SIDED_ON
    s.normalTangent.xy = s.facingSign > 0.0h || _TransInvertBackNormal < 0.5h ? s.normalTangent.xy : -s.normalTangent.xy;
#endif
}

/// Sets opacity channel as mask.
/// @param[in,out] s Material surface data.
void aOpacityBlend(
    inout ASurface s)
{
    s.mask = s.opacity;
}

/// Sets mask to replace everything.
/// @param[in,out] s Material surface data.
void aNoBlend(
    inout ASurface s)
{
    s.mask = 1.0h;
}

/// Inverts current feature mask.
/// @param[in,out] s Material surface data.
void aInvertBlend(
    inout ASurface s)
{
    s.mask = 1.0h - s.mask;
}

/// Sets the feature mask by combining a packed mask map with a picker vector.
/// @param[in,out]  s           Material surface data.
/// @param[in]      masks       Masks from packed mask map.
/// @param[in]      maskPicker  Mask picker vector, with values of 0 or 1.
void aMasksBlend(
    inout ASurface s,
    half4 masks,
    half4 maskPicker)
{
    s.mask = aDotClamp(masks, maskPicker);
}

/// Sets base UVs to match _MainTex sampler.
/// @param[in,out] s Material surface data.
void aSetDefaultBaseUv(
    inout ASurface s)
{
    A_SET_BASE_UV_SCROLL(s, _MainTex);
}

/// Sets base UVs directly.
/// @param[in,out]  s Material surface data.
/// @param[in]      baseUv Material surface data.
void aSetBaseUv(
    inout ASurface s,
    float2 baseUv)
{
    s.baseUv = baseUv;

#ifdef _VIRTUALTEXTURING_ON
    s.baseVirtualCoord = VTUpdateVirtualCoord(s.baseVirtualCoord, s.baseUv);
#endif
}

/// Applies cutout effect.
/// @param s Material surface data.
void aCutout(
    ASurface s)
{
#ifdef _ALPHATEST_ON
    clip(s.opacity - _Cutoff);
#endif
}

/// Samples the base color map.
/// @param  s   Material surface data.
/// @return     Base Color with alpha.
half4 aSampleBase(
    ASurface s) 
{
    half4 result = 0.0h;

#ifdef _VIRTUALTEXTURING_ON
    result = VTSampleBase(s.baseVirtualCoord);
#else
    result = tex2D(_MainTex, s.baseUv);
#endif
    
    return result;
}

/// Samples the base material map.
/// @param  s   Material surface data.
/// @return     Packed material.
half4 aSampleMaterial(
    ASurface s) 
{
    half4 result = 0.0h;

#ifdef A_EXPANDED_MATERIAL_MAPS
    // Assuming sRGB texture filtering, undo it for all but AO.
    result.x = tex2D(_MetallicMap, s.baseUv).g;
    result.y = tex2D(_AoMap, s.baseUv).g;
    result.z = tex2D(_SpecularityMap, s.baseUv).g;
    result.w = tex2D(_RoughnessMap, s.baseUv).g;
    result.xzw = LinearToGammaSpace(result.xzw);
#else
    #ifdef _VIRTUALTEXTURING_ON
        result = VTSampleSpecular(s.baseVirtualCoord);
    #else
        result = tex2D(_SpecTex, s.baseUv);
    #endif

    // Converts AO from gamma to linear
    result.y = GammaToLinearSpace(result.yyy).r;
#endif

    return result;
}

/// Samples the base bump map.
/// @param  s   Material surface data.
/// @return     Normalized tangent-space normal.
half3 aSampleBump(
    ASurface s) 
{
    half4 result = 0.0h;

#ifdef _VIRTUALTEXTURING_ON
    result = VTSampleNormal(s.baseVirtualCoord);
#else
    result = tex2D(_BumpMap, s.baseUv);
#endif

    return UnpackScaleNormal(result, _BumpScale);  
}

/// Samples  and scales the base bump map.
/// @param  s       Material surface data.
/// @param  scale   Normal XY scale factor.
/// @return         Normalized tangent-space normal.
half3 aSampleBumpScale(
    ASurface s,
    half scale)
{
    half4 result = 0.0h;

#ifdef _VIRTUALTEXTURING_ON
    result = VTSampleNormal(s.baseVirtualCoord);
#else
    result = tex2D(_BumpMap, s.baseUv);
#endif

    return UnpackScaleNormal(result, _BumpScale * scale);
}

/// Samples the base bump map biasing the mipmap level sampled.
/// @param  s   Material surface data.
/// @return     Normalized tangent-space normal.
half3 aSampleBumpBias(
    ASurface s,
    float bias) 
{
    half4 result = 0.0h;

#ifdef _VIRTUALTEXTURING_ON
    result = VTSampleNormal(VTComputeVirtualCoord(s.baseUv, bias));
#else
    result = tex2Dbias(_BumpMap, float4(s.baseUv, 0.0h, bias));
#endif

    return UnpackScaleNormal(result, _BumpScale);  
}

/// Applies vertex color based on weight parameter.
/// @param  s   Material surface data.
/// @return     Vertex color tint.
half3 aVertexColorTint(
    ASurface s)
{
#ifdef A_VERTEX_COLOR_BLEND_WEIGHTS
    return half3(1.0h, 1.0h, 1.0h);
#else
    return aLerpWhiteTo(s.vertexColor.rgb, _BaseColorVertexTint);
#endif
}

/// Gets combined base color from main channels.
/// @param  s   Material surface data.
/// @return     Base Color with alpha.
half4 aBaseColor(
    ASurface s)
{
    half4 result = _Color * aSampleBase(s);

    result.rgb *= aVertexColorTint(s);
    return result;
}

/// Obtains specularity from packed map.
/// @param  material    Packed material map sample.
/// @return             Specularity.
half aMetallic(
    half4 material)
{
    return _Metal * material.x;
}

/// Obtains ambient occlusion from packed map.
/// @param  material    Packed material map sample.
/// @return             Modified linear-space AO.
half aAmbientOcclusion(
    half4 material)
{
    return aLerpOneTo(material.y, _Occlusion);
}

/// Obtains specularity from packed map.
/// @param  material    Packed material map sample.
/// @return             Specularity.
half aSpecularity(
    half4 material)
{
    return _Specularity * material.z;
}

/// Obtains roughness from packed map.
/// @param  material    Packed material map sample.
/// @return             Roughness.
half aRoughness(
    half4 material)
{
    return _Roughness * material.w;
}

#endif // A_FRAMEWORK_FEATURE_CGINC
