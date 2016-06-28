// Alloy Physical Shader Framework
// Copyright 2013-2016 RUST LLC.
// http://www.alloy.rustltd.com/

Shader "Alloy/Nature/Terrain/nSplat TriPlanar" {
Properties {
    // Triplanar Properties
    _TriplanarProperties ("'Triplanar' {Section:{126, 41, 41}}", Float) = 0
    _TriplanarBlendSharpness ("'Sharpness' {Min:1, Max:50}", Float) = 2

    // Distant Terrain Properties
    _DistantTerrainProperties("'Terrain' {Section:{126, 66, 41}}", Float) = 0
    _FadeDist("'Fade Distance' {Min:0}", Float) = 500.0
    _FadeRange("'Fade Range' {Min:1}", Float) = 100.0
    _DistantSpecularity("'Specularity' {Min:0, Max:1}", Float) = 0.5
    _DistantSpecularTint("'Specular Tint' {Min:0, Max:1}", Float) = 0
    _DistantRoughness("'Roughness' {Min:0, Max:1}", Float) = 0.5
    
    // Detail Properties
    [Toggle(_DETAIL_ON)] 
    _DetailT ("'Detail' {Feature:{57, 126, 41}}", Float) = 0
    [Enum(Mul, 0, MulX2, 1)] 
    _DetailMode ("'Color Mode' {Dropdown:{Mul:{}, MulX2:{}}}", Float) = 0
    _DetailAlbedoMap ("'Color(RGB)' {Visualize:{RGB}}", 2D) = "white" {}
    _DetailAlbedoMapUV ("UV Set", Float) = 0
    _DetailMaterialMap ("'AO(G) Variance(A)' {Visualize:{G, A}, Parent:_DetailAlbedoMap}", 2D) = "white" {}
    _DetailNormalMap ("'Normals' {Visualize:{NRM}, Parent:_DetailAlbedoMap}", 2D) = "bump" {}
    _DetailWeight ("'Weight' {Min:0, Max:1}", Float) = 1
    _DetailOcclusion ("'Occlusion Strength' {Min:0, Max:1}", Float) = 1
    _DetailNormalMapScale ("'Normal Strength' {}", Float) = 1
    
    // set by terrain engine
    _Control ("Control (RGBA)", 2D) = "red" {}
    _Splat3 ("Layer 3 (A)", 2D) = "white" {}
    _Splat2 ("Layer 2 (B)", 2D) = "white" {}
    _Splat1 ("Layer 1 (G)", 2D) = "white" {}
    _Splat0 ("Layer 0 (R)", 2D) = "white" {}
    _Normal3 ("Normal 3 (A)", 2D) = "bump" {}
    _Normal2 ("Normal 2 (B)", 2D) = "bump" {}
    _Normal1 ("Normal 1 (G)", 2D) = "bump" {}
    _Normal0 ("Normal 0 (R)", 2D) = "bump" {}
    _Metallic0 ("Metallic 0", Range(0.0, 1.0)) = 0.0	
    _Metallic1 ("Metallic 1", Range(0.0, 1.0)) = 0.0	
    _Metallic2 ("Metallic 2", Range(0.0, 1.0)) = 0.0	
    _Metallic3 ("Metallic 3", Range(0.0, 1.0)) = 0.0
    
    // used in fallback on old cards & base map
    _MainTex ("BaseMap (RGB)", 2D) = "white" {}
    _Color ("Main Color", Color) = (1,1,1,1)
}

CGINCLUDE
    #define A_TRIPLANAR
    #define A_TERRAIN_NSPLAT
ENDCG

SubShader {
    Tags{
        "Queue" = "Geometry-100"
        "RenderType" = "Opaque"
    }

    Pass {
        Name "FORWARD" 
        Tags { "LightMode" = "ForwardBase" }

        CGPROGRAM
        #pragma target 3.0
        #pragma exclude_renderers gles
        
        #pragma shader_feature _DETAIL_ON
        #pragma multi_compile __ _TERRAIN_NORMAL_MAP
        
        #pragma multi_compile_fwdbase
        #pragma multi_compile_fog
            
        #pragma vertex aVertexShader
        #pragma fragment aFragmentShader
        
        #define UNITY_PASS_FORWARDBASE
        
        #include "Assets/Alloy/Shaders/Definitions/Terrain.cginc"
        #include "Assets/Alloy/Shaders/Passes/ForwardBase.cginc"

        ENDCG
    }
    
    Pass {
        Name "FORWARD_DELTA"
        Tags { "LightMode" = "ForwardAdd" }
        
        Blend One One
        ZWrite Off

        CGPROGRAM
        #pragma target 3.0
        #pragma exclude_renderers gles
        
        #pragma shader_feature _DETAIL_ON
        #pragma multi_compile __ _TERRAIN_NORMAL_MAP
        
        #pragma multi_compile_fwdadd_fullshadows
        #pragma multi_compile_fog
        //#pragma multi_compile_instancing
        
        #pragma vertex aVertexShader
        #pragma fragment aFragmentShader

        #define UNITY_PASS_FORWARDADD

        #include "Assets/Alloy/Shaders/Definitions/Terrain.cginc"
        #include "Assets/Alloy/Shaders/Passes/ForwardAdd.cginc"

        ENDCG
    }
    
    Pass {
        Name "SHADOWCASTER"
        Tags { "LightMode" = "ShadowCaster" }
        
        CGPROGRAM
        #pragma target 3.0
        #pragma exclude_renderers gles
        
        #pragma multi_compile_shadowcaster

        #pragma vertex aVertexShader
        #pragma fragment aFragmentShader
        
        #define UNITY_PASS_SHADOWCASTER
        
        #include "Assets/Alloy/Shaders/Definitions/Terrain.cginc"
        #include "Assets/Alloy/Shaders/Passes/Shadow.cginc"

        ENDCG
    }
    
    Pass {
        Name "DEFERRED"
        Tags { "LightMode" = "Deferred" }

        CGPROGRAM
        #pragma target 3.0
        #pragma exclude_renderers nomrt gles
        
        #pragma shader_feature _DETAIL_ON
        #pragma multi_compile __ _TERRAIN_NORMAL_MAP
                
        #pragma multi_compile ___ UNITY_HDR_ON
        #pragma multi_compile LIGHTMAP_OFF LIGHTMAP_ON
        #pragma multi_compile DIRLIGHTMAP_OFF DIRLIGHTMAP_COMBINED DIRLIGHTMAP_SEPARATE
        #pragma multi_compile DYNAMICLIGHTMAP_OFF DYNAMICLIGHTMAP_ON
        
        #pragma vertex aVertexShader
        #pragma fragment aFragmentShader
        
        #define UNITY_PASS_DEFERRED
        
        #include "Assets/Alloy/Shaders/Definitions/Terrain.cginc"
        #include "Assets/Alloy/Shaders/Passes/Deferred.cginc"

        ENDCG
    }
    
    Pass {
        Name "Meta"
        Tags { "LightMode" = "Meta" }

        Cull Off

        CGPROGRAM
        #pragma target 3.0
        #pragma exclude_renderers nomrt gles
        
        #pragma shader_feature _DETAIL_ON
        #pragma multi_compile __ _TERRAIN_NORMAL_MAP
                        
        #pragma vertex aVertexShader
        #pragma fragment aFragmentShader
        
        #define UNITY_PASS_META
        
        #include "Assets/Alloy/Shaders/Definitions/Terrain.cginc"
        #include "Assets/Alloy/Shaders/Passes/Meta.cginc"

        ENDCG
    }
}

Dependency "AddPassShader" = "Hidden/Alloy/Nature/Terrain/nSplat TriPlanar AddPass"
Dependency "BaseMapShader" = "Hidden/Alloy/Nature/Terrain/Distant"

Fallback "Hidden/Alloy/Nature/Terrain/Distant"
CustomEditor "AlloyFieldBasedEditor"
}
