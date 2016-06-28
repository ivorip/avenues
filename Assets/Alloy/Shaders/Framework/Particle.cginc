// Alloy Physical Shader Framework
// Copyright 2013-2016 RUST LLC.
// http://www.alloy.rustltd.com/

/////////////////////////////////////////////////////////////////////////////////
/// @file Particle.cginc
/// @brief Particles uber-header.
/////////////////////////////////////////////////////////////////////////////////

#ifndef A_FRAMEWORK_PARTICLE_CGINC
#define A_FRAMEWORK_PARTICLE_CGINC

#include "Assets/Alloy/Shaders/Framework/Utility.cginc"

#include "UnityCG.cginc"
#include "UnityInstancing.cginc"
#include "UnityLightingCommon.cginc"
#include "UnityStandardUtils.cginc"
#include "UnityShaderVariables.cginc"
            
struct AVertex {
    float4 vertex : POSITION;
    float4 color : COLOR;
    float2 texcoord : TEXCOORD0;
#if defined(_RIM_FADE_ON) || defined(A_PARTICLE_LIGHTING_ON)
    half3 normal : NORMAL;
#endif
    UNITY_INSTANCE_ID
};

struct AVertexToFragment {
    float4 vertex : SV_POSITION;
    float4 color : COLOR;
    float2 uv_MainTex : TEXCOORD0;
#ifdef _PARTICLE_EFFECTS_ON
    float2 uv_ParticleEffectMask1 : TEXCOORD1;
    float2 uv_ParticleEffectMask2 : TEXCOORD2;
#endif
    UNITY_FOG_COORDS(3)
#if defined(SOFTPARTICLES_ON) || defined(_DISTANCE_FADE_ON)
    float4 projPos : TEXCOORD4;
#endif
#if defined(_RIM_FADE_ON) || defined(A_PARTICLE_LIGHTING_ON)
    half3 normalWorld : TEXCOORD5;
    half4 viewDirWorld : TEXCOORD6;
#endif
#if defined(A_PARTICLE_LIGHTING_ON)
    float4 positionWorld : TEXCOORD7;
    half3 ambient : TEXCOORD8;
#endif
    UNITY_INSTANCE_ID
};
        
sampler2D_float _CameraDepthTexture;

half4 _TintColor;
A_SAMPLER2D(_MainTex);	
half _TintWeight;
float _InvFade;

#ifdef _PARTICLE_EFFECTS_ON
    A_SAMPLER2D(_ParticleEffectMask1);
    A_SAMPLER2D(_ParticleEffectMask2);
#endif

#ifdef _RIM_FADE_ON
    half _RimFadeWeight; // Expects linear-space values
    half _RimFadePower;
#endif

float _DistanceFadeNearFadeCutoff;
float _DistanceFadeRange;

AVertexToFragment aVertexShader(
    AVertex v)
{
    AVertexToFragment o;
    UNITY_INITIALIZE_OUTPUT(AVertexToFragment, o);               
    UNITY_SETUP_INSTANCE_ID(v);
    UNITY_TRANSFER_INSTANCE_ID(v, o);
    
    o.vertex = UnityObjectToClipPos(v.vertex.xyz);
#if defined(SOFTPARTICLES_ON) || defined(_DISTANCE_FADE_ON)
    o.projPos = ComputeScreenPos (o.vertex);
    COMPUTE_EYEDEPTH(o.projPos.z);
#endif
    o.color = v.color;
    
#ifndef A_VERTEX_COLOR_DEGAMMA_OFF
    o.color.rgb = GammaToLinearSpace(o.color.rgb);
#endif
    
    o.uv_MainTex = A_TRANSFORM_SCROLL_SPIN(_MainTex, v.texcoord);
    
#ifdef _PARTICLE_EFFECTS_ON
    o.uv_ParticleEffectMask1 = A_TRANSFORM_SCROLL_SPIN(_ParticleEffectMask1, v.texcoord);
    o.uv_ParticleEffectMask2 = A_TRANSFORM_SCROLL_SPIN(_ParticleEffectMask2, v.texcoord);
#endif

#if defined(_RIM_FADE_ON) || defined(A_PARTICLE_LIGHTING_ON)
    float4 positionWorld = mul(unity_ObjectToWorld, v.vertex);
    o.normalWorld = UnityObjectToWorldNormal(v.normal);
    o.viewDirWorld.xyz = UnityWorldSpaceViewDir(positionWorld.xyz);
#endif
    
#ifdef A_PARTICLE_LIGHTING_ON	
    // 1 Directional, 4 Point lights, and Light probes.
    o.positionWorld = positionWorld;
    o.ambient = _LightColor0.rgb * aDotClamp(_WorldSpaceLightPos0.xyz, o.normalWorld);
    o.ambient += aShade4PointLights(o.positionWorld.xyz, o.normalWorld);
    o.ambient += ShadeSHPerVertex(o.normalWorld, o.ambient);
#endif
    
    UNITY_TRANSFER_FOG(o,o.vertex);
    return o;
}

/// Controls how the particle is faded out based on scene intersection, rim, 
/// and camera distance.
half aFadeParticle(
    AVertexToFragment i)
{
    half fade = 1.0h;

    UNITY_SETUP_INSTANCE_ID(i);

#ifdef SOFTPARTICLES_ON
    float sceneZ = DECODE_EYEDEPTH(SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture, UNITY_PROJ_COORD(i.projPos)));
    float partZ = i.projPos.z;
    fade = saturate(_InvFade * (sceneZ - partZ));
#endif
#ifdef _DISTANCE_FADE_ON
    // Alpha clip.
    // cf http://wiki.unity3d.com/index.php?title=AlphaClipsafe
    fade *= saturate((i.projPos.z - _DistanceFadeNearFadeCutoff) / _DistanceFadeRange);
#endif
#ifdef _RIM_FADE_ON
    half3 normal = normalize(i.normalWorld);
    half3 viewDir = normalize(i.viewDirWorld.xyz);
    half NdotV = abs(dot(normal, viewDir));
    half bias = 1.0h - _RimFadeWeight;
    fade *= aRimLight(bias, _RimFadePower, 1.0h - NdotV);
#endif
    
    return fade;
}

/// Applies transforming effects mask textures to the particle.
half4 aParticleEffects(
    AVertexToFragment i)
{
    half4 color = tex2D(_MainTex, i.uv_MainTex);
    color.rgb *= _TintWeight;

#ifdef _PARTICLE_EFFECTS_ON
    color *= tex2D(_ParticleEffectMask1, i.uv_ParticleEffectMask1);
    color *= tex2D(_ParticleEffectMask2, i.uv_ParticleEffectMask2);
#endif
#ifdef A_PARTICLE_LIGHTING_ON	
    color.rgb *= ShadeSHPerPixel(i.normalWorld, i.ambient, i.positionWorld);
#endif

    return color;
}

#endif // A_FRAMEWORK_PARTICLE_CGINC
