#ifndef MYRP_POST_EFFECT_STACK_INCLUDED
#define MYRP_POST_EFFECT_STACK_INCLUDED

#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"

TEXTURE2D(_CameraDepthTexture);
SAMPLER(sampler_CameraDepthTexture);
float4 _CameraDepthTexture_TexelSize;

TEXTURE2D(_MainTex);
SAMPLER(sampler_MainTex);
float4 _ProjectionParams;
float4 _WorldSpaceCameraPos;

CBUFFER_START(UnityPerFrame)
float4x4 unity_MatrixV;
float4x4 UNITY_MATRIX_VP;
CBUFFER_END

CBUFFER_START(UnityPerDraw)
float4x4 unity_ObjectToWorld;
float4x4 unity_WorldToObject;
CBUFFER_END

struct VertexInput
{
    float4 pos : POSITION;
    float2 uv : TEXCOORD0;
    float3 normal : NORMAL;
};

struct VertexOutput
{
    float4 clipPos : SV_POSITION;
    float2 uv : TEXCOORD0;
    float3 normal : TEXCOORD1;
};

float4 _OutlineColor = float4(1,0,0,1);
float _NormalMult;
float _NormalBias;
float _DepthMult = 0.1f;
float _DepthBias;

// INLINE FUNCTIONS ------------------

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


inline float3 UnityObjectToViewPos(in float3 pos)
{
    return mul(unity_MatrixV, mul(unity_ObjectToWorld, float4(pos, 1.0))).xyz;
}
inline float3 UnityObjectToViewPos(float4 pos) // overload for float4; avoids "implicit truncation" warning for existing shaders
{
    return UnityObjectToViewPos(pos.xyz);
}

// -----------------


float Compare(float baseDepth, float2 uv, float2 offset)
{
    //read neighbor pixel
    float4 neighborDepthTex = SAMPLE_TEXTURE2D(_CameraDepthTexture, sampler_CameraDepthTexture,
                        uv + _CameraDepthTexture_TexelSize.xy * offset);
    float3 neighborNormal;
    float neighborDepth = neighborDepthTex.r;
    neighborDepth = neighborDepth * _ProjectionParams.z;
    
    float r = baseDepth - neighborDepth;

    return r ;
}

VertexOutput CopyPassVertex(VertexInput input)
{
    VertexOutput output;
    output.clipPos = float4(input.pos.xy, 0.0, 1.0);
    output.uv = input.pos.xy * 0.5 + 0.5;    
    if (_ProjectionParams.x < 0.0)
    {output.uv.y = 1.0 - output.uv.y;}
    
    return output;
}


float4 CopyPassFragment(VertexOutput input) : SV_TARGET
{
    
    float depthTex = SAMPLE_TEXTURE2D(_CameraDepthTexture, sampler_CameraDepthTexture,
                        input.uv).r;
    float depth = depthTex.r;
    float3 normal;
    depth = depth * _ProjectionParams.z; // +1 for manga effect
    
    //White
    float depthDifference = Compare(depth, input.uv, float2(2, 0));
    depthDifference = depthDifference + Compare(depth, input.uv, float2(0, 2));
    depthDifference = depthDifference + Compare(depth, input.uv, float2(0, -2));
    depthDifference = depthDifference + Compare(depth, input.uv, float2(-2, 0));
   
    //Black
    float depthDifferenceClose = Compare(depth, input.uv, float2(1, 0));
    depthDifferenceClose = depthDifferenceClose + Compare(depth, input.uv, float2(0, 1));
    depthDifferenceClose = depthDifferenceClose + Compare(depth, input.uv, float2(0, -1));
    depthDifferenceClose = depthDifferenceClose + Compare(depth, input.uv, float2(-1, 0));
    
    depthDifference = depthDifference * 5.5;
    depthDifference = saturate(depthDifference);
    depthDifference = pow(depthDifference, 1);  
    
    depthDifferenceClose = depthDifferenceClose * 5.5;
    depthDifferenceClose = saturate(depthDifferenceClose);
    depthDifferenceClose = pow(depthDifferenceClose, 1);
   
    
    float4 sourceColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.uv);
    float4 color = 0;
    color += lerp(sourceColor, float4(1, 1, 1, 1), depthDifference - depthDifferenceClose);
    color += lerp(sourceColor, float4(0, 0, 0, 1), depthDifferenceClose) - sourceColor;
    
    return color;
    //return sourceColor;
    //return depthDifference;
    
    /*
    float outline = /*normalDifference +depthDifference;
    float4 color = lerp(sourceColor, _OutlineColor, outline);
    return color;*/
}

#endif // MYRP_POST_EFFECT_STACK_INCLUDED