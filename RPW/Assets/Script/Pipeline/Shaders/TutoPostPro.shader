Shader "My Pipeline/TutoPostPro" {

	Properties{

		_OutlineColor("Outline Color", Color) = (0,0,0,1)
		_NormalMult("Normal Outline Multiplier", Range(0,4)) = 1
		_NormalBias("Normal Outline Bias", Range(1,4)) = 1
		_DepthMult("Depth Outline Multiplier", Range(0,4)) = 1
		_DepthBias("Depth Outline Bias", Range(1,4)) = 1
	}
	SubShader{
		Pass {
			Cull Off
			ZTest Always
			ZWrite Off

			HLSLPROGRAM
			#pragma target 3.5
			#pragma vertex CopyPassVertex
			#pragma fragment CopyPassFragment
			#include "../ShaderLibrary/PostEffectStack.hlsl"
			ENDHLSL
		}
	}
}