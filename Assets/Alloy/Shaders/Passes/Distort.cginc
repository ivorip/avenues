// Alloy Physical Shader Framework
// Copyright 2013-2016 RUST LLC.
// http://www.alloy.rustltd.com/

/////////////////////////////////////////////////////////////////////////////////
/// @file Distort.cginc
/// @brief Distort pass inputs and entry points.
/////////////////////////////////////////////////////////////////////////////////

#ifndef A_PASSES_DISTORT_CGINC
#define A_PASSES_DISTORT_CGINC

#ifndef A_DISTORT_TEXTURE
    #define A_DISTORT_TEXTURE _GrabTexture
#endif

#ifndef A_DISTORT_TEXELSIZE
    #define A_DISTORT_TEXELSIZE _GrabTexture_TexelSize
#endif

struct AVertexToFragment {
    A_VERTEX_DATA(0, 1, 2, 3, 4, 5, 6)
    float3 normalProjection : TEXCOORD7;
    float4 grabUv : TEXCOORD8;
    UNITY_INSTANCE_ID
    UNITY_VERTEX_OUTPUT_STEREO
};

#include "Assets/Alloy/Shaders/Framework/Pass.cginc"

void aVertexShader(
    AVertex v,
    out AVertexToFragment o,
    out float4 opos : SV_POSITION)
{
    aTransferVertex(v, o, opos);
    o.grabUv = ComputeGrabScreenPos(opos);
    o.normalProjection = mul((float3x3)UNITY_MATRIX_MVP, v.normal);
    UNITY_TRANSFER_FOG(o, opos);
}

float _DistortWeight;
float _DistortIntensity;
float _DistortGeoWeight;
sampler2D A_DISTORT_TEXTURE;
float4 A_DISTORT_TEXELSIZE;

half4 aFragmentShader(
    AVertexToFragment i
    A_FACING_TYPE) : SV_Target
{
    ASurface s = aForwardSurface(i, A_FACING_SIGN);
    
    // Combine normals.
    half3 combinedNormals = BlendNormals(s.normalTangent, normalize(i.normalProjection));
    combinedNormals = lerp(s.normalTangent, combinedNormals, _DistortGeoWeight);
    
    // Calculate perturbed coordinates.
    float4 grabUv = i.grabUv;
    float2 offset = combinedNormals.xy * A_DISTORT_TEXELSIZE.xy;
    grabUv.xy += offset * (grabUv.z * _DistortWeight * _DistortIntensity);
    
    // Sample and combine textures.
    half3 refr = tex2Dproj(A_DISTORT_TEXTURE, UNITY_PROJ_COORD(grabUv)).rgb;
    return aOutputForward(s, i, s.baseColor * refr);
}

#endif // A_PASSES_DISTORT_CGINC
