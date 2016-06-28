// Alloy Physical Shader Framework
// Copyright 2013-2016 RUST LLC.
// http://www.alloy.rustltd.com/

///////////////////////////////////////////////////////////////////////////////
/// @file SpeedTreeBillboard.cginc
/// @brief SpeedTree Billboard model inputs and outputs.
///////////////////////////////////////////////////////////////////////////////

#ifndef A_MODELS_SPEED_TREE_BILLBOARD_CGINC
#define A_MODELS_SPEED_TREE_BILLBOARD_CGINC

#define A_UV2_ON

#ifndef A_VERTEX_COLOR_BLEND_WEIGHTS
    #define A_VERTEX_COLOR_BLEND_WEIGHTS
#endif

#define ENABLE_WIND
#define SPEEDTREE_Y_UP

#ifdef GEOM_TYPE_BRANCH_DETAIL
    #define GEOM_TYPE_BRANCH
#endif

#include "Assets/Alloy/Shaders/Framework/Model.cginc"
#include "SpeedTreeVertex.cginc"

CBUFFER_START(UnityBillboardPerCamera)
	uniform float3 unity_BillboardNormal;
	uniform float3 unity_BillboardTangent;
	uniform float4 unity_BillboardCameraParams;
	#define unity_BillboardCameraPosition (unity_BillboardCameraParams.xyz)
	#define unity_BillboardCameraXZAngle (unity_BillboardCameraParams.w)
CBUFFER_END

CBUFFER_START(UnityBillboardPerBatch)
	uniform float4 unity_BillboardInfo; // x: num of billboard slices; y: 1.0f / (delta angle between slices)
	uniform float4 unity_BillboardSize; // x: width; y: height; z: bottom
	uniform float4 unity_BillboardImageTexCoords[16];
CBUFFER_END

void aVertex(
    inout AVertex v)
{
    // assume no scaling & rotation
    float3 worldPos = v.vertex.xyz + float3(unity_ObjectToWorld[0].w, unity_ObjectToWorld[1].w, unity_ObjectToWorld[2].w);

#ifdef BILLBOARD_FACE_CAMERA_POS
    float3 eyeVec = normalize(unity_BillboardCameraPosition - worldPos);
    float3 billboardTangent = normalize(float3(-eyeVec.z, 0, eyeVec.x));			// cross(eyeVec, {0,1,0})
    float3 billboardNormal = float3(billboardTangent.z, 0, -billboardTangent.x);	// cross({0,1,0},billboardTangent)
    float3 angle = atan2(billboardNormal.z, billboardNormal.x);						// signed angle between billboardNormal to {0,0,1}
    angle += angle < 0 ? 2 * UNITY_PI : 0;
#else
    float3 billboardTangent = unity_BillboardTangent;
    float3 billboardNormal = unity_BillboardNormal;
    float angle = unity_BillboardCameraXZAngle;
#endif

    float widthScale = v.uv1.x;
    float heightScale = v.uv1.y;
    float rotation = v.uv1.z;

    float2 percent = v.uv0.xy;
    float3 billboardPos = (percent.x - 0.5f) * unity_BillboardSize.x * widthScale * billboardTangent;
    billboardPos.y += (percent.y * unity_BillboardSize.y + unity_BillboardSize.z) * heightScale;

#ifdef ENABLE_WIND
    if (_WindQuality * _WindEnabled > 0)
        billboardPos = GlobalWind(billboardPos, worldPos, true, _ST_WindVector.xyz, v.uv1.w);
#endif

    v.vertex.xyz += billboardPos;
    v.vertex.w = 1.0f;
    v.normal = billboardNormal.xyz;

#ifdef A_TANGENT_TO_WORLD_ON
    v.tangent = float4(billboardTangent.xyz, -1);
#endif

    float slices = unity_BillboardInfo.x;
    float invDelta = unity_BillboardInfo.y;
    angle += rotation;

    float imageIndex = fmod(floor(angle * invDelta + 0.5f), slices);
    float4 imageTexCoords = unity_BillboardImageTexCoords[imageIndex];

    if (imageTexCoords.w < 0) {
        v.uv0.xy = imageTexCoords.xy - imageTexCoords.zw * percent.yx;
    }
    else {
        v.uv0.xy = imageTexCoords.xy + imageTexCoords.zw * percent;
    }

#ifdef EFFECT_HUE_VARIATION
    float hueVariationAmount = frac(worldPos.x + worldPos.y + worldPos.z);
    v.color.b = saturate(hueVariationAmount * _HueVariation.a);
#endif
}

void aFinalColor(
    ASurface s,
    inout half4 color)
{
    UNITY_APPLY_FOG(s.fogCoord, color);
}

void aFinalGbuffer(
    ASurface s,
    inout half4 diffuse,
    inout half4 specSmoothness,
    inout half4 normal,
    inout half4 emission)
{

}

#endif // A_MODELS_SPEED_TREE_BILLBOARD_CGINC
