// Alloy Physical Shader Framework
// Copyright 2013-2016 RUST LLC.
// http://www.alloy.rustltd.com/

///////////////////////////////////////////////////////////////////////////////
/// @file Model.cginc
/// @brief Model type uber-header.
///////////////////////////////////////////////////////////////////////////////

#ifndef A_FRAMEWORK_MODEL_CGINC
#define A_FRAMEWORK_MODEL_CGINC

// NOTE: Config comes first to override Unity settings!
#include "Assets/Alloy/Shaders/Config.cginc"
#include "Assets/Alloy/Shaders/Framework/Surface.cginc"
#include "Assets/Alloy/Shaders/Framework/Utility.cginc"

// Features
#include "Assets/Alloy/Shaders/Features/AO2.cginc"
#include "Assets/Alloy/Shaders/Features/CarPaint.cginc"
#include "Assets/Alloy/Shaders/Features/Decal.cginc"
#include "Assets/Alloy/Shaders/Features/Detail.cginc"
#include "Assets/Alloy/Shaders/Features/DirectionalBlend.cginc"
#include "Assets/Alloy/Shaders/Features/Dissolve.cginc"
#include "Assets/Alloy/Shaders/Features/Emission.cginc"
#include "Assets/Alloy/Shaders/Features/Emission2.cginc"
#include "Assets/Alloy/Shaders/Features/HeightmapBlend.cginc"
#include "Assets/Alloy/Shaders/Features/MainTextures.cginc"
#include "Assets/Alloy/Shaders/Features/OrientedTextures.cginc"
#include "Assets/Alloy/Shaders/Features/Parallax.cginc"
#include "Assets/Alloy/Shaders/Features/Rim.cginc"
#include "Assets/Alloy/Shaders/Features/Rim2.cginc"
#include "Assets/Alloy/Shaders/Features/SecondaryTextures.cginc"
#include "Assets/Alloy/Shaders/Features/SpeedTree.cginc"
#include "Assets/Alloy/Shaders/Features/TeamColor.cginc"
#include "Assets/Alloy/Shaders/Features/TransitionBlend.cginc"

#include "HLSLSupport.cginc"
#include "UnityCG.cginc"
#include "UnityInstancing.cginc"
#include "UnityStandardBRDF.cginc"
#include "UnityStandardUtils.cginc"

#if !defined(A_UV2_ON) && (defined(DYNAMICLIGHTMAP_ON) || defined(UNITY_PASS_META))
    #define A_UV2_ON
#endif

#if defined(A_LIGHTING_OFF) || !(defined(UNITY_PASS_FORWARDBASE) || defined(UNITY_PASS_DEFERRED))
    #define A_GI_OFF
#endif

#if !defined(A_SCREEN_UV_ON) && defined(LOD_FADE_CROSSFADE)
    #define A_SCREEN_UV_ON
#endif

#ifdef A_GI_OFF
    #define A_GI_DATA(n)
#else
    #define A_GI_DATA(n) half4 giData : TEXCOORD##n;
#endif

#if !defined(A_SCREEN_UV_ON) && (defined(UNITY_PASS_SHADOWCASTER) || defined(UNITY_PASS_META))
    #define A_SURFACE_DATA_LITE

    #define A_VERTEX_DATA(A, B, C, D, E, F, G) \
        float4 texcoords    : TEXCOORD##A; \
        half4 color         : TEXCOORD##B; 
#else
    #define A_TANGENT_TO_WORLD_ON
    
    #define A_VERTEX_DATA(A, B, C, D, E, F, G) \
        float4 positionWorldAndViewDepth    : TEXCOORD##A; \
        float4 texcoords                    : TEXCOORD##B; \
        UNITY_FOG_COORDS_PACKED(C, half4) \
        half4 tangentToWorldAndScreenUv0    : TEXCOORD##D; \
        half4 tangentToWorldAndScreenUv1    : TEXCOORD##E; \
        half4 tangentToWorldAndScreenUv2    : TEXCOORD##F; \
        half4 color                         : TEXCOORD##G; 
#endif

/// Vertex input from the model data.
struct AVertex 
{
    float4 vertex : POSITION;
    float4 uv0 : TEXCOORD0;
    float4 uv1 : TEXCOORD1;
    half3 normal : NORMAL;
#ifdef A_UV2_ON
    float4 uv2 : TEXCOORD2;
#endif
#ifdef A_UV3_ON
    float4 uv3 : TEXCOORD3;
#endif
#ifdef A_TANGENT_TO_WORLD_ON
    half4 tangent : TANGENT;
#endif
    half4 color : COLOR;
    UNITY_INSTANCE_ID
};

#endif // A_FRAMEWORK_MODEL_CGINC
