// Alloy Physical Shader Framework
// Copyright 2013-2016 RUST LLC.
// http://www.alloy.rustltd.com/

///////////////////////////////////////////////////////////////////////////////
/// @file Splat.cginc
/// @brief Splat mapping with either UV or TriPlanar texture mapping.
///////////////////////////////////////////////////////////////////////////////

#ifndef A_FRAMEWORK_SPLAT_CGINC
#define A_FRAMEWORK_SPLAT_CGINC

#include "Assets/Alloy/Shaders/Framework/Surface.cginc"
#include "Assets/Alloy/Shaders/Framework/Utility.cginc"

#include "HLSLSupport.cginc"
#include "UnityCG.cginc"

/// Contains accumulated splat material data.
struct ASplat {
    /// Albedo and/or Metallic f0, with roughness in alpha.
    half4 base;

    /// Packed material data.
    half4 material;

    /// World, Object, or packed Tangent normals.
    half4 normal;
};

/// Contains shared state for all splat functions, including TriPlanar data.
struct ASplatContext {
    /// Vertex color.
    /// Expects linear-space LDR color values.
    half4 vertexColor;

    /// The model's UV0 & UV1 texture coordinate data.
    /// Be aware that it can have parallax precombined with it.
    float4 uv01;

    /// X-axis TriPlanar tangent to world matrix.
    half3x3 xTangentToWorld;

    /// Y-axis TriPlanar tangent to world matrix.
    half3x3 yTangentToWorld;

    /// Z-axis TriPlanar tangent to world matrix.
    half3x3 zTangentToWorld;

    /// Blend weights between the top, middle, and bottom TriPlanar axis.
    half3 blend;

    /// Position in either world or object-space.
    float3 position;

    /// Binary masks for the positive values in the vertex normals.
    half3 axisMasks;
};

/// Constructor. 
/// @return Structure initialized with sane default values.
ASplat aCreateSplat()
{
    ASplat sp;

    UNITY_INITIALIZE_OUTPUT(ASplat, sp);
    sp.base = 0.0h;
    sp.material = 0.0h;
    sp.normal = 0.0h;
    return sp;
}

/// Uses surface data to make shared splat data.
/// @param  s               Material surface data.
/// @param  sharpness       Sharpness of the blend between TriPlanar axis.
/// @param  positionScale   Scales the position used for TriPlanar UVs.
/// @return                 Splat context initialized with shared data.
ASplatContext aCreateSplatContext(
    ASurface s,
    half sharpness,
    float positionScale)
{
    ASplatContext sc;
    UNITY_INITIALIZE_OUTPUT(ASplatContext, sc);

    sc.uv01 = s.uv01;
#ifndef A_VERTEX_COLOR_BLEND_WEIGHTS
    sc.vertexColor = s.vertexColor;
#endif
#ifdef A_TRIPLANAR
    // Triplanar mapping
    // cf http://www.gamedev.net/blog/979/entry-2250761-triplanar-texturing-and-normal-mapping/
    #ifdef _TRIPLANARMODE_WORLD
        half3 geoNormal = s.vertexNormalWorld;
        sc.position = s.positionWorld;
    #else
        half3 geoNormal = UnityWorldToObjectDir(s.vertexNormalWorld);
        sc.position = mul(unity_WorldToObject, float4(s.positionWorld, 1.0f)).xyz;
    #endif

    // Unity uses a Left-handed axis, so it requires clumsy remapping.
    sc.xTangentToWorld = half3x3(half3(0.0h, 0.0h, 1.0h), half3(0.0h, 1.0h, 0.0h), geoNormal);
    sc.yTangentToWorld = half3x3(half3(1.0h, 0.0h, 0.0h), half3(0.0h, 0.0h, 1.0h), geoNormal);
    sc.zTangentToWorld = half3x3(half3(1.0h, 0.0h, 0.0h), half3(0.0h, 1.0h, 0.0h), geoNormal);

    half3 blending = abs(geoNormal);
    blending = normalize(max(blending, A_EPSILON));
    blending = pow(blending, sharpness);
    blending /= dot(blending, half3(1.0h, 1.0h, 1.0h));
    sc.blend = blending;

    sc.axisMasks = step(half3(0.0h, 0.0h, 0.0h), geoNormal);
    sc.position *= positionScale;
#endif

    return sc;
}

/// Converts splat to material data and assigns it to a surface.
/// @param[in,out]  s   Material surface data.
/// @param[in]      sp  Combined splat data.
void aApplySplat(
    inout ASurface s,
    ASplat sp)
{
    s.baseColor = sp.base.rgb;
    s.metallic = sp.material.r;
    s.specularity = sp.material.b;

#ifdef A_SPLAT_MATERIAL_FULL
    s.ambientOcclusion = sp.material.g;
    s.roughness = sp.material.a;
#else
    s.roughness = sp.base.a;

    #ifdef A_SPECULAR_TINT_ON
        s.specularTint = sp.material.g;
    #endif
#endif
#ifndef A_TRIPLANAR
    s.normalTangent = UnpackNormal(sp.normal);
#else
    #ifdef _TRIPLANARMODE_WORLD
        s.normalWorld = normalize(sp.normal.xyz);
    #else
        s.normalWorld = UnityObjectToWorldNormal(sp.normal.xyz);
    #endif    

    s.normalTangent = aNormalTangent(s, s.normalWorld);
#endif
}

/// Combines two splats into one, accumulating into first splat.
/// @param[in,out]  sp0 Target for combined splat data ouput.
/// @param[in]      sp1 Second splat to be combined.
void aMergeSplats(
    inout ASplat sp0,
    ASplat sp1)
{
    sp0.base += sp1.base;
    sp0.material += sp1.material;
    sp0.normal += sp1.normal;
}

/// Applies constant material data to a splat.
/// @param[in,out]  sp              Splat being modified.
/// @param[in]      sc              Splat context.
/// @param[in]      tint            Base color tint.
/// @param[in]      vertexTint      Base color vertex color tint weight.
/// @param[in]      metallic        Metallic  weight.
/// @param[in]      specularity     Specularity.
/// @param[in]      specularTint    Specular tint weight.
/// @param[in]      roughness       Linear roughness.
void aSplatMaterial(
    inout ASplat sp,
    ASplatContext sc,
    half4 tint,
    half vertexTint,
    half metallic,
    half specularity,
    half specularTint,
    half roughness)
{
    sp.base *= tint;
#ifndef A_VERTEX_COLOR_BLEND_WEIGHTS
    sp.base.rgb *= aLerpWhiteTo(sc.vertexColor.rgb, vertexTint);
#endif
#ifdef A_SPLAT_MATERIAL_FULL
    sp.material *= half4(metallic, 1.0h, specularity, roughness);
#else
    sp.base.a *= roughness;
    sp.material *= half4(metallic, specularTint, specularity, 1.0h);
#endif
}

/// TriPlanar axis applied to a splat.
/// @param[in,out]  sp          Splat being modified.
/// @param[in]      mask        Masks where the effect is applied.
/// @param[in]      tbn         Local normal tangent to world matrix.
/// @param[in]      uv          Texture coordinates.
/// @param[in]      occlusion   Occlusion map weight.
/// @param[in]      bumpScale   Normal map XY scale.
/// @param[in]      base        Base color map.
/// @param[in]      material    Material map.
/// @param[in]      normal      Normal map.
void aTriPlanarAxis(
    inout ASplat sp,
    half mask,
    half3x3 tbn,
    float2 uv,
    half occlusion,
    half bumpScale,
    sampler2D base,
    sampler2D material,
    sampler2D normal)
{
    sp.base += mask * tex2D(base, uv);
    sp.normal += mask * mul(UnpackScaleNormal(tex2D(normal, uv), bumpScale), tbn).xyzz;

#ifndef A_SPLAT_MATERIAL_FULL
    sp.material += mask.rrrr;
#else
    half4 mat = tex2D(material, uv);
    mat.g = aLerpOneTo(GammaToLinearSpace(mat.ggg).r, occlusion);
    sp.material += mask * mat;
#endif
}

/// X-axis triplanar material applied to a splat.
/// @param[in,out]  sp          Splat being modified.
/// @param[in]      sc          Splat context.
/// @param[in]      base        Base color map.
/// @param[in]      material    Material map.
/// @param[in]      normal      Normal map.
/// @param[in]      occlusion   Occlusion map weight.
/// @param[in]      bumpScale   Normal map XY scale.
void aTriPlanarX(
    inout ASplat sp,
    ASplatContext sc,
    A_SAMPLER_PARAM(base),
    sampler2D material,
    sampler2D normal,
    half occlusion,
    half bumpScale)
{
    aTriPlanarAxis(sp, sc.blend.x, sc.xTangentToWorld, A_TRANSFORM_SCROLL(base, sc.position.zy), occlusion, bumpScale, base, material, normal);
}

/// Y-axis triplanar material applied to a splat.
/// @param[in,out]  sp          Splat being modified.
/// @param[in]      sc          Splat context.
/// @param[in]      base        Base color map.
/// @param[in]      material    Material map.
/// @param[in]      normal      Normal map.
/// @param[in]      occlusion   Occlusion map weight.
/// @param[in]      bumpScale   Normal map XY scale.
void aTriPlanarY(
    inout ASplat sp,
    ASplatContext sc,
    A_SAMPLER_PARAM(base),
    sampler2D material,
    sampler2D normal,
    half occlusion,
    half bumpScale)
{
    aTriPlanarAxis(sp, sc.blend.y, sc.yTangentToWorld, A_TRANSFORM_SCROLL(base, sc.position.xz), occlusion, bumpScale, base, material, normal);
}

/// Z-axis triplanar material applied to a splat.
/// @param[in,out]  sp          Splat being modified.
/// @param[in]      sc          Splat context.
/// @param[in]      base        Base color map.
/// @param[in]      material    Material map.
/// @param[in]      normal      Normal map.
/// @param[in]      occlusion   Occlusion map weight.
/// @param[in]      bumpScale   Normal map XY scale.
void aTriPlanarZ(
    inout ASplat sp,
    ASplatContext sc,
    A_SAMPLER_PARAM(base),
    sampler2D material,
    sampler2D normal,
    half occlusion,
    half bumpScale)
{
    aTriPlanarAxis(sp, sc.blend.z, sc.zTangentToWorld, A_TRANSFORM_SCROLL(base, sc.position.xy), occlusion, bumpScale, base, material, normal);
}

/// Positive Y-axis triplanar material applied to a splat.
/// @param[in,out]  sp          Splat being modified.
/// @param[in]      sc          Splat context.
/// @param[in]      base        Base color map.
/// @param[in]      material    Material map.
/// @param[in]      normal      Normal map.
/// @param[in]      occlusion   Occlusion map weight.
/// @param[in]      bumpScale   Normal map XY scale.
void aTriPlanarPositiveY(
    inout ASplat sp,
    ASplatContext sc,
    A_SAMPLER_PARAM(base),
    sampler2D material,
    sampler2D normal,
    half occlusion,
    half bumpScale)
{
    aTriPlanarAxis(sp, sc.axisMasks.y * sc.blend.y, sc.yTangentToWorld, A_TRANSFORM_SCROLL(base, sc.position.xz), occlusion, bumpScale, base, material, normal);
}

/// Negative Y-axis triplanar material applied to a splat.
/// @param[in,out]  sp          Splat being modified.
/// @param[in]      sc          Splat context.
/// @param[in]      base        Base color map.
/// @param[in]      material    Material map.
/// @param[in]      normal      Normal map.
/// @param[in]      occlusion   Occlusion map weight.
/// @param[in]      bumpScale   Normal map XY scale.
void aTriPlanarNegativeY(
    inout ASplat sp,
    ASplatContext sc,
    A_SAMPLER_PARAM(base),
    sampler2D material,
    sampler2D normal,
    half occlusion,
    half bumpScale)
{
    aTriPlanarAxis(sp, (1.0h - sc.axisMasks.y) * sc.blend.y, sc.yTangentToWorld, A_TRANSFORM_SCROLL(base, sc.position.xz), occlusion, bumpScale, base, material, normal);
}

/// Applies constant material data to a splat.
/// @param  sc              Splat context.
/// @param  base            Base color map.
/// @param  normal          Normal map.
/// @param  tint            Base color tint.
/// @param  metallic        Metallic  weight.
/// @param  specularity     Specularity.
/// @param  specularTint    Specular tint weight.
/// @param  roughness       Linear roughness.
/// @return                 Splat populated with terrain data.
ASplat aCreateTerrainSplat(
    ASplatContext sc,
    A_SAMPLER_PARAM(base),
    sampler2D normal,
    half3 tint,
    half metallic,
    half specularity,
    half specularTint,
    half roughness)
{
    ASplat sp = aCreateSplat();

#ifndef A_TRIPLANAR
    float2 uv = A_TRANSFORM_UV_SCROLL(sc, base);
    sp.base = tex2D(base, uv);
    sp.normal = tex2D(normal, uv); // Leave packed until the end.
    sp.material = 1.0h;
#else
    aTriPlanarX(sp, sc, A_SAMPLER_INPUT(base), base, normal, 1.0h, 1.0h);
    aTriPlanarY(sp, sc, A_SAMPLER_INPUT(base), base, normal, 1.0h, 1.0h);
    aTriPlanarZ(sp, sc, A_SAMPLER_INPUT(base), base, normal, 1.0h, 1.0h);
#endif

    aSplatMaterial(sp, sc, half4(tint, 1.0h), 0.0h, metallic, specularity, specularTint, roughness);
    return sp;
}

/// Combine splats and convert to material data to assign to a surface.
/// @param[in,out]  s       Material surface data.
/// @param[in]      weights Weights masking where splats are combined.
/// @param[in]      sp0     Splat data.
/// @param[in]      sp1     Splat data.
/// @param[in]      sp2     Splat data.
/// @param[in]      sp3     Splat data.
void aApplyTerrainSplats(
    inout ASurface s,
    half4 weights,
    ASplat sp0,
    ASplat sp1,
    ASplat sp2,
    ASplat sp3)
{
    ASplat sp = aCreateSplat();
    sp.base = weights.r * sp0.base + weights.g * sp1.base + weights.b * sp2.base + weights.a * sp3.base;
    sp.material = weights.r * sp0.material + weights.g * sp1.material + weights.b * sp2.material + weights.a * sp3.material;
    sp.normal = weights.r * sp0.normal + weights.g * sp1.normal + weights.b * sp2.normal + weights.a * sp3.normal;
    aApplySplat(s, sp);
}

#endif // A_FRAMEWORK_SPLAT_CGINC
