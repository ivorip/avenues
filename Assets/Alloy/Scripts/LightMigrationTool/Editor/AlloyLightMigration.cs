// Alloy Physical Shader Framework
// Copyright 2013-2016 RUST LLC.
// http://www.alloy.rustltd.com/

using System;
using UnityEditor;
using UnityEngine;

public class AlloyLightMigration : EditorWindow {
    [MenuItem("Window/Alloy/Light Migration Tool", false, 1)]
    private static void OpenWindow() {
        GetWindow<AlloyLightMigration>(true, "Convert Point/Spot lights to Alloy area lights...", true);
    }
    
    private void OnGUI() {
        GUILayout.BeginHorizontal();
        GUILayout.FlexibleSpace();
        
        GUILayout.BeginVertical();
        GUILayout.FlexibleSpace();
        
        bool isButtonClicked = GUILayout.Button("Migrate lights", EditorStyles.toolbarButton, GUILayout.Width(120.0f),
                                                GUILayout.Height(70.0f));
        
        GUILayout.FlexibleSpace();
        GUILayout.EndVertical();
        
        GUILayout.FlexibleSpace();
        GUILayout.EndHorizontal();
        
        if (isButtonClicked) {
            var lights = Resources.FindObjectsOfTypeAll<Light>();
            var lightsLength = lights.Length;
            
            for (int i = 0; i < lightsLength; i++) {
                var light = lights[i];
                
                EditorUtility.DisplayProgressBar(
                    "Converting lights...",
                    string.Format("{0} / {1} converted.", i, lightsLength),
                    i / (lightsLength - 1.0f));
                

                // Skip Unity baked Area Lights.
                if (light.type == LightType.Area) {
                    continue;
                }
                
                //Prefab, skip
                if (EditorUtility.IsPersistent(light)) {
                    continue;
                }

                AlloyAreaLight area = light.GetComponent<AlloyAreaLight>();

                // Skip if it is already and area light.
                if (area == null) {
                    Undo.RecordObject(light.gameObject, "Convert to area light");
                    area = Undo.AddComponent<AlloyAreaLight>(light.gameObject);
                }

                Undo.RecordObject(light, "Set light cookie");
                area.UpdateBinding();
            }

            EditorUtility.ClearProgressBar();
        }
    }
}