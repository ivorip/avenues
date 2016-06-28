// Alloy Physical Shader Framework
// Copyright 2013-2016 RUST LLC.
// http://www.alloy.rustltd.com/

using UnityEngine;
using UnityEditor;

public static class AlloyGUI  {
    public static void Vector2Field(SerializedProperty prop, string label, bool xy = true) {
        SerializedProperty xProp;
        SerializedProperty yProp;

        if (xy) {
            if (prop.propertyType == SerializedPropertyType.Color) {
                xProp = prop.FindPropertyRelative("r");
                yProp = prop.FindPropertyRelative("g");
            }
            else {
                xProp = prop.FindPropertyRelative("x");
                yProp = prop.FindPropertyRelative("y");
            }
        }
        else {
            if (prop.propertyType == SerializedPropertyType.Color) {
                xProp = prop.FindPropertyRelative("b");
                yProp = prop.FindPropertyRelative("a");
            }
            else {
                xProp = prop.FindPropertyRelative("z");
                yProp = prop.FindPropertyRelative("w");
            }
        }

        float old = EditorGUIUtility.labelWidth;
        EditorGUIUtility.labelWidth = 50.0f;

        EditorGUILayout.BeginHorizontal();

        GUILayout.Label(label, GUILayout.Width(50.0f));

        EditorGUIUtility.labelWidth = 20.0f;
        EditorGUILayout.PropertyField(xProp, new GUIContent("x"), GUILayout.Width(60.0f));
        EditorGUILayout.PropertyField(yProp, new GUIContent("y"), GUILayout.Width(60.0f));

        EditorGUILayout.EndHorizontal();

        EditorGUIUtility.labelWidth = old;
    }



}
