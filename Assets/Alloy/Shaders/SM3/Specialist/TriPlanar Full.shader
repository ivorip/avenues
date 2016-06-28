// Alloy Physical Shader Framework
// Copyright 2013-2016 RUST LLC.
// http://www.alloy.rustltd.com/

Shader "Alloy/TriPlanar/Full" {
Properties {
    // Settings
    _Lightmapping ("'GI' {LightmapEmissionProperty:{}}", Float) = 1
    
    // Triplanar Properties
    _TriplanarProperties ("'Triplanar' {Section:{126, 41, 41}}", Float) = 0
    [KeywordEnum(Object, World)]
    _TriplanarMode ("'Mode' {Dropdown:{Object:{}, World:{}}}", Float) = 1
    _TriplanarBlendSharpness ("'Sharpness' {Min:1, Max:50}", Float) = 2
    
    // Primary Textures 
    _PrimaryTextures ("'Primary Textures' {Section:{126, 66, 41}}", Float) = 0
    _PrimaryColor ("'Tint' {}", Color) = (1,1,1,1)	
    _PrimaryMainTex ("'Base Color(RGB)' {Visualize:{RGB}}", 2D) = "white" {}
    _PrimaryMainTexVelocity ("Scroll", Vector) = (0,0,0,0) 
    _PrimaryMaterialMap ("'Metal(R) AO(G) Spec(B) Rough(A)' {Visualize:{R, G, B, A}, Parent:_PrimaryMainTex}", 2D) = "white" {}
    _PrimaryBumpMap ("'Normals' {Visualize:{NRM}, Parent:_PrimaryMainTex}", 2D) = "bump" {}
    _PrimaryColorVertexTint ("'Vertex Color Tint' {Min:0, Max:1}", Float) = 0
    _PrimaryMetallic ("'Metallic' {Min:0, Max:1}", Float) = 1
    _PrimarySpecularity ("'Specularity' {Min:0, Max:1}", Float) = 1
    _PrimaryRoughness ("'Roughness' {Min:0, Max:1}", Float) = 1
    _PrimaryOcclusion ("'Occlusion Strength' {Min:0, Max:1}", Float) = 1
    _PrimaryBumpScale ("'Normal Strength' {}", Float) = 1
    
    // Secondary Textures 
    [Toggle(_SECONDARY_TRIPLANAR_ON)] 
    _SecondaryTextures ("'Secondary Textures' {Feature:{126, 92, 41}}", Float) = 0
    _SecondaryColor ("'Tint' {}", Color) = (1,1,1,1)	
    _SecondaryMainTex ("'Base Color(RGB)' {Visualize:{RGB}}", 2D) = "white" {}
    _SecondaryMainTexVelocity ("Scroll", Vector) = (0,0,0,0) 
    _SecondaryMaterialMap ("'Metal(R) AO(G) Spec(B) Rough(A)' {Visualize:{R, G, B, A}, Parent:_SecondaryMainTex}", 2D) = "white" {}
    _SecondaryBumpMap ("'Normals' {Visualize:{NRM}, Parent:_SecondaryMainTex}", 2D) = "bump" {}
    _SecondaryColorVertexTint ("'Vertex Color Tint' {Min:0, Max:1}", Float) = 0
    _SecondaryMetallic ("'Metallic' {Min:0, Max:1}", Float) = 1
    _SecondarySpecularity ("'Specularity' {Min:0, Max:1}", Float) = 1
    _SecondaryRoughness ("'Roughness' {Min:0, Max:1}", Float) = 1
    _SecondaryOcclusion ("'Occlusion Strength' {Min:0, Max:1}", Float) = 1
    _SecondaryBumpScale ("'Normal Strength' {}", Float) = 1
    
    // Tertiary Textures 
    [Toggle(_TERTIARY_TRIPLANAR_ON)] 
    _TertiaryTextures ("'Tertiary Textures' {Feature:{126, 118, 41}}", Float) = 0
    _TertiaryColor ("'Tint' {}", Color) = (1,1,1,1)	
    _TertiaryMainTex ("'Base Color(RGB)' {Visualize:{RGB}}", 2D) = "white" {}
    _TertiaryMainTexVelocity ("Scroll", Vector) = (0,0,0,0) 
    _TertiaryMaterialMap ("'Metal(R) AO(G) Spec(B) Rough(A)' {Visualize:{R, G, B, A}, Parent:_TertiaryMainTex}", 2D) = "white" {}
    _TertiaryBumpMap ("'Normals' {Visualize:{NRM}, Parent:_TertiaryMainTex}", 2D) = "bump" {}
    _TertiaryColorVertexTint ("'Vertex Color Tint' {Min:0, Max:1}", Float) = 0
    _TertiaryMetallic ("'Metallic' {Min:0, Max:1}", Float) = 1
    _TertiarySpecularity ("'Specularity' {Min:0, Max:1}", Float) = 1
    _TertiaryRoughness ("'Roughness' {Min:0, Max:1}", Float) = 1
    _TertiaryOcclusion ("'Occlusion Strength' {Min:0, Max:1}", Float) = 1
    _TertiaryBumpScale ("'Normal Strength' {}", Float) = 1

    // Rim Emission Properties 
    [Toggle(_RIM_ON)] 
    _Rim ("'Rim Emission' {Feature:{41, 125, 126}}", Float) = 0
    [HDR]
    _RimColor ("'Tint' {}", Color) = (1,1,1)
    [Gamma]
    _RimWeight ("'Weight' {Min:0, Max:1}", Float) = 1
    [Gamma]
    _RimBias ("'Fill' {Min:0, Max:1}", Float) = 0
    _RimPower ("'Falloff' {Min:0.01}", Float) = 4
}

CGINCLUDE
    #define A_SPLAT_MATERIAL_FULL
ENDCG

SubShader {
    Tags { 
        "Queue" = "Geometry" 
        "RenderType" = "Opaque"
    }
    LOD 400

    Pass {
        Name "FORWARD" 
        Tags { "LightMode" = "ForwardBase" }

        CGPROGRAM
        #pragma target 3.0
        #pragma exclude_renderers gles
        
        #pragma shader_feature _TRIPLANARMODE_OBJECT _TRIPLANARMODE_WORLD
        #pragma shader_feature _SECONDARY_TRIPLANAR_ON
        #pragma shader_feature _TERTIARY_TRIPLANAR_ON
        #pragma shader_feature _RIM_ON
        
        #pragma multi_compile_fwdbase
        #pragma multi_compile_fog
        //#pragma multi_compile_instancing
            
        #pragma vertex aVertexShader
        #pragma fragment aFragmentShader
        
        #define UNITY_PASS_FORWARDBASE
        
        #include "Assets/Alloy/Shaders/Definitions/TriPlanar.cginc"
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
                
        #pragma shader_feature _TRIPLANARMODE_OBJECT _TRIPLANARMODE_WORLD
        #pragma shader_feature _SECONDARY_TRIPLANAR_ON
        #pragma shader_feature _TERTIARY_TRIPLANAR_ON
        
        #pragma multi_compile_fwdadd_fullshadows
        #pragma multi_compile_fog
        //#pragma multi_compile_instancing
        
        #pragma vertex aVertexShader
        #pragma fragment aFragmentShader

        #define UNITY_PASS_FORWARDADD

        #include "Assets/Alloy/Shaders/Definitions/TriPlanar.cginc"
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
        //#pragma multi_compile_instancing

        #pragma vertex aVertexShader
        #pragma fragment aFragmentShader
        
        #define UNITY_PASS_SHADOWCASTER
        
        #include "Assets/Alloy/Shaders/Definitions/TriPlanar.cginc"
        #include "Assets/Alloy/Shaders/Passes/Shadow.cginc"

        ENDCG
    }
    
    Pass {
        Name "DEFERRED"
        Tags { "LightMode" = "Deferred" }

        CGPROGRAM
        #pragma target 3.0
        #pragma exclude_renderers nomrt gles
        
        #pragma shader_feature _TRIPLANARMODE_OBJECT _TRIPLANARMODE_WORLD
        #pragma shader_feature _SECONDARY_TRIPLANAR_ON
        #pragma shader_feature _TERTIARY_TRIPLANAR_ON
        #pragma shader_feature _RIM_ON
        
        #pragma multi_compile ___ UNITY_HDR_ON
        #pragma multi_compile LIGHTMAP_OFF LIGHTMAP_ON
        #pragma multi_compile DIRLIGHTMAP_OFF DIRLIGHTMAP_COMBINED DIRLIGHTMAP_SEPARATE
        #pragma multi_compile DYNAMICLIGHTMAP_OFF DYNAMICLIGHTMAP_ON
        //#pragma multi_compile_instancing
        
        #pragma vertex aVertexShader
        #pragma fragment aFragmentShader
        
        #define UNITY_PASS_DEFERRED
        
        #include "Assets/Alloy/Shaders/Definitions/TriPlanar.cginc"
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
        
        #pragma shader_feature _TRIPLANARMODE_OBJECT _TRIPLANARMODE_WORLD
        #pragma shader_feature _SECONDARY_TRIPLANAR_ON
        #pragma shader_feature _TERTIARY_TRIPLANAR_ON
        
        #pragma vertex aVertexShader
        #pragma fragment aFragmentShader
        
        #define UNITY_PASS_META
        
        #include "Assets/Alloy/Shaders/Definitions/TriPlanar.cginc"
        #include "Assets/Alloy/Shaders/Passes/Meta.cginc"

        ENDCG
    }
}

FallBack "VertexLit"
CustomEditor "AlloyFieldBasedEditor"
}
