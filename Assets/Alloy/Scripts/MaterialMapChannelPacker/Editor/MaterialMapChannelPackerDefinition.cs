// Alloy Physical Shader Framework
// Copyright 2013-2016 RUST LLC.
// http://www.alloy.rustltd.com/

using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using UnityEditor;
using UnityEngine;


namespace Alloy {

    [Serializable]
    public class BaseTextureChannelMapping {
        public string Title;
        public string HelpText;
        public Color BackgroundColor;
    }

    [Flags]
    public enum MapChannel {
        R = 1,
        G = 2,
        B = 4,
        A = 8
    };

    [Serializable]
    public class MapTextureChannelMapping : BaseTextureChannelMapping {
        public bool CanInvert;
        public bool InvertByDefault;

        [EnumFlags] public MapChannel InputChannels;
        [EnumFlags] public MapChannel OutputChannels;
        public bool RoughnessCorrect;
        public bool OutputVariance;
        public bool HideChannel;

        public TextureValueChannelMode DefaultMode;
        

        public int MainIndex {
            get {
                if (OutputChannels.HasFlag(MapChannel.R)) {
                    return 0;
                }
                if (OutputChannels.HasFlag(MapChannel.G)) {
                    return 1;
                }
                if (OutputChannels.HasFlag(MapChannel.B)) {
                    return 2;
                }
                if (OutputChannels.HasFlag(MapChannel.A)) {
                    return 3;
                }

                Debug.LogError(" Packed map does not have any output channels" );
                return 0;
            }
        }

        private IEnumerable<int> GetIndices(MapChannel channel) {
            if (channel.HasFlag(MapChannel.R)) {
                yield return 0;
            }
            if (channel.HasFlag(MapChannel.G)) {
                yield return 1;
            }
            if (channel.HasFlag(MapChannel.B)) {
                yield return 2;
            }
            if (channel.HasFlag(MapChannel.A)) {
                yield return 3;
            }
        }

        public IEnumerable<int> InputIndices {
            get { return GetIndices(InputChannels); }
        }

        public IEnumerable<int> OutputIndices {
            get {return GetIndices(OutputChannels);}
        }

        private string GetChannelString(MapChannel channel) {
            StringBuilder sb = new StringBuilder(5);
            if (channel.HasFlag(MapChannel.R)) {
                sb.Append('R');
            }
            if (channel.HasFlag(MapChannel.G)) {
                sb.Append('G');
            }
            if (channel.HasFlag(MapChannel.B)) {
                sb.Append('B');
            }
            if (channel.HasFlag(MapChannel.A)) {
                sb.Append('A');
            }

            return sb.ToString();
        }

        public string InputString { get { return GetChannelString(InputChannels); } }
        public string OutputString { get { return GetChannelString(OutputChannels); } }
        public bool UseNormals { get { return OutputVariance || RoughnessCorrect; } }
    }


    [Serializable] public class NormalMapChannelTextureChannelMapping : BaseTextureChannelMapping {}
    [Serializable]public class TextureImportConfig {
        public bool IsLinear;
        public FilterMode Filter = FilterMode.Trilinear;
        public bool DefaultCompressed;
    }

    [CustomEditor(typeof (PackedMapDefinition))]
    public class PackedMapDefintionEdtior : Editor {
        public override void OnInspectorGUI() {
            serializedObject.Update();
            
            EditorGUILayout.PropertyField(serializedObject.FindProperty("Title"));
            EditorGUILayout.PropertyField(serializedObject.FindProperty("Suffix"));
            EditorGUILayout.PropertyField(serializedObject.FindProperty("ImportSettings"), true);

            GUILayout.Space(20.0f);

            var map = target as PackedMapDefinition;
            var channels = serializedObject.FindProperty("Channels");

            //int rI = 0, gI = 0, bI = 0, aI = 0;
            int rO = 0, gO = 0, bO = 0, aO = 0;

            int del = -1;

            for (int i = 0; i < channels.arraySize; i++) {
                var ser = channels.GetArrayElementAtIndex(i);
                var channel = map.Channels[i];
                var outputs = channel.OutputChannels;

                if (GUILayout.Button("", "OL Minus")) {
                    del = i;
                }

                EditorGUILayout.PropertyField(ser.FindPropertyRelative("Title"));
                EditorGUILayout.PropertyField(ser.FindPropertyRelative("HelpText"));
                EditorGUILayout.PropertyField(ser.FindPropertyRelative("BackgroundColor"));

                if (!channel.RoughnessCorrect) {
                    EditorGUILayout.PropertyField(ser.FindPropertyRelative("OutputVariance"));
                }

                if (!channel.OutputVariance) {
                    EditorGUILayout.PropertyField(ser.FindPropertyRelative("RoughnessCorrect"));
                }

                EditorGUILayout.PropertyField(ser.FindPropertyRelative("HideChannel"));

                EditorGUILayout.PropertyField(ser.FindPropertyRelative("CanInvert"));

                if (channel.CanInvert) {
                    EditorGUILayout.PropertyField(ser.FindPropertyRelative("InvertByDefault"));
                }

                EditorGUILayout.PropertyField(ser.FindPropertyRelative("InputChannels"));
                EditorGUILayout.PropertyField(ser.FindPropertyRelative("OutputChannels"));

                EditorGUILayout.PropertyField(ser.FindPropertyRelative("DefaultMode"));

                if (outputs.HasFlag(MapChannel.R)) {
                    rO++;
                }

                if (outputs.HasFlag(MapChannel.G)) {
                    gO++;
                }

                if (outputs.HasFlag(MapChannel.B)) {
                    bO++;
                }

                if (outputs.HasFlag(MapChannel.A)) {
                    aO++;
                }
            }

            if (rO == 0 || gO == 0 || bO == 0 || aO == 0) {
                EditorGUILayout.HelpBox("Missing output channel!", MessageType.Error);
            }

            if (rO > 1 || gO > 1 || bO > 1 || aO > 1) {
                EditorGUILayout.HelpBox("Output channel is doubly written!", MessageType.Error);
            }

            if (del != -1) {
                channels.DeleteArrayElementAtIndex(del);
            }

            if (GUILayout.Button("", "OL Plus")) {
                channels.InsertArrayElementAtIndex(channels.arraySize);
            }
            
            GUILayout.Space(10.0f);

            if (map.Channels.Any(channel => channel.UseNormals)) {
                GUILayout.Label("Packed map uses normals");
            }

            serializedObject.ApplyModifiedProperties();
        }
    }

    public class MaterialMapChannelPackerDefinition : ScriptableObject {
        public List<PackedMapDefinition> PackedMaps;



        public PackedMapDefinition PackedPack { get { return PackedMaps[0]; } }
        public PackedMapDefinition DetailPack { get { return PackedMaps[1]; } }
        public PackedMapDefinition TerrainPack { get { return PackedMaps[2]; } }


        [Header("Global settings")]
        public NormalMapChannelTextureChannelMapping NRMChannel = new NormalMapChannelTextureChannelMapping();

        [Space(15.0f)]
        public string VarianceText;
        public string AutoRegenerateText;

        public bool IsPackedMap(string path) {
	        for (int i = 0; i < PackedMaps.Count; i++) {
		        var map = PackedMaps[i];
		        if (path.EndsWith(map.Suffix, StringComparison.InvariantCultureIgnoreCase)) {
			        return true;
		        }
	        }

	        return false;
        }
    }
}