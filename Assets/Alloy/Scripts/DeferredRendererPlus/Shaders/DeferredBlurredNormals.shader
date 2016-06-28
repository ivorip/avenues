// Alloy Physical Shader Framework
// Copyright 2013-2016 RUST LLC.
// http://www.alloy.rustltd.com/

Shader "Hidden/Alloy/Deferred Blurred Normals" {
Properties {
    _MainTex ("Render Input", 2D) = "white" {}
}
SubShader {
    ZTest Always Cull Off ZWrite Off Fog { Mode Off }

    CGINCLUDE
    #pragma target 3.0
    #pragma exclude_renderers gles

    #include "Assets/Alloy/Shaders/Framework/Utility.cginc"

    #include "UnityCG.cginc"
    #include "UnityDeferredLibrary.cginc"

    // Screen-space diffusion
    // cf http://www.iryoku.com/screen-space-subsurface-scattering
    // cf http://uaasoftware.com/xi/PDSS/diffuseShader.fx

    // blurWidth = 0.15
    // blurDepthDifferenceMultiplier = 100
    // distanceToProjectionWindow = 1 / tan(radians(FoV) / 2);
    // blurStepScale = blurWidth * distanceToProjectionWindow
    // blurDepthDifferenceScale = blurDepthDifferenceMultiplier * distanceToProjectionWindow

    /// Number of downsampling texture taps.
    #define A_NUM_DOWNSAMPLE_TAPS 4

    /// Downsampling texture coordinate offset directions.
    static const float2 A_DOWNSAMPLE_OFFSETS[A_NUM_DOWNSAMPLE_TAPS] = {
        float2(0.0f, 0.0f),
        float2(1.0f, 0.0f),
        float2(0.0f, 1.0f),
        float2(1.0f, 1.0f)
    };

    /// Number of blur texture taps.
    #define A_NUM_BLUR_TAPS 7

    /// Gaussian Distribution blur texture coordinate offsets.
    static const float A_BLUR_OFFSETS[A_NUM_BLUR_TAPS] = {
        0.0f, -3.0f,  -2.0f,  -1.0f,   1.0f,   2.0f,   3.0f
    };

    /// Gaussian Distribution blur sample weights.
    static const half A_BLUR_WEIGHTS[A_NUM_BLUR_TAPS] = {
        0.199471h,  0.0647588h, 0.120985h, 0.176033h, 0.176033h, 0.120985h, 0.0647588h
    };

    /// Number of upsampling texture taps.
    #define A_NUM_UPSAMPLE_TAPS 4

    /// Upsampling texture coordinate offset directions.
    static const float2 A_UPSAMPLE_OFFSETS[A_NUM_UPSAMPLE_TAPS] = {
        float2(0.0f, 1.0f),
        float2(1.0f, 0.0f),
        float2(-1.0f, 0.0f),
        float2(0.0f, -1.0f)
    };

    /// (X: blurStepScale, Y: blurDepthDifferenceScale).
    float2 _DeferredBlurredNormalsParams;
    
    // G-Buffer LAB (transmission in alpha).
    sampler2D _DeferredTransmissionBuffer;

    /// Pass source texture.
    sampler2D _MainTex;

    /// Pass source texture (X: 1 / width, Y: 1 / height, Z: width, W: height).
    float4 _MainTex_TexelSize;
    
    /// Downsamples the G-Buffer normals and depth to 1/2 resolution.
    /// @param  IN  Vertex input.
    /// @return     Downsampled image (XYZ: Normals, W: Nearest Depth).
    half4 aDownsample(
        v2f_img IN) 
    {
        half depth = 1.0h;
        half3 normal = 0.0h;

        UNITY_UNROLL
        for (int i = 1; i < A_NUM_DOWNSAMPLE_TAPS; i++) {
            float2 coord = A_DOWNSAMPLE_OFFSETS[i] * _MainTex_TexelSize.xy + IN.uv;
            float4 sampleUv = float4(coord, 0.0f, 0.0f);

            normal += 0.25h * (tex2Dlod(_MainTex, sampleUv).xyz * 2.0f - 1.0f);
            depth = min(depth, SAMPLE_DEPTH_TEXTURE_LOD(_CameraDepthTexture, sampleUv));
        }

        // Export unpacked normals and depth together for subsequent passes.
        return half4(normal, LinearEyeDepth(depth));
    }

    /// Blur the source image along the specified axis.
    /// @param  IN      Vertex input.
    /// @param  axis    Axis on which to blur.
    /// @return         (XYZ: Blurred Normals, W: Sharp Depth).
    half4 aBlurAxis(
        v2f_img IN, 
        float2 axis) 
    {
        // Gaussian Blur.
        half4 normalDepthM = tex2Dlod(_MainTex, float4(IN.uv, 0.0f, 0.0f));
        float scale = _DeferredBlurredNormalsParams.x / normalDepthM.w;
        float2 finalStep = scale * axis * _MainTex_TexelSize.xy;
        half3 output = A_BLUR_WEIGHTS[0] * normalDepthM.xyz;

        UNITY_UNROLL
        for (int i = 1; i < A_NUM_BLUR_TAPS; i++) {
            float2 coord = A_BLUR_OFFSETS[i] * finalStep + IN.uv;
            half4 normalDepth = tex2Dlod(_MainTex, float4(coord, 0.0f, 0.0f));
            half alpha = min(1.0f, _DeferredBlurredNormalsParams.y * abs(normalDepth.w - normalDepthM.w));

            // Lerp back to middle sample when blur sample crosses an edge.
            output += A_BLUR_WEIGHTS[i] * lerp(normalDepth.xyz, normalDepthM.xyz, alpha);
        }

        // Transfer original depth for subsequent passes.
        return half4(output, normalDepthM.w);
    }
    
    /// Upsamples the blurred normals.
    /// @param  IN  Vertex input.
    /// @return     Upsampled, packed blurred normals.
    half4 aUpsample(
        v2f_img IN) 
    {
        // Cross Bilateral Upsample filter.
        half4 output = 0.0h;
        half depth = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE_LOD(_CameraDepthTexture, float4(IN.uv, 0.0f, 0.0f)));
        
        UNITY_UNROLL
        for (int i = 0; i < A_NUM_UPSAMPLE_TAPS; i++) {
            float2 coord = A_UPSAMPLE_OFFSETS[i] * _MainTex_TexelSize.xy + IN.uv;
            half4 normalDepth = tex2Dlod(_MainTex, float4(coord, 0.0f, 0.0f));
              
            output.xyz += normalDepth.xyz / (abs(normalDepth.w - depth) + A_EPSILON);
        }

        // Normalize implicitly divides by total weight.
        output.xyz = normalize(output.xyz);

        // Pack normals and transmission for RGBA8 storage.
        output.xyz = output.xyz * 0.5h + 0.5h;
        output.w = tex2D(_DeferredTransmissionBuffer, IN.uv).a;
        return output;
    }
    ENDCG
        
    Pass {
        CGPROGRAM
        #pragma vertex vert_img
        #pragma fragment frag

        half4 frag(v2f_img IN) : SV_Target {
            return aDownsample(IN);
        }
        ENDCG
    }
        
    Pass {
        CGPROGRAM
        #pragma vertex vert_img
        #pragma fragment frag
            
        half4 frag(v2f_img IN) : SV_Target {
            return aBlurAxis(IN, float2(1.0f, 0.0f));
        }
        ENDCG
    }
        
    Pass {
        CGPROGRAM
        #pragma vertex vert_img
        #pragma fragment frag

        half4 frag(v2f_img IN) : SV_Target {
            return aBlurAxis(IN, float2(0.0f, 1.0f));
        }
        ENDCG
    }
        
    Pass {
        CGPROGRAM
        #pragma vertex vert_img
        #pragma fragment frag

        half4 frag(v2f_img IN) : SV_Target {
            return aUpsample(IN);
        }
        ENDCG
    }
}
}