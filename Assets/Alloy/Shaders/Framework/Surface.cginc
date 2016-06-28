// Alloy Physical Shader Framework
// Copyright 2013-2016 RUST LLC.
// http://www.alloy.rustltd.com/

/////////////////////////////////////////////////////////////////////////////////
/// @file Surface.cginc
/// @brief ASurface structure, and related methods.
/////////////////////////////////////////////////////////////////////////////////

#ifndef A_FRAMEWORK_SURFACE_CGINC
#define A_FRAMEWORK_SURFACE_CGINC

#include "Assets/Alloy/Shaders/Config.cginc"
#include "Assets/Alloy/Shaders/Framework/Brdf.cginc"
#include "Assets/Alloy/Shaders/Framework/Utility.cginc"

#include "HLSLSupport.cginc"
#include "UnityCG.cginc"
#include "UnityStandardBRDF.cginc"
#include "UnityStandardUtils.cginc"

#if defined(UNITY_PASS_DEFERRED) || defined(UNITY_PASS_FORWARDADD) || defined(UNITY_PASS_FORWARDBASE)
    #define A_TANGENT_NORMAL_MAPPING
#endif

#ifndef A_SURFACE_CUSTOM_LIGHTING_DATA
    #define A_SURFACE_CUSTOM_LIGHTING_DATA
#endif

/// Picks either UV0 or UV1.
#define A_UV(s, name) ((name##UV < 0.5f) ? s.uv01.xy : s.uv01.zw)

/// Applies Unity texture transforms plus UV-switching effect.
#define A_TRANSFORM_UV(s, name) (TRANSFORM_TEX(A_UV(s, name), name))

/// Applies Unity texture transforms plus UV-switching and our scrolling effects.
#define A_TRANSFORM_UV_SCROLL(s, name) (A_TRANSFORM_SCROLL(name, A_UV(s, name)))

/// Contains ALL data and state for rendering a surface.
/// Can set state to control how features are combined into the surface data.
struct ASurface {
    /////////////////////////////////////////////////////////////////////////////
    // Vertex Inputs.
    /////////////////////////////////////////////////////////////////////////////
    
    /// Screen-space texture coordinates.
    float2 screenUv;

    /// Unity's fog data.
    float fogCoord;

    /// The model's UV0 & UV1 texture coordinate data.
    /// Be aware that it can have parallax precombined with it.
    float4 uv01;
        
    /// Tangent space to World space rotation matrix.
    half3x3 tangentToWorld;

    /// Position in world space.
    float3 positionWorld;
        
    /// View direction in world space.
    /// Expects a normalized vector.
    half3 viewDirWorld;
        
    /// View direction in tangent space.
    /// Expects a normalized vector.
    half3 viewDirTangent;
    
    /// Distance from the camera to the given fragement.
    /// Expects values in the range [0,n].
    half viewDepth;
    
    /// Vertex color.
    /// Expects linear-space LDR color values.
    half4 vertexColor;

    /// Vertex normal in world space.
    /// Expects normalized vectors in the range [-1,1].
    half3 vertexNormalWorld;

    /// Indicates via sign whether a triangle is front or back facing.
    /// Positive is front-facing, negative is back-facing. 
    half facingSign;


    /////////////////////////////////////////////////////////////////////////////
    // Feature layering options.
    /////////////////////////////////////////////////////////////////////////////
    
    /// Masks where the next feature layer will be applied.
    /// Expects values in the range [0,1].
    half mask;
        
    /// The base map's texture transform tiling amount.
    float2 baseTiling;
        
    /// Transformed texture coordinates for the base map.
    float2 baseUv;

#ifdef _VIRTUALTEXTURING_ON
    /// Transformed texture coordinates for the virtual base map.
    VirtualCoord baseVirtualCoord;
#endif
    

    /////////////////////////////////////////////////////////////////////////////
    // Material data.
    /////////////////////////////////////////////////////////////////////////////
    
    /// Controls opacity or cutout regions.
    /// Expects values in the range [0,1].
    half opacity;
        
    /// Diffuse ambient occlusion.
    /// Expects values in the range [0,1].
    half ambientOcclusion;
    
    /// Albedo and/or Metallic f0 based on settings. Used by Enlighten.
    /// Expects linear-space LDR color values.
    half3 baseColor;
    
    /// Linear control of dielectric f0 from [0.00,0.08].
    /// Expects values in the range [0,1].
    half specularity;
    
#ifdef A_SPECULAR_TINT_ON
    /// Tints the dielectric specularity by the base color chromaticity.
    /// Expects values in the range [0,1].
    half specularTint;
#endif
#ifdef A_CLEARCOAT_ON
    /// Strength of clearcoat layer, used to apply masks.
    /// Expects values in the range [0,1].
    half clearCoatWeight;
    
    /// Roughness of clearcoat layer.
    /// Expects values in the range [0,1].
    half clearCoatRoughness;
#endif
    
    /// Interpolates material from dielectric to metal.
    /// Expects values in the range [0,1].
    half metallic;
        
    /// Linear roughness value, where zero is smooth and one is rough.
    /// Expects values in the range [0,1].
    half roughness;
    
    /// Normal in tangent space.
    /// Expects a normalized vector.
    half3 normalTangent;
    
    /// Light emission by the material. Used by Enlighten.
    /// Expects linear-space HDR color values.
    half3 emission;

    /// Monochrome transmission thickness.
    /// Expects gamma-space LDR values.
    half transmission;


    /////////////////////////////////////////////////////////////////////////////
    // BRDF inputs.
    /////////////////////////////////////////////////////////////////////////////
    
    /// Diffuse albedo.
    /// Expects linear-space LDR color values.
    half3 albedo;
    
    /// Fresnel reflectance at incidence zero.
    /// Expects linear-space LDR color values.
    half3 f0;
    
    /// Beckmann roughness.
    /// Expects values in the range [0,1].
    half beckmannRoughness;
    
    /// Specular occlusion.
    /// Expects values in the range [0,1].
    half specularOcclusion;
        
    /// Color tint for transmission effect.
    /// Expects linear-space LDR color values.
    half3 transmissionColor;
    
    /// Normal in world space.
    /// Expects normalized vectors in the range [-1,1].
    half3 normalWorld;

    /// Deferred material lighting type.
    /// Expects the values 0, 1/3, 2/3, or 1.
    half materialType;

    /// View reflection vector in world space.
    /// Expects a non-normalized vector.
    half3 reflectionVectorWorld;
    
    /// Clamped N.V.
    /// Expects values in the range [0,1].
    half NdotV;

    /// Fresnel weight of N.V.
    /// Expects values in the range [0,1].
    half FV;
    
    /// Ambient diffuse normal in world space.
    /// Expects normalized vectors in the range [-1,1].
    half3 ambientNormalWorld;
    
    A_SURFACE_CUSTOM_LIGHTING_DATA
};

/// Constructor. 
/// @return Structure initialized with sane default values.
ASurface aCreateSurface() {
    ASurface s;

    UNITY_INITIALIZE_OUTPUT(ASurface, s);
    s.mask = 1.0h;
    s.opacity = 1.0h;
    s.baseColor = 1.0h;
#ifdef A_SPECULAR_TINT_ON
    s.specularTint = 0.0h;
#endif
#ifdef A_CLEARCOAT_ON
    s.clearCoatWeight = 0.0h;
    s.clearCoatRoughness = 0.0h;
#endif
    s.metallic = 0.0h;
    s.specularity = 0.5h;
    s.roughness = 0.0h; 
    s.emission = 0.0h;
    s.ambientOcclusion = 1.0h;
    s.normalTangent = A_FLAT_NORMAL;
    s.materialType = 1.0h;
    s.transmission = 0.0h;
    
    // Stop divide by zero warnings from the compiler.
    s.vertexNormalWorld = half3(0.0h, 0.0h, 1.0h);
    s.normalWorld = half3(0.0h, 0.0h, 1.0h);
    s.viewDirTangent = half3(0.0h, 0.0h, 1.0h);
    s.tangentToWorld = half3x3(half3(0.0h, 0.0h, 0.0h), half3(0.0h, 0.0h, 0.0h), half3(0.0h, 0.0h, 0.0h));
    s.facingSign = 1.0h;

    return s;
}

/// Calculates view-dependent vectors.
/// @param[in,out] s Material surface data.
void aUpdateViewData(
    inout ASurface s)
{
    s.reflectionVectorWorld = reflect(-s.viewDirWorld, s.normalWorld);
    s.NdotV = aDotClamp(s.normalWorld, s.viewDirWorld);
    s.FV = aFresnel(s.NdotV);
}

/// Calculates a world-space normal from a tangent-space input.
/// @param  s               Material surface data.
/// @param  normalTangent   Normal in tangent space.
/// @return                 Normal in world space.
half3 aNormalWorld(
    ASurface s,
    half3 normalTangent)
{
#ifndef A_TANGENT_NORMAL_MAPPING
    return s.vertexNormalWorld;
#else
    return normalize(mul(normalTangent, s.tangentToWorld));
#endif
}

/// Calculates a tangent-space normal from a world-space input.
/// @param  s           Material surface data.
/// @param  normalWorld Normal in world space.
/// @return             Normal in tangent space.
half3 aNormalTangent(
    ASurface s,
    half3 normalWorld)
{
#ifndef A_TANGENT_NORMAL_MAPPING
    return A_FLAT_NORMAL;
#else
    return normalize(mul(s.tangentToWorld, normalWorld));
#endif
}

/// Calculates world-space normal data from the tangent-space normal.
/// @param[in,out] s Material surface data.
void aUpdateNormalData(
    inout ASurface s)
{
    s.normalWorld = aNormalWorld(s, s.normalTangent);
    aUpdateViewData(s);
}

#endif // A_FRAMEWORK_SURFACE_CGINC
