// Alloy Physical Shader Framework
// Copyright 2013-2016 RUST LLC.
// http://www.alloy.rustltd.com/

using System;
using Alloy;
using UnityEditor;
using UnityEngine;


public class EnumFlagsAttribute : PropertyAttribute {
}


[CustomPropertyDrawer(typeof (EnumFlagsAttribute))]
public class ChannelDrawer : PropertyDrawer {
    public override void OnGUI(Rect position, SerializedProperty property, GUIContent label) {
        EditorGUI.BeginProperty(position, label, property);

        EditorGUI.BeginChangeCheck();
        int index = EditorGUI.MaskField(position, label, property.intValue, property.enumDisplayNames);

        if (EditorGUI.EndChangeCheck()) {
            property.intValue = index;
        }

        EditorGUI.EndProperty();
    }
}

public static class EnumExtension {
    public static bool HasFlag(this Enum keys, Enum flag) {
        int keysVal = Convert.ToInt32(keys);
        int flagVal = Convert.ToInt32(flag);

        return (keysVal & flagVal) == flagVal;
    }
}