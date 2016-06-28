// Alloy Physical Shader Framework
// Copyright 2013-2016 RUST LLC.
// http://www.alloy.rustltd.com/

using UnityEngine;

public static class AlloyUtils {
    public static float IntensityToLumens(float intensity) {
        return Mathf.GammaToLinearSpace(intensity) * Mathf.PI * 100.0f;
    }

    public static float LumensToIntensity(float lumens) {
        return Mathf.LinearToGammaSpace(lumens / (100.0f * Mathf.PI));
    }
}
