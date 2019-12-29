#ifndef MYRP_POST_EFFECT_STACK_INCLUDED
#define MYRP_POST_EFFECT_STACK_INCLUDED

#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"

TEXTURE2D(_CameraDepthTexture);
SAMPLER(sampler_CameraDepthTexture);
float4 _CameraDepthTexture_TexelSize;

TEXTURE2D(_MainTex);
SAMPLER(sampler_MainTex);
float4 _ProjectionParams;

CBUFFER_START(UnityPerFrame)
float4x4 unity_MatrixV;
CBUFFER_END

CBUFFER_START(UnityPerDraw)
float4x4 unity_ObjectToWorld;
float4x4 unity_WorldToObject;
CBUFFER_END

struct VertexInput
{
    float4 pos : POSITION;
    float2 uv : TEXCOORD0;
    float4 normal : NORMAL;
};

struct VertexOutput
{
    float4 clipPos : SV_POSITION;
    float2 uv : TEXCOORD0;
    float4 normal : NORMAL;
};

float4 _OutlineColor = float4(1,0,0,1);
float _NormalMult;
float _NormalBias;
float _DepthMult = 0.1f;
float _DepthBias;


inline float3 UnityObjectToWorldDir(in float3 dir)
{
    return normalize(mul((float3x3) unity_ObjectToWorld, dir));
}

inline float3 UnityObjectToWorldNormal(in float3 norm)
{
#ifdef UNITY_ASSUME_UNIFORM_SCALING
    return UnityObjectToWorldDir(norm);
#else
    // mul(IT_M, norm) => mul(norm, I_M) => {dot(norm, I_M.col0), dot(norm, I_M.col1), dot(norm, I_M.col2)}
    return normalize(mul(norm, (float3x3) unity_WorldToObject));
#endif
}

/*
void Compare(inout float depthOutline, inout float normalOutline,
                    float baseDepth, float3 baseNormal, float2 uv, float2 offset)
{
                //read neighbor pixel
    float4 neighborDepthTex = SAMPLE_TEXTURE2D(_CameraDepthTexture, sampler_CameraDepthTexture,
                        uv + _CameraDepthTexture_TexelSize.xy * offset);
    float neighborDepth = neighborDepthTex.r;
    float3 neighborNormal;
    neighborDepth = neighborDepth * _ProjectionParams.z;

    float depthDifference = baseDepth - neighborDepth;
    depthOutline = depthOutline + depthDifference;

    float3 normalDifference = baseNormal - neighborNormal;
    normalDifference = normalDifference.r + normalDifference.g + normalDifference.b;
    normalOutline = normalOutline + normalDifference;
}*/

float Compare(float baseDepth, float2 uv, float2 offset)
{
    //read neighbor pixel
    float4 neighborDepthTex = SAMPLE_TEXTURE2D(_CameraDepthTexture, sampler_CameraDepthTexture,
                        uv + _CameraDepthTexture_TexelSize.xy * offset);
    float3 neighborNormal;
    float neighborDepth = neighborDepthTex.r;
    neighborDepth = neighborDepth * _ProjectionParams.z;
    
    float r = baseDepth - neighborDepth;

    return r;
}

VertexOutput CopyPassVertex(VertexInput input)
{
    VertexOutput output;
    output.clipPos = float4(input.pos.xy, 0.0, 1.0);
    output.uv = input.pos.xy * 0.5 + 0.5;    
    if (_ProjectionParams.x < 0.0)
    {output.uv.y = 1.0 - output.uv.y;}
    
    float3 worldNorm = UnityObjectToWorldNormal((float3)input.normal);
    float3 viewNorm = mul((float3x3) unity_MatrixV, worldNorm);
    
    return output;
}

/*
float4 CopyPassFragment(VertexOutput input) : SV_TARGET
{
    float depthTex = SAMPLE_TEXTURE2D(_CameraDepthTexture, sampler_CameraDepthTexture,
                        input.uv).r;
    float depth = depthTex.r;
    float3 normal;
    depth = depth * _ProjectionParams.z;
    
    float depthDifference = 0;
    float normalDifference = 0;
    
    Compare(depthDifference, normalDifference, depth, normal, input.uv, float2(1, 0));
    Compare(depthDifference, normalDifference, depth, normal, input.uv, float2(0, 1));
    Compare(depthDifference, normalDifference, depth, normal, input.uv, float2(0, -1));
    Compare(depthDifference, normalDifference, depth, normal, input.uv, float2(-1, 0));
    
    depthDifference = depthDifference * _DepthMult;
    depthDifference = saturate(depthDifference);
    depthDifference = pow(depthDifference, _DepthBias);

    normalDifference = normalDifference * _NormalMult;
    normalDifference = saturate(normalDifference);
    normalDifference = pow(normalDifference, _NormalBias);
    
    float4 sourceColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.uv);
    float outline = /*normalDifference + depthDifference;
    float4 color = lerp(sourceColor, _OutlineColor, outline);
    return color;
}*/

float4 CopyPassFragment(VertexOutput input) : SV_TARGET
{
    float depthTex = SAMPLE_TEXTURE2D(_CameraDepthTexture, sampler_CameraDepthTexture,
                        input.uv).r;
    float depth = depthTex.r;
    float3 normal;
    depth = depth * _ProjectionParams.z;
    
    
    float depthDifference = Compare(depth, input.uv, float2(1, 0));
    depthDifference = depthDifference + Compare(depth, input.uv, float2(0, 1));
    depthDifference = depthDifference + Compare(depth, input.uv, float2(0, -1));
    depthDifference = depthDifference + Compare(depth, input.uv, float2(-1, 0));
    
    //depthDifference = depthDifference * _DepthMult;
    depthDifference = depthDifference * 0.1;
    //depthDifference = saturate(depthDifference);
    depthDifference = pow(depthDifference, 1);
    
    float4 sourceColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.uv);
    float4 color = lerp(sourceColor, float4(1, 1, 1, 1), depthDifference);
    
    return color;
    
    /*
    float outline = /*normalDifference +depthDifference;
    float4 color = lerp(sourceColor, _OutlineColor, outline);
    return color;*/
}

#endif // MYRP_POST_EFFECT_STACK_INCLUDED