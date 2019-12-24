Shader "My Pipeline/Outline"
{
    Properties
    {
        [HideInInspector] _MainTex("Texture", 2D) = "white" {}
        _OutlineColor("Outline Color", Color) = (0,0,0,1)
        _NormalMult("Normal Outline Multiplier", Range(0,4)) = 1
        _NormalBias("Normal Outline Bias", Range(1,4)) = 1
        _DepthMult("Depth Outline Multiplier", Range(0,4)) = 1
        _DepthBias("Depth Outline Bias", Range(1,4)) = 1
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100
        Cull Off
        ZWrite Off
        ZTest Always

        Pass
        {
				HLSLPROGRAM

				#pragma target 3.5

				#pragma multi_compile_instancing
				#pragma instancing_options assumeuniformscaling

				#pragma vertex OutlinePassVert
				#pragma fragment OutlinePassFrag

				#include "../ShaderLibrary/Outline.hlsl"

				ENDHLSL
        }
    }
}
