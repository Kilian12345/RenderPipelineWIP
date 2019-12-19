Shader "My Pipeline/Outline"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {

			Tags
			{
				"Queue" = "Transparent"
			}

				ZWrite Off
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
