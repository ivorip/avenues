// Alloy Physical Shader Framework
// Copyright 2013-2016 RUST LLC.
// http://www.alloy.rustltd.com/

using UnityEditor;
using UnityEngine;
using System.Collections;

public static class AlloyMenuGroups  {

    [MenuItem("Window/Alloy/Feedback", false, 100)]
    static void Feedback() {

        Application.OpenURL("http://alloy.rustltd.com/contact");
    }


    [MenuItem("Window/Alloy/Documentation", false, 100)]
    static void Documentation() {

        Application.OpenURL("http://alloy.rustltd.com/documentation");
    }

    [MenuItem("Window/Alloy/About", false, 100)]
    static void About() {

        Application.OpenURL("http://alloy.rustltd.com/");
    }

}
