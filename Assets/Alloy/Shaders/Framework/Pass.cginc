// Alloy Physical Shader Framework
// Copyright 2013-2016 RUST LLC.
// http://www.alloy.rustltd.com/

///////////////////////////////////////////////////////////////////////////////
/// @file Pass.cginc
/// @brief Passes uber-header.
///////////////////////////////////////////////////////////////////////////////

#ifndef A_FRAMEWORK_PASS_CGINC
#define A_FRAMEWORK_PASS_CGINC

#include "Assets/Alloy/Shaders/Framework/Brdf.cginc"
#include "Assets/Alloy/Shaders/Framework/Lighting.cginc"
#include "Assets/Alloy/Shaders/Framework/Surface.cginc"
#include "Assets/Alloy/Shaders/Framework/Tessellation.cginc"
#include "Assets/Alloy/Shaders/Framework/Unity.cginc"
#include "Assets/Alloy/Shaders/Framework/Utility.cginc"
#include "Assets/Alloy/Shaders/Framework/Model.cginc"

#include "HLSLSupport.cginc"
#include "Lighting.cginc"
#include "UnityCG.cginc"
#include "UnityGlobalIllumination.cginc"
#include "UnityInstancing.cginc"
#include "UnityLightingCommon.cginc"
#include "UnityShaderVariables.cginc"
#include "UnityStandardBRDF.cginc"
#include "UnityStandardUtils.cginc"

#ifdef A_TWO_SIDED_ON
    #define A_FACING_TYPE ,half facingSign : VFACE
    #define A_FACING_SIGN facingSign
#else
    #define A_FACING_TYPE
    #define A_FACING_SIGN 1.0h
#endif

// NOTE: Custom macro to save calculations and remove dependency on o.pos!
#ifdef A_LIGHTING_OFF
    #define A_TRANSFER_SHADOW(a)
#elif !defined(SHADOWS_SCREEN) || defined(UNITY_NO_SCREENSPACE_SHADOWS)
    #define A_TRANSFER_SHADOW(a) TRANSFER_SHADOW(a)
#else
    #define A_COMPUTE_VERTEX_SCREEN_UV
    #define A_TRANSFER_SHADOW(a) a._ShadowCoord = unityShadowCoord4(o.tangentToWorldAndScreenUv0.w, o.tangentToWorldAndScreenUv1.w, 0.0, o.tangentToWorldAndScreenUv2.w);
#endif

#ifndef A_SURFACE_SHADER_OFF
    /// Transfers the per-vertex surface data to the pixel shader.
    /// @param[in]  v       Vertex input data.
    /// @param[out] o       Vertex to fragment transfer data.
    /// @param[out] opos    Clip space position.
    void aTransferVertex(
        AVertex v,
        out AVertexToFragment o, 
        out float4 opos)
    {
        UNITY_INITIALIZE_OUTPUT(AVertexToFragment, o);
    #ifndef A_INSTANCING_OFF
        UNITY_SETUP_INSTANCE_ID(v);
        UNITY_TRANSFER_INSTANCE_ID(v, o);
    #endif

        aVertex(v);

        // Gamma-space vertex color, unless the shader modifies it.
        o.color = v.color;
        o.texcoords.xy = v.uv0.xy;
        o.texcoords.zw = v.uv1.xy;

        opos = 0.0f;

    #ifndef A_SURFACE_DATA_LITE
        UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

        opos = UnityObjectToClipPos(v.vertex.xyz);
        o.positionWorldAndViewDepth.xyz = mul(unity_ObjectToWorld, v.vertex).xyz;
        o.fogCoord.yzw = UnityWorldSpaceViewDir(o.positionWorldAndViewDepth.xyz);

        #ifdef A_VIEW_DEPTH_ON
            COMPUTE_EYEDEPTH(o.positionWorldAndViewDepth.w);
        #endif
    
        float3 normalWorld = UnityObjectToWorldNormal(v.normal);
    
        #ifdef A_TANGENT_TO_WORLD_ON
            float4 tangentWorld = float4(UnityObjectToWorldDir(v.tangent.xyz), v.tangent.w);
            float3x3 tangentToWorld = CreateTangentToWorldPerVertex(normalWorld, tangentWorld.xyz, tangentWorld.w);

            o.tangentToWorldAndScreenUv0.xyz = tangentToWorld[0];
            o.tangentToWorldAndScreenUv1.xyz = tangentToWorld[1];
            o.tangentToWorldAndScreenUv2.xyz = tangentToWorld[2];
        #else
            o.tangentToWorldAndScreenUv0.xyz = 0.0h;
            o.tangentToWorldAndScreenUv1.xyz = 0.0h;
            o.tangentToWorldAndScreenUv2.xyz = normalWorld;
        #endif
    
        #if defined(A_SCREEN_UV_ON) || defined(A_COMPUTE_VERTEX_SCREEN_UV)
            float4 projPos = ComputeScreenPos(opos);

            o.tangentToWorldAndScreenUv0.w = projPos.x;
            o.tangentToWorldAndScreenUv1.w = projPos.y;
            o.tangentToWorldAndScreenUv2.w = projPos.w;
        #else
            o.tangentToWorldAndScreenUv0.w = 0.0h;
            o.tangentToWorldAndScreenUv1.w = 0.0h;
            o.tangentToWorldAndScreenUv2.w = 1.0h;
        #endif
    #endif
    }

    /// Create a ASurface populated with data from the vertex shader.
    /// @param  i           Vertex to fragment transfer data.
    /// @param  facingSign  Sign of front/back facing direction.
    /// @return             Initialized surface data object.
    ASurface aForwardSurface(
        AVertexToFragment i,
        half facingSign)
    {
        ASurface s = aCreateSurface();

    #ifndef A_INSTANCING_OFF
        UNITY_SETUP_INSTANCE_ID(i);
    #endif
        s.uv01 = i.texcoords;
        s.vertexColor = i.color;
        s.facingSign = facingSign;

    #ifndef A_SURFACE_DATA_LITE
        #ifdef A_SCREEN_UV_ON
            s.screenUv.x = i.tangentToWorldAndScreenUv0.w;
            s.screenUv.y = i.tangentToWorldAndScreenUv1.w;
            s.screenUv.xy /= i.tangentToWorldAndScreenUv2.w;
        #endif
        #ifdef LOD_FADE_CROSSFADE
            half2 projUV = s.screenUv.xy * _ScreenParams.xy * 0.25h;
            projUV.y = frac(projUV.y) * 0.0625h /* 1/16 */ + unity_LODFade.y; // quantized lod fade by 16 levels
            clip(tex2D(_DitherMaskLOD2D, projUV).a - 0.5f);
        #endif

        s.positionWorld = i.positionWorldAndViewDepth.xyz;
        s.viewDirWorld = normalize(i.fogCoord.yzw);

        #ifdef A_VIEW_DEPTH_ON
            s.viewDepth = i.positionWorldAndViewDepth.w;
        #endif
        #ifdef A_TWO_SIDED_ON
            i.tangentToWorldAndScreenUv2.xyz *= s.facingSign;
        #endif
        #ifdef A_TANGENT_TO_WORLD_ON
            half3 t = i.tangentToWorldAndScreenUv0.xyz;
            half3 b = i.tangentToWorldAndScreenUv1.xyz;
            half3 n = i.tangentToWorldAndScreenUv2.xyz;
        
            #if UNITY_TANGENT_ORTHONORMALIZE
                n = normalize(n);
    
                // ortho-normalize Tangent
                t = normalize (t - n * dot(t, n));

                // recalculate Binormal
                half3 newB = cross(n, t);
                b = newB * sign (dot (newB, b));
            #endif

            s.tangentToWorld = half3x3(t, b, n);
        #endif
        #ifdef A_VIEW_VECTOR_TANGENT_ON
            // IMPORTANT: Calculated in the pixel shader to fix distortion issues in POM!
            s.viewDirTangent = normalize(mul(s.tangentToWorld, s.viewDirWorld));
        #endif

        // Give these sane defaults in case the surface shader doesn't set them.
        s.normalWorld = normalize(i.tangentToWorldAndScreenUv2.xyz);
        s.vertexNormalWorld = s.normalWorld;
        aUpdateViewData(s);
    #endif

        // Runs the shader and lighting type's surface code.
        aSetDefaultBaseUv(s);
        aPreSurface(s);
        aSurface(s);
        aUpdateBrdfData(s);
        return s;
    }

    /// Transfers the per-vertex lightmapping or SH data to the fragment shader.
    /// @param  v   Vertex input data.
    /// @param  i   Vertex to fragment transfer data.
    void aVertexGi(
        AVertex v,
        inout AVertexToFragment i)
    {
    #ifndef A_GI_OFF
        #ifndef LIGHTMAP_OFF
            i.giData.xy = v.uv1.xy * unity_LightmapST.xy + unity_LightmapST.zw;
            i.giData.zw = 0.0h;
        #elif UNITY_SHOULD_SAMPLE_SH
            half3 normalWorld = i.tangentToWorldAndScreenUv2.xyz;

            // Add approximated illumination from non-important point lights
            #ifdef VERTEXLIGHT_ON
                i.giData.rgb = aShade4PointLights(i.positionWorldAndViewDepth.xyz, normalWorld);
            #endif

            i.giData.rgb = ShadeSHPerVertex(normalWorld, i.giData.rgb);
        #endif

        #ifdef DYNAMICLIGHTMAP_ON
            i.giData.zw = v.uv2.xy * unity_DynamicLightmapST.xy + unity_DynamicLightmapST.zw;
        #endif
    #endif
    }

    /// Populates a UnityGI descriptor in the fragment shader.
    /// @param  s       Material surface data.
    /// @param  i       Vertex to fragment transfer data.
    /// @param  shadow  Forward Base directional light shadow.
    /// @return         Initialized UnityGI descriptor.
    UnityGI aFragmentGi(
        ASurface s,
        AVertexToFragment i,
        half shadow)
    {
        UnityGI gi;
        UNITY_INITIALIZE_OUTPUT(UnityGI, gi);

    #ifndef A_GI_OFF
        UnityGIInput d;

        UNITY_INITIALIZE_OUTPUT(UnityGIInput, d);
        d.worldPos = s.positionWorld;
        d.worldViewDir = -s.viewDirWorld; // ???
        d.atten = shadow;

        #if defined(LIGHTMAP_ON) || defined(DYNAMICLIGHTMAP_ON)
            d.ambient = 0;
            d.lightmapUV = i.giData;
        #else
            d.ambient = i.giData.rgb;
            d.lightmapUV = 0;
        #endif

        d.boxMax[0] = unity_SpecCube0_BoxMax;
        d.boxMin[0] = unity_SpecCube0_BoxMin;
        d.probePosition[0] = unity_SpecCube0_ProbePosition;
        d.probeHDR[0] = unity_SpecCube0_HDR;

        d.boxMax[1] = unity_SpecCube1_BoxMax;
        d.boxMin[1] = unity_SpecCube1_BoxMin;
        d.probePosition[1] = unity_SpecCube1_ProbePosition;
        d.probeHDR[1] = unity_SpecCube1_HDR;

        // Pass 1.0 for occlusion so we can apply it later in indirect().  
        gi = UnityGI_Base(d, 1.0h, s.ambientNormalWorld);

        #ifndef A_REFLECTION_PROBES_OFF
            Unity_GlossyEnvironmentData g;

            g.reflUVW = s.reflectionVectorWorld;
            g.roughness = s.roughness;
            gi.indirect.specular = UnityGI_IndirectSpecular(d, 1.0h, s.normalWorld, g);
        #endif
    #endif

        return gi;
    }

    /// Final processing of the forward output.
    /// @param  s       Material surface data.
    /// @param  i       Vertex to fragment transfer data.
    /// @param  color   Lighting + Emission + Fog + etc.
    /// @return         Final HDR output color with alpha opacity.
    half4 aOutputForward(
        ASurface s,
        AVertexToFragment i,
        half3 color)
    {
        half4 col;
        col.rgb = color;

    #ifdef A_ALPHA_BLENDING_ON
        col.a = s.opacity;
    #else
        UNITY_OPAQUE_ALPHA(col.a);
    #endif
    #if defined(FOG_LINEAR) || defined(FOG_EXP) || defined(FOG_EXP2)
        s.fogCoord = i.fogCoord;
    #else
        s.fogCoord = 0.0f;
    #endif
        aFinalColor(s, col);
        return aHdrClamp(col);
    }

    /// Final processing of the deferred output.
    /// @param[in]  i                   Vertex to fragment transfer data.
    /// @param[in]  facingSign          Sign of front/back facing direction.
    /// @param[out] outDiffuseOcclusion RGB: albedo, A: specular occlusion.
    /// @param[out] outSpecSmoothness   RGB: f0, A: 1-roughness.
    /// @param[out] outNormal           RGB: packed normal, A: 1-scattering mask.
    /// @param[out] outEmission         RGB: emission, A: 1-transmission.
    void aOutputDeferred(    
        AVertexToFragment i,
        half facingSign,
        out half4 outDiffuseOcclusion,
        out half4 outSpecSmoothness,
        out half4 outNormal,
        out half4 outEmission)
    {
        ASurface s = aForwardSurface(i, facingSign);
        UnityGI gi = aFragmentGi(s, i, 1.0h);

        outEmission = aUnityOutputDeferred(s, gi, outDiffuseOcclusion, outSpecSmoothness, outNormal);
    
    #ifndef UNITY_HDR_ON
        outEmission.rgb = exp2(-outEmission.rgb);
    #endif

        aFinalGbuffer(s, outDiffuseOcclusion, outSpecSmoothness, outNormal, outEmission);
    }
#endif

#endif // A_FRAMEWORK_PASS_CGINC
