// Alloy Physical Shader Framework
// Copyright 2013-2016 RUST LLC.
// http://www.alloy.rustltd.com/

using UnityEditor;
using UnityEngine;
using System.Collections;

public static class AlloyLightCreator {

    [MenuItem("GameObject/Light/Point Light")]
    private static void CreateSphereAreaLight() {
        var go = new GameObject();
        
        Undo.RegisterCreatedObjectUndo(go, "Created alloy sphere light");
        go.name = "AlloySphereLight";
        
        var light = go.AddComponent<Light>();
        light.type = LightType.Point;
        
        go.AddComponent<AlloyAreaLight>();
        go.transform.position = SceneView.lastActiveSceneView.pivot;

        Selection.activeGameObject = go;
    }

    [MenuItem("GameObject/Light/Spotlight")]
    private static void CreateSpotSphereAreaLight() {
        var go = new GameObject();
        
        Undo.RegisterCreatedObjectUndo(go, "Created alloy sphere light");
        go.name = "AlloySplotLight";
        
        var light = go.AddComponent<Light>();
        light.type = LightType.Spot;
        
        go.AddComponent<AlloyAreaLight>();
        go.transform.position = SceneView.lastActiveSceneView.pivot;
        
        Selection.activeGameObject = go;
    }

    [MenuItem("GameObject/Light/Directional Light")]
    private static void CreateDirectionalLight()
    {
        var go = new GameObject();
        go.transform.position = SceneView.lastActiveSceneView.pivot;

        Undo.RegisterCreatedObjectUndo(go, "Created alloy directional light");
        go.name = "AlloyDirectionalLight";

        var light = go.AddComponent<Light>();
        light.type = LightType.Directional;

        go.AddComponent<AlloyAreaLight>();

        Selection.activeGameObject = go;
    }

    [MenuItem("GameObject/Light/Area Light")]
    private static void CreateAreaLight()
    {
        var go = new GameObject();
        go.transform.position = SceneView.lastActiveSceneView.pivot;

        Undo.RegisterCreatedObjectUndo(go, "Created area light");
        go.name = "Area Light";

        var light = go.AddComponent<Light>();
        light.type = LightType.Area;

        Selection.activeGameObject = go;
    }
}
