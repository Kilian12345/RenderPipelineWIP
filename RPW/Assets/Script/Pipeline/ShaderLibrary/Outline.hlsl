#ifndef MYRP_OUTLINE_INCLUDED
#define MYRP_OUTLINE_INCLUDED

#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"


CBUFFER_START(UnityPerFrame)
float4x4 unity_MatrixVP;
CBUFFER_END

CBUFFER_START(UnityPerDraw)
float4x4 unity_ObjectToWorld;
CBUFFER_END

#define UNITY_MATRIX_M unity_ObjectToWorld

#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/UnityInstancing.hlsl"


struct VertexInput
{
    float4 pos : POSITION;
    float3 uv : TEXCOORD0;
	UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct VertexOutput
{
    float4 pos : SV_POSITION;
    float2 uv : TEXCOORD0;
};

sampler2D _MainTex;
            //the depth normals texture
sampler2D _CameraDepthNormalsTexture;
            //texelsize of the depthnormals texture
float4 _CameraDepthNormalsTexture_TexelSize;

float4 _OutlineColor;
float _NormalMult;
float _NormalBias;
float _DepthMult;
float _DepthBias;

VertexOutput OutlinePassVert(VertexInput input)
{
    VertexOutput output;
    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_TRANSFER_INSTANCE_ID(input, output);
    input.pos.xyz *= _OutlineWidth;
    float4 worldPos = mul(UNITY_MATRIX_M, float4(input.pos.xyz, 1.0));
    output.pos = mul(unity_MatrixVP, worldPos);
    output.pos = mul(output.pos, input.pos);
    output.uv = input.uv;
    

    return output;
}

void Compare(inout float depthOutline, inout float normalOutline,
                    float baseDepth, float3 baseNormal, float2 uv, float2 offset)
{
                //read neighbor pixel
    float4 neighborDepthnormal = tex2D(_CameraDepthNormalsTexture,
                        uv + _CameraDepthNormalsTexture_TexelSize.xy * offset);
    float3 neighborNormal;
    float neighborDepth;
    DecodeDepthNormal(neighborDepthnormal, neighborDepth, neighborNormal);
    neighborDepth = neighborDepth * _ProjectionParams.z;

    float depthDifference = baseDepth - neighborDepth;
    depthOutline = depthOutline + depthDifference;

    float3 normalDifference = baseNormal - neighborNormal;
    normalDifference = normalDifference.r + normalDifference.g + normalDifference.b;
    normalOutline = normalOutline + normalDifference;
}

float4 OutlinePassFrag(VertexOutput input) : SV_TARGET
{
    UNITY_SETUP_INSTANCE_ID(input);
    float4 sourceColor = _MainTex.Sample(sampler_MainTex, input.uv);
    return sourceColor * _OutlineColor;
    //return UNITY_ACCESS_INSTANCED_PROP(PerInstance, float4(_MainTex, input.uv));
}

#endif // MYRP_OUTLINE_INCLUDED