// Alloy Physical Shader Framework
// Copyright 2013-2016 RUST LLC.
// http://www.alloy.rustltd.com/

/////////////////////////////////////////////////////////////////////////////////
/// @file SpeedTreeBillboard.cginc
/// @brief SpeedTree Billboard surface shader definition.
/////////////////////////////////////////////////////////////////////////////////

#ifndef A_DEFINITIONS_SPEED_TREE_BILLBOARD_CGINC
#define A_DEFINITIONS_SPEED_TREE_BILLBOARD_CGINC

#define _ALPHATEST_ON

#include "Assets/Alloy/Shaders/Lighting/Standard.cginc"
#include "Assets/Alloy/Shaders/Models/SpeedTreeBillboard.cginc"

void aSurface(
    inout ASurface s)
{
    aSpeedTree(s);
    s.specularity = 0.5h;
    s.roughness = 1.0h;
    s.ambientOcclusion = 1.0h;

#ifdef EFFECT_BUMP
    aUpdateNormalData(s);
#endif
}

#endif // A_DEFINITIONS_SPEED_TREE_BILLBOARD_CGINC
