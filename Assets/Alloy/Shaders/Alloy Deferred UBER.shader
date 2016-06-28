// Alloy Physical Shader Framework
// Copyright 2013-2016 RUST LLC.
// http://www.alloy.rustltd.com/

Shader "Hidden/Alloy/Deferred Shading UBER" {
Properties {
    _LightTexture0 ("", any) = "" {}
    _LightTextureB0 ("", 2D) = "" {}
    _ShadowMapTexture ("", any) = "" {}
    _SrcBlend ("", Float) = 1
    _DstBlend ("", Float) = 1
}

CGINCLUDE
    // UBER - Standard Shader Ultra integration
    // https://www.assetstore.unity3d.com/en/#!/content/39959

    // When using both features check UBER_StandardConfig.cginc to configure Gbuffer channels
    // by default translucency is passed in diffuse (A) gbuffer and self-shadows are passed in normal (A) channel
    //
    // NOTE that you're not supposed to use Standard shader with occlusion data together with UBER translucency in deferred, because Standard Shader writes occlusion velue in GBUFFER0 alpha as the translucency does !
    //
    #define UBER_TRANSLUCENCY_DEFERRED
    #define UBER_POM_SELF_SHADOWS_DEFERRED
    //
    // you can gently turn it up (like 0.3, 0.5) if you find front facing geometry overbrighten (esp. for point lights),
    // but suppresion can negate albedo for high translucency values (they can become badly black)
    #define TRANSLUCENCY_SUPPRESS_DIFFUSECOLOR 0.0
    
    //
    // Do NOT select - currently in Alloy3 lightcolor.a is reserved
    //#define UBER_TRANSLUCENCY_PER_LIGHT_ALPHA
    //
ENDCG

SubShader {

// Pass 1: Lighting pass
//  LDR case - Lighting encoded into a subtractive ARGB8 buffer
//  HDR case - Lighting additively blended into floating point buffer
Pass {
    ZWrite Off
    Blend [_SrcBlend] [_DstBlend]

CGPROGRAM
#pragma target 3.0

#pragma vertex vert_deferred
#pragma fragment frag
#pragma multi_compile_lightpass
#pragma multi_compile ___ UNITY_HDR_ON

#pragma exclude_renderers nomrt

#include "Assets/Alloy/Shaders/Lighting/Standard.cginc"
#include "Assets/Alloy/Shaders/Framework/Deferred.cginc"

#if defined(UBER_POM_SELF_SHADOWS_DEFERRED)
    float4		_WorldSpaceLightPosCustom;
#endif

// UBER - Translucency
#if defined(UBER_TRANSLUCENCY_DEFERRED)
    sampler2D _UBERTranslucencyBuffer; // copied by command buffer from emission.a (_CameraGBufferTexture3.a which is not accessible here as it acts as target for lighting pass - we read/write into the same buffer)
    half4		_TranslucencyColor;
    half4		_TranslucencyColor2;
    half4		_TranslucencyColor3;
    half4		_TranslucencyColor4;
    half		_TranslucencyStrength;
    half		_TranslucencyConstant;
    half		_TranslucencyNormalOffset;
    half		_TranslucencyExponent;
    half		_TranslucencyOcclusion;
    half		_TranslucencyPointLightDirectionality;
    half		_TranslucencySuppressRealtimeShadows;

    half Translucency(half3 normalWorld, ADirect d, half3 eyeVec) {
        #ifdef USING_DIRECTIONAL_LIGHT
            half tLitDot = aDotClamp((d.direction + normalWorld * _TranslucencyNormalOffset), eyeVec);
        #else
            float3 lightDirectional = normalize(_LightPos.xyz - _WorldSpaceCameraPos.xyz);
            half3 light_dir = normalize(lerp(d.direction, lightDirectional, _TranslucencyPointLightDirectionality));
            half tLitDot = aDotClamp((light_dir + normalWorld * _TranslucencyNormalOffset), eyeVec);
        #endif
        
        tLitDot = exp2(-_TranslucencyExponent * (1 - tLitDot)) * _TranslucencyStrength;

        half translucencyAtten = (tLitDot + _TranslucencyConstant);
        
//		#if defined(UBER_TRANSLUCENCY_PER_LIGHT_ALPHA)
//			translucencyAtten *= _LightColor.a;
//		#endif
        
        return translucencyAtten;
    }
#endif
        
half4 CalculateLight (unity_v2f_deferred i)
{    
    ASurface s = aDeferredSurface(i);
    ADirect d = aDeferredDirect(s);
    
    half4 color = 0.0h;
    
#if defined(UBER_POM_SELF_SHADOWS_DEFERRED)
    d.shadow = (abs(dot((_LightDir.xyz + _WorldSpaceLightPosCustom.xyz), float3(1, 1, 1))) < 0.01) ? min(d.shadow, 1.0h - s.materialType) : d.shadow;
#endif	
    
#if defined(UBER_TRANSLUCENCY_DEFERRED)	
    // 0..255 (HDR) (0..63 for LDR - TODO - change all 255 occurences below to 63)
    half translucency_thickness = 1 - tex2D(_UBERTranslucencyBuffer, s.screenUv).r;
    int lightIndex = frac(translucency_thickness * 255.9999) * 4;
    half3 TranslucencyColor = _TranslucencyColor.rgb;
    
    TranslucencyColor = (lightIndex >= 1) ? _TranslucencyColor2.rgb : TranslucencyColor;
    TranslucencyColor = (lightIndex >= 2) ? _TranslucencyColor3.rgb : TranslucencyColor;
    TranslucencyColor = (lightIndex >= 3) ? _TranslucencyColor4.rgb : TranslucencyColor;
    
    half3 TL = Translucency(s.normalWorld, d, normalize(s.positionWorld - _WorldSpaceCameraPos)) * TranslucencyColor.rgb;
    
    TL *= s.albedo;
    TL *= saturate(translucency_thickness - 1.0 / 255);
    s.albedo *= saturate(1 - max(max(TL.r, TL.g), TL.b) * TRANSLUCENCY_SUPPRESS_DIFFUSECOLOR);
    d.shadow = lerp(d.shadow, 1, aDotClamp(TL, 1) * _TranslucencySuppressRealtimeShadows);

    color.rgb += d.shadow * TL * d.color.rgb;
#endif
    
    color.rgb += aDirect(d, s);
    return aHdrClamp(color);
}

#ifdef UNITY_HDR_ON
half4
#else
fixed4
#endif
frag (unity_v2f_deferred i) : SV_Target
{
    half4 c = CalculateLight(i);
    #ifdef UNITY_HDR_ON
    return c;
    #else
    return exp2(-c);
    #endif
}

ENDCG
}


// Pass 2: Final decode pass.
// Used only with HDR off, to decode the logarithmic buffer into the main RT
Pass {
    ZTest Always Cull Off ZWrite Off
    Stencil {
        ref [_StencilNonBackground]
        readmask [_StencilNonBackground]
        // Normally just comp would be sufficient, but there's a bug and only front face stencil state is set (case 583207)
        compback equal
        compfront equal
    }

CGPROGRAM
#pragma target 3.0
#pragma vertex vert
#pragma fragment frag
#pragma exclude_renderers nomrt

#include "UnityCG.cginc"

sampler2D _LightBuffer;
struct v2f {
	float4 vertex : SV_POSITION;
	float2 texcoord : TEXCOORD0;
};

v2f vert (float3 vertex : POSITION, float2 texcoord : TEXCOORD0)
{
	v2f o;
	o.vertex = UnityObjectToClipPos(vertex);
	o.texcoord = texcoord.xy;
	return o;
}

fixed4 frag (v2f i) : SV_Target
{
	return -log2(tex2D(_LightBuffer, i.texcoord));
}
ENDCG 
}

}
Fallback Off
}
