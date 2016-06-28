Greetings!
Welcome to the Alloy Shader Framework Version 3 Readme!

Pre-Import Checklist:

Alright, so we're ready to jump into some Alloy 3 goodness, but there's a few things we want to make sure we're ready for depending on what the state of your project is, and what past version of Alloy (if any) are in your project.
First and foremost, if you are importing a new version of Alloy into a project where _any_ prior version of Alloy existed, it's probably a good idea to have a backup of it (manual or version controlled), just in case something goes awry.

Upgrading From Alloy3.x: In general, the alloy framework has reached a level of structure stability such that a prior version blow-out should _not_ be necessary. However, sometime go awry, a GUID gets messed up, or some other act of the cosmos, and a blow-out is a better idea. Personally, I tend to do clean installs just in case, as the only inconveinence is the import time.

Import Steps:
1. Ensure you are in a new blank scene.
2. ENSURE that there are NO script errors in your console preventing unity from recompiling assemblies. Alloy will NOT function properly (including our editor scripts), if you attempt to import with standing errors in your project.
3. Import the Alloy package from the Unity Asset Store download window if you have not yet done so.
4. The first thing you'll notice in the Alloy folder is that there is a sub-directory called 'Packages'.Within this directory there will be a package named Alloy3xx_ShadersAndEditorCore. Import this package first.
5. If you are a Windows user, and wish to use Alloy Tesselation Shaders (DX11 only), import the Alloy3xx_SM5Shaders folder. In general these shaders take a bit longer to compile/import, so we suggest only importing the variants you intend on using.
6. Lastly, if you'd like to check out our shweet samples, import the Alloy3SampleAssets package. Enjoy!

Setting Up Your Project

Before using Alloy, there a couple things you MUST set up in your project. 

1. Open Edit->Project Settings->Graphics.
2. Set the 'Deferred' setting to 'Custom shader'.
3. Open the picker below, and select the 'Alloy Deferred Shading' shader.
  * For additional options, go to "Advanced Setup" on our documentation website.
4. Set the 'Deferred Reflections' setting to 'Custom shader'.
5. Open the picker below, and select the 'Alloy Deferred Reflections' shader.
6. Open Edit->Project Settings->Player.
7. Open the 'Other Settings' rollout.
8. Set 'Color Space' to 'Linear'.
9. If you wish to use many lights, set 'Rendering Path' to 'Deferred'.
10. Select your camera in your scene.
11. Check the 'HDR' box.
12. Open Edit->Project Settings->Quality.
13. Ensure 'Anti-aliasing' on the Quality Setting your are using is set to 'none', or HDR will be silently disabled on your camera (ಠ_ಠ THANKS UNITY ಠ_ಠ).
14. Open Window->Alloy->Light Migration Tool.
15. Click "Migrate Lights" and wait for it to finish updating your existing lights.
16. Now save your scene.

Now you're ready to play!

Documentation:
1. In the Unity editor menu bar, go to "Window/Alloy/Documentation".
2. Change windows to the newly opened browser tab.

Now you're ready to play!
Getting Started:
