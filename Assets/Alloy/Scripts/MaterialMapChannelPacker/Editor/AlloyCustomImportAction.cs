// Alloy Physical Shader Framework
// Copyright 2013-2016 RUST LLC.
// http://www.alloy.rustltd.com/

using System;
using System.Linq;
using System.IO;
using System.Reflection;
using UnityEditor;
using UnityEngine;
using Object = UnityEngine.Object;

namespace Alloy {
    public class AlloyCustomImportAction : AssetPostprocessor {
        private delegate void OnAlloyImportFunc(AlloyCustomImportObject settings, Texture2D texture, string path);

        public static bool IsAlloyPackedMapPath(string path) {
            path = Path.GetFileNameWithoutExtension(path);
            return AlloyMaterialMapChannelPacker.GlobalDefinition.IsPackedMap(path);
        }

        //Make sure to generate PNG alongside .asset file if it doesn't exist yet
        private static void OnPostprocessAllAssets(string[] importedAssets, string[] deletedAssets, string[] movedAssets,
            string[] movedFromAssetPath) {
            foreach (var asset in importedAssets) {
                if (!IsAlloyPackedMapPath(asset)) {
                    continue;
                }

                if (File.Exists(asset.Replace(".asset", ".png"))) {
                    continue;
                }

                var settings = AssetDatabase.LoadAssetAtPath(asset, typeof (AlloyCustomImportObject)) as AlloyCustomImportObject;

                if (settings != null) {
                    settings.GenerateMap();
                }
            }
        }

        private void OnAlloyImport(Texture2D texture, OnAlloyImportFunc onImport) {
            // Check to see if this is an Alloy material that we need to edit.
            if (!IsAlloyPackedMapPath(assetPath)) {
                return;
            }

            // and if we've got saved settings/data for it...
            var textureName = Path.GetFileNameWithoutExtension(assetPath);
            var path = Path.Combine(Path.GetDirectoryName(assetPath), textureName) + ".asset";

            //Import can fail because of a variety of reasons, so make sure it's all good here
            if (!File.Exists(path)) {
                Debug.LogError(textureName + " has no post-processing data! Please contact Alloy support.");
                Selection.activeObject = texture;
                return;
            }

            var settings = AssetDatabase.LoadAssetAtPath(path, typeof (AlloyCustomImportObject)) as AlloyCustomImportObject;
            if (settings == null) {
                if (AlloyImporterSupervisor.IsFinalTry) {
                    Debug.LogError(textureName + " settings file is corrupt! Contact Alloy support");
                    return;
                }

                AlloyImporterSupervisor.OnFailedImport(path);
                return;
            }

            for (int i = 0; i < 4; ++i) {
                if (settings.SelectedModes[i] == TextureValueChannelMode.Texture && settings.GetTexture(i) == null) {
                    if (AlloyImporterSupervisor.IsFinalTry) {
                        Debug.LogError(textureName + " texture input " + (i + 1) + " can't be loaded!");
                        return;
                    }

                    AlloyImporterSupervisor.OnFailedImport(path);
                    return;
                }
            }

            if (!string.IsNullOrEmpty(settings.NormalGUID) && settings.NormalMapTexture == null) {
                if (AlloyImporterSupervisor.IsFinalTry) {
                    Debug.LogError(textureName + " normalmap texture input can't be loaded!");
                    return;
                }

                AlloyImporterSupervisor.OnFailedImport(path);
                return;
            }

            //If it's all good, do the importing action
            onImport(settings, texture, path);
        }

        private void ApplyImportSettings(AlloyCustomImportObject settings, Texture2D texture, string path) {
            var importer = assetImporter as TextureImporter;
            var size = settings.GetOutputSize();
            var def = settings.PackMode;

            if (def.ImportSettings.IsLinear) {
                importer.textureType = TextureImporterType.Advanced;
                importer.linearTexture = true;
            }

            importer.filterMode = def.ImportSettings.Filter;
            importer.mipmapEnabled = true;

            // They need the ability to set this themselves, but we should cap it.
            var nextPowerOfTwo = Mathf.NextPowerOfTwo((int) Mathf.Max(size.x, size.y));

            if (importer.maxTextureSize > nextPowerOfTwo) {
                importer.maxTextureSize = nextPowerOfTwo;
            }

            // Allow setting to uncompressed, else use compressed. Disallows any other format!
            if (def.ImportSettings.DefaultCompressed && importer.textureFormat != TextureImporterFormat.AutomaticTruecolor) {
                importer.textureFormat = TextureImporterFormat.AutomaticCompressed;
            }
        }

        private void HandleAutoRefresh() {
            var paths = AssetDatabase.GetAllAssetPaths();
            var texGUID = AssetDatabase.AssetPathToGUID(assetPath);

            foreach (var path in paths) {
                if (!IsAlloyPackedMapPath(path)) {
                    continue;
                }

                var setting = AssetDatabase.LoadAssetAtPath(path, typeof (AlloyCustomImportObject)) as AlloyCustomImportObject;
                if (setting == null || (texGUID != setting.NormalGUID && !setting.TexturesGUID.Contains(texGUID))) {
                    continue;
                }

                if (setting.DoAutoRegenerate) {
                    AssetDatabase.ImportAsset(path.Replace(".asset", ".png"));
                }
            }
        }

        private void OnPreprocessTexture() {
            OnAlloyImport(null, ApplyImportSettings);
            HandleAutoRefresh();
        }

        private void OnPostprocessTexture(Texture2D texture) {
            OnAlloyImport(texture, GeneratePackedMaterialMap);
        }

        public static void CreatePostProcessingInformation(string filePath, AlloyCustomImportObject settings) {
            settings.hideFlags = HideFlags.None;
            AssetDatabase.CreateAsset(settings, filePath);
        }

        /// <summary>
        /// Generates the packed material map for an object
        /// </summary>
        public static void GeneratePackedMaterialMap(AlloyCustomImportObject settings, Texture2D target, string filePath) {
            int mipmapCount = 1;


            Vector2 size = settings.GetOutputSize();
            int width = (int) size.x;
            int height = (int) size.y;

            // Pick output texture dimensions based on the largest input texture.
            for (int i = 0; i < 4; ++i) {
                if (settings.SelectedModes[i] != TextureValueChannelMode.Texture || settings.GetTexture(i) == null) {
                    continue;
                }

                mipmapCount = Math.Max(mipmapCount, GetMipmapCount(settings.GetTexture(i)));
            }

            bool doMips;
            if (settings.NormalMapTexture != null) {
                var tex = settings.NormalMapTexture;
                var count = GetMipmapCount(tex);

                mipmapCount = Math.Max(mipmapCount, count);
                doMips = true;
            } else {
                mipmapCount = 1;
                doMips = false;
            }

            if (target.width != width || target.height != height) {
                target.Resize(width, height);
            }

            if (!Mathf.IsPowerOfTwo(width) || !Mathf.IsPowerOfTwo(height)) {
                Debug.LogWarning(
                    "Alloy: Texture resolution is not power of 2; will have issues generating correct mip maps if custom sizing is specified in generated texture platform settings.");
            }
            var readableTextures = new Texture2D[settings.TexturesGUID.Length];

            for (int i = 0; i < settings.TexturesGUID.Length; ++i) {
                if (settings.SelectedModes[i] != TextureValueChannelMode.Texture) {
                    continue;
                }

                var settingsTex = settings.GetTexture(i);

                if (settingsTex == null) {
                    readableTextures[i] = null;
                } else {
                    readableTextures[i] = AlloyTextureReader.GetReadable(settingsTex, false);
                }
            }

            var normal = AlloyTextureReader.GetReadable(settings.NormalMapTexture, true);
			try {
				// Use renderer to sample mipmaps.
				for (int mipLevel = 0; mipLevel < mipmapCount; mipLevel++) {
					// CPU Method - more reliable/consistent across GPUs, but slower.
					if (mipmapCount > 1) {
						EditorUtility.DisplayProgressBar("Calculating Mip Maps...", "MipLevel " + mipLevel, (float) mipLevel / mipmapCount);
					}
					else {
						EditorUtility.DisplayProgressBar("Calculating Packed map...", "Packing...", 1.0f);
					}

					var normalCache = new AlloyTextureColorCache(normal, target);

					Profiler.BeginSample("Read");
					var texCache = readableTextures.Select(tex => new AlloyTextureColorCache(tex, target)).ToArray();
					Profiler.EndSample();


					AlloyPackerCompositor.CompositeMips(target, settings, texCache, normalCache, mipLevel);
				}
			} finally {
				EditorUtility.ClearProgressBar();
			}
			foreach (var texture in readableTextures) {
                Object.DestroyImmediate(texture);
            }

            Object.DestroyImmediate(normal);

            int maxResolution = 0;

            settings.Width = width;
            settings.Height = height;

            settings.MaxResolution = maxResolution;
            EditorUtility.SetDirty(settings); // Tells Unity to save changes to the settings .asset object on disk

            target.Apply(!doMips, false);
        }

        private static int GetMipmapCount(Texture tex) {
            int count = 1;
            var texture2D = tex as Texture2D;
            var renderTexture = tex as RenderTexture;
            var proceduralTexture = tex as ProceduralTexture;

            if (texture2D != null) {
                count = texture2D.mipmapCount;
            } else if (renderTexture != null) {
                count = renderTexture.useMipMap ? GetMipCountFromSize(tex) : 1;
            } else if (proceduralTexture != null) {
                var mat =
                    proceduralTexture.GetType()
                        .GetMethod("GetProceduralMaterial", BindingFlags.Instance | BindingFlags.NonPublic)
                        .Invoke(proceduralTexture, null) as ProceduralMaterial;
                var imp = AssetImporter.GetAtPath(AssetDatabase.GetAssetPath(mat)) as SubstanceImporter;
                count = imp != null && imp.GetGenerateMipMaps(mat) ? GetMipCountFromSize(tex) : 1;
            }

            return count;
        }

        private static int GetMipCountFromSize(Texture tex) {
            return Mathf.CeilToInt(Mathf.Log(Mathf.Max(tex.width, tex.height), 2.0f)) + 1;
        }
    }
}