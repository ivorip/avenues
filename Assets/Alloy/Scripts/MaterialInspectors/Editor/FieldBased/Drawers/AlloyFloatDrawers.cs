// Alloy Physical Shader Framework
// Copyright 2013-2016 RUST LLC.
// http://www.alloy.rustltd.com/

using System;
using System.Text.RegularExpressions;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using UnityEditor;

public class AlloyDropdownOption {
    public string Name;
    public string[] HideFields;
}

public class AlloyFloatParser : AlloyFieldParser{
    protected override AlloyFieldDrawer GenerateDrawer(AlloyInspectorBase editor) {
        AlloyFieldDrawer retDrawer = null;

        foreach (var token in Arguments) {
            var argName = token.ArgumentName;
            var argToken = token.ArgumentToken;

            switch (argName) {
                case "Min":
                    AlloyFloatDrawer minDrawer = null;
                    var minValToken = argToken as AlloyValueToken;
                        
                    if (retDrawer != null)
                        minDrawer = retDrawer as AlloyFloatDrawer;
                        
                    if (minDrawer == null)
                        minDrawer = new AlloyFloatDrawer(editor, MaterialProperty);

                    minDrawer.HasMin = true;
                    minDrawer.MinValue = minValToken.FloatValue;
                    retDrawer = minDrawer;
                    break;

                case "Max":
                    AlloyFloatDrawer maxDrawer = null;
                    var maxValToken = argToken as AlloyValueToken;
                    
                    if (retDrawer != null)
                        maxDrawer = retDrawer as AlloyFloatDrawer;

                    if (maxDrawer == null)
                        maxDrawer = new AlloyFloatDrawer(editor, MaterialProperty);

                    maxDrawer.HasMax = true;
                    maxDrawer.MaxValue = maxValToken.FloatValue;
                    retDrawer = maxDrawer;
                    break;

                case "Section":
                    var section = new AlloySectionDrawer(editor, MaterialProperty);
                    section.Color = ParseColor(argToken);
                    retDrawer = section;
                    break;

                case "Feature":
                    var feature = new AlloyFeatureDrawer(editor, MaterialProperty);
                    feature.Color = ParseColor(argToken);
                    retDrawer = feature;
                    break;

                case "Toggle":
                    retDrawer = new AlloyToggleDrawer(editor, MaterialProperty);
                    SetToggleOption(retDrawer, argToken);
                    break;
                    
                case "SpeedTreeGeometryType":
                    retDrawer = new AlloySpeedTreeGeometryTypeDrawer(editor, MaterialProperty);
                    SetDropdownOption(retDrawer, argToken);
                    break;

                case "RenderingMode":
                    retDrawer = new AlloyRenderingModeDrawer(editor, MaterialProperty);
                    SetDropdownOption(retDrawer, argToken);
                    break;

                case "Dropdown":
                    retDrawer = new AlloyDropdownDrawer(editor, MaterialProperty);
                    SetDropdownOption(retDrawer, argToken);
                    break;

                case "LightmapEmissionProperty":
                    retDrawer = new AlloyLightmapEmissionDrawer(editor, MaterialProperty);
                    break;

                case "DecalSortOrder":
                    retDrawer = new AlloyDecalSortOrderDrawer(editor, MaterialProperty);
                    break;
            }
        }

        if (retDrawer == null)
            retDrawer = new AlloyFloatDrawer(editor, MaterialProperty);

        return retDrawer;
    }

    private static void SetDropdownOption(AlloyFieldDrawer retDrawer, AlloyToken argToken) {
        var drawer = retDrawer as AlloyDropdownDrawer;

        if (drawer == null) {
            return;
        }
        var options = argToken as AlloyCollectionToken;

        if (options == null) {
            return;
        }
        var dropOptions = new List<AlloyDropdownOption>();

        for (int i = 0; i < options.SubTokens.Count; i++) {
            AlloyArgumentToken arg = (AlloyArgumentToken)options.SubTokens[i];
            var collection = arg.ArgumentToken as AlloyCollectionToken;

            if (collection == null) {
                continue;
            }

            // Split name at capital letters, then insert spaces between words.
            var dropOption = new AlloyDropdownOption {
                Name = string.Join(" ", Regex.Split(arg.ArgumentName, @"(?<!^)(?=[A-Z])")),
                HideFields = collection.SubTokens.Select(alloyToken => alloyToken.Token).ToArray()
            };
            dropOptions.Add(dropOption);
        }

        drawer.DropOptions = dropOptions.ToArray();
    }

    private static void SetToggleOption(AlloyFieldDrawer retDrawer, AlloyToken argToken) {
        var drawer = retDrawer as AlloyToggleDrawer;

        if (drawer == null) {
            return;
        }
        var collectionToken = argToken as AlloyCollectionToken;

        if (collectionToken == null) {
            return;
        }
        foreach (var token in collectionToken.SubTokens) {
            var arg = token as AlloyArgumentToken;

            if (arg != null && arg.ArgumentName == "On") {
                var onToken = arg.ArgumentToken as AlloyCollectionToken;

                if (onToken != null) {
                    drawer.OnHideFields = onToken.SubTokens.Select(colToken => colToken.Token).ToArray();
                }
            }
            else if (arg != null && arg.ArgumentName == "Off") {
                var offToken = arg.ArgumentToken as AlloyCollectionToken;

                if (offToken != null) {
                    drawer.OffHideFields = offToken.SubTokens.Select(colToken => colToken.Token).ToArray();
                }
            }
        }
    }

    private static void SetMinOption(AlloyFieldDrawer retDrawer, AlloyToken argToken) {
        var floatDrawer = retDrawer as AlloyFloatDrawer;
        var minValToken = argToken as AlloyValueToken;

        if (floatDrawer != null) {
            floatDrawer.HasMin = true;

            if (minValToken != null) {
                floatDrawer.MinValue = minValToken.FloatValue;
            }
        }
    }


    private Color ParseColor(AlloyToken argToken) {
        var colCollection = argToken as AlloyCollectionToken;

        if (colCollection != null) {
            var r = colCollection.SubTokens[0] as AlloyValueToken;
            var g = colCollection.SubTokens[1] as AlloyValueToken;
            var b = colCollection.SubTokens[2] as AlloyValueToken;

            if (r != null && g != null && b != null) {
                return new Color32((byte)r.FloatValue, (byte)g.FloatValue, (byte)b.FloatValue, 255);
            }
        }

        return Color.white;
    }

    public AlloyFloatParser(MaterialProperty field)
        : base(field) {
    }
}


public abstract class AlloyTabDrawer : AlloyFieldDrawer
{
    public Color Color;
    private Func<bool, Action<Rect>> m_foldoutAction;

    protected void SetAllTabsOpenedTo(bool open, AlloyFieldDrawerArgs args) {
        foreach (var tab in args.AllTabNames) {
            args.TabGroup.SetOpen(tab + args.MatInst, open);
        }
    }

    public override bool ShouldDraw(AlloyFieldDrawerArgs args) {
        return true;
    }

    protected void DrawNow(AlloyFieldDrawerArgs args, bool optional) {
        bool first = string.IsNullOrEmpty(args.CurrentTab);

        if (first) {
            GUILayout.Space(5.0f);
        }
        else {
            if (args.DoDraw) {
                GUILayout.Space(10.0f);
            }

            EditorGUILayout.EndFadeGroup();
        }

        if (!optional || args.Editor.TabIsEnabled(Property.name)) {
            bool open;

            if (first && !optional) {
                bool openAll = args.AllTabNames.All(tab => args.TabGroup.IsOpen(tab + args.MatInst));
                bool closeOpen;
                bool all = openAll;



                open = args.TabGroup.TabArea(DisplayName, Color, true, m_foldoutAction(all), out closeOpen, DisplayName + args.MatInst);

                if (closeOpen) {
                    openAll = !openAll;
                    SetAllTabsOpenedTo(openAll, args);
                }
            }
            else {
                bool removed;
                open = args.TabGroup.TabArea(DisplayName, Color, optional, out removed, DisplayName + args.MatInst);

                if (removed) {
                    args.Editor.DisableTab(DisplayName, Property.name, args.MatInst);
                }
            }

            var anim = args.OpenCloseAnim[Property.name];
            anim.target = open;

            args.CurrentTab = Property.name;
            args.DoDraw = EditorGUILayout.BeginFadeGroup(anim.faded);
        }
        else {
            args.DoDraw = false;

            args.TabsToAdd.Add(new AlloyTabAdd { Color = Color, Name = DisplayName, Enable = () => args.Editor.EnableTab(DisplayName, Property.name, args.MatInst) });
        }
    }

    protected AlloyTabDrawer(AlloyInspectorBase editor, MaterialProperty property)
        : base(editor, property) {
        m_foldoutAction = all => r => GUI.Label(r, all ? "v" : ">", EditorStyles.whiteLabel);
    }
}

public class AlloyFeatureDrawer : AlloyTabDrawer {
    public override void Draw(AlloyFieldDrawerArgs args) {
        DrawNow(args, true);

    }

    public AlloyFeatureDrawer(AlloyInspectorBase editor, MaterialProperty property) : base(editor, property) {
    }
}

public class AlloySectionDrawer : AlloyTabDrawer {
    public override void Draw(AlloyFieldDrawerArgs args) {
        DrawNow(args, false);
    }

    public AlloySectionDrawer(AlloyInspectorBase editor, MaterialProperty property) : base(editor, property) {
    }
}

public class AlloyFloatDrawer : AlloyFieldDrawer
{
    public bool HasMin;
    public float MinValue;

    public bool HasMax;
    public float MaxValue;

    private int m_selectedIndex;

    public override void Draw(AlloyFieldDrawerArgs args) {
        if (HasMin || HasMax) {
            if (HasMin && HasMax) {
                FloatFieldSlider(DisplayName, MinValue, MaxValue);
            }
            else if (HasMin) {
                FloatFieldMin(DisplayName, MinValue);
            }
            else {
                FloatFieldMax(DisplayName, MaxValue);
            }
        }
        else {
            PropField(DisplayName);
        }
    }

    public AlloyFloatDrawer(AlloyInspectorBase editor, MaterialProperty property) : base(editor, property) {
    }
}

public class AlloyDropdownDrawer : AlloyFieldDrawer {
    public AlloyDropdownOption[] DropOptions;

    protected virtual bool OnSetOption(int newOption, AlloyFieldDrawerArgs args) {
        return false;
    }

    public override void Draw(AlloyFieldDrawerArgs args) {
        int current = (int) Serialized.floatValue;
        var label = new GUIContent(DisplayName);

        EditorGUI.BeginProperty(new Rect(), label, Serialized);
        EditorGUI.BeginChangeCheck();
        int newVal = EditorGUILayout.Popup(label, current, DropOptions.Select(option => new GUIContent(option.Name)).ToArray());


        if (!OnSetOption(newVal, args) && EditorGUI.EndChangeCheck()) {
            Serialized.floatValue = newVal;
            Property.floatValue = newVal;
        }

        EditorGUI.EndProperty();

        args.PropertiesSkip.AddRange(DropOptions[current].HideFields);
    }

    public AlloyDropdownDrawer(AlloyInspectorBase editor, MaterialProperty property) : base(editor, property) {
    }
}

public class AlloyToggleDrawer : AlloyFieldDrawer {
    public string[] OnHideFields;
    public string[] OffHideFields;

    public override void Draw(AlloyFieldDrawerArgs args) {
        bool current = Serialized.floatValue > 0.5f;
        var label = new GUIContent(DisplayName);

        EditorGUI.BeginProperty(new Rect(), label, Serialized);
        EditorGUI.BeginChangeCheck();
        current = EditorGUILayout.Toggle(label, current);

        if (EditorGUI.EndChangeCheck()) {
            Serialized.floatValue = current ? 1.0f : 0.0f;
            Property.floatValue = current ? 1.0f : 0.0f;
        }

        EditorGUI.EndProperty();

        if (!current) {
            if (OffHideFields != null) {
                args.PropertiesSkip.AddRange(OffHideFields);
            }
        } else {
            if (OnHideFields != null) {
                args.PropertiesSkip.AddRange(OnHideFields);
            }
        }
    }

    public AlloyToggleDrawer(AlloyInspectorBase editor, MaterialProperty property) : base(editor, property) {
    }
}