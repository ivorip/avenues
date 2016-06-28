// Alloy Physical Shader Framework
// Copyright 2013-2016 RUST LLC.
// http://www.alloy.rustltd.com/

/////////////////////////////////////////////////////////////////////////////////
/// @file Deferred.cginc
/// @brief Deferred shader uber-header.
/////////////////////////////////////////////////////////////////////////////////

#ifndef A_FRAMEWORK_DEFERRED_CGINC
#define A_FRAMEWORK_DEFERRED_CGINC

#include "Assets/Alloy/Shaders/Config.cginc"
#include "Assets/Alloy/Shaders/Framework/Direct.cginc"
#include "Assets/Alloy/Shaders/Framework/Lighting.cginc"
#include "Assets/Alloy/Shaders/Framework/Surface.cginc"
#include "Assets/Alloy/Shaders/Framework/Utility.cginc"

#include "HLSLSupport.cginc"
#include "UnityCG.cginc"
#include "UnityPBSLighting.cginc"
#include "UnityStandardBRDF.cginc"
#include "UnityStandardUtils.cginc"
#include "UnityDeferredLibrary.cginc"

sampler2D _CameraGBufferTexture0;
sampler2D _CameraGBufferTexture1;
sampler2D _CameraGBufferTexture2;

/// Creates a surface description from a Unity G-Buffer.
/// @param[in,out] i    Unity deferred vertex format.
/// @return             Material surface data.
ASurface aDeferredSurface(
    inout unity_v2f_deferred i)
{
    i.ray = i.ray * (_ProjectionParams.z / i.ray.z);

    // Read depth and reconstruct world position.
    float2 uv = i.uv.xy / i.uv.w;
    float depth = Linear01Depth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, uv));
    float4 vpos = float4(i.ray * depth, 1.0f);

    // Convert G-Buffer to surface.
    ASurface s = aCreateSurface();
    half4 diffuse = tex2D(_CameraGBufferTexture0, uv);
    half4 specularSmoothness = tex2D(_CameraGBufferTexture1, uv);
    half4 normal = tex2D(_CameraGBufferTexture2, uv);

    s.screenUv = uv;
    s.viewDepth = vpos.z;
    s.positionWorld = mul(unity_CameraToWorld, vpos).xyz;
    s.viewDirWorld = normalize(UnityWorldSpaceViewDir(s.positionWorld));

    // Standard.
    s.albedo = diffuse.rgb;
    s.specularOcclusion = diffuse.a;
    s.f0 = specularSmoothness.rgb;
    s.roughness = 1.0h - specularSmoothness.a;
    s.normalWorld = normalize(normal.xyz * 2.0h - 1.0h);
    s.materialType = normal.w;
    s.beckmannRoughness = aLinearToBeckmannRoughness(s.roughness);
    aUpdateViewData(s);
    aGbufferSurface(s);
    return s;
}

/// Creates a direct description from Unity light parameters.
/// @param  s   Material surface data.
/// @return     Direct description data.
ADirect aDeferredDirect(
    ASurface s)
{
    ADirect d = aCreateDirect();
    float fadeDist = UnityDeferredComputeFadeDistance(s.positionWorld, s.viewDepth);
    float4 lightCoord = 0.0f;
    float3 lightVector = 0.0f;
    half3 lightAxis = 0.0h;
    half range = 1.0h;

    d.color = _LightColor.rgb;
    	
#ifndef DIRECTIONAL
    lightCoord = mul(unity_WorldToLight, float4(s.positionWorld, 1.0f));
#endif

#if defined(DIRECTIONAL) || defined(DIRECTIONAL_COOKIE)
    lightVector = -_LightDir.xyz;
    d.shadow = UnityDeferredComputeShadow(s.positionWorld, fadeDist, s.screenUv);
        
    #if !defined(ALLOY_SUPPORT_REDLIGHTS) && defined(DIRECTIONAL_COOKIE)
        aLightCookie(d, tex2Dbias(_LightTexture0, float4(lightCoord.xy, 0, -8)));
    #endif
#elif defined(POINT) || defined(POINT_COOKIE) || defined(SPOT)
    lightVector = _LightPos.xyz - s.positionWorld;
    lightAxis = normalize(unity_WorldToLight[1].xyz);
    range = rsqrt(_LightPos.w); // _LightPos.w = 1/r*r

    #if defined(SPOT)
        // negative bias because http://aras-p.info/blog/2010/01/07/screenspace-vs-mip-mapping/
        half4 cookie = tex2Dbias(_LightTexture0, float4(lightCoord.xy / lightCoord.w, 0, -8));
        
        cookie.a *= (lightCoord.w < 0.0f);
        aLightCookie(d, cookie);
        d.shadow = UnityDeferredComputeShadow(s.positionWorld, fadeDist, s.screenUv);
    #elif defined(POINT) || defined(POINT_COOKIE)
        d.shadow = UnityDeferredComputeShadow(-lightVector, fadeDist, s.screenUv);
                
        #if defined (POINT_COOKIE)
            aLightCookie(d, texCUBEbias(_LightTexture0, float4(lightCoord.xyz, -8)));
        #endif //POINT_COOKIE
    #endif //POINT || POINT_COOKIE

    A_UNITY_ATTENUATION(d, _LightTextureB0, lightVector, _LightPos.w)
#endif

#if !(defined(ALLOY_SUPPORT_REDLIGHTS) && defined(DIRECTIONAL_COOKIE))
    aAreaLight(d, s, _LightColor, lightAxis, lightVector, range);
#else
    d.direction = lightVector;
    d.color *= redLightFunctionLegacy(_LightTexture0, s.positionWorld, s.normalWorld, s.viewDirWorld, d.direction);
    aDirectionalLight(d, s);
#endif

    return d;
}

#endif // A_FRAMEWORK_DEFERRED_CGINC
