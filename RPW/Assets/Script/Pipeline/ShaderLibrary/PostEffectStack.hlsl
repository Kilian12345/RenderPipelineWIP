#ifndef MYRP_POST_EFFECT_STACK_INCLUDED
#define MYRP_POST_EFFECT_STACK_INCLUDED

#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"

float4 _ProjectionParams;

TEXTURE2D(_MainTex);
SAMPLER(sampler_MainTex);

// // //

TEXTURE2D(_CameraDepthNormalsTexture);
SAMPLER(sampler_CameraDepthNormalsTexture);

float4 _CameraDepthNormalsTexture_TexelSize;

float4 _OutlineColor = float4(0, 0, 0, 1);
float _NormalMult = 1;
float _NormalBias = 1;
float _DepthMult = 1;
float _DepthBias = 1;

struct VertexInput
{
    float4 pos : POSITION;
    float2 uv : TEXCOORD0;
};

struct VertexOutput
{
    float4 clipPos : SV_POSITION;
    float2 uv : TEXCOORD0;
};

inline float DecodeFloatRG(float2 enc)
{
    float2 kDecodeDot = float2(1.0, 1 / 255.0);
    return dot(enc, kDecodeDot);
}

inline float3 DecodeViewNormalStereo(float4 enc4)
{
    float kScale = 1.7777;
    float3 nn = enc4.xyz * float3(2 * kScale, 2 * kScale, 0) + float3(-kScale, -kScale, 1);
    float g = 2.0 / dot(nn.xyz, nn.xyz);
    float3 n;
    n.xy = g * nn.xy;
    n.z = g - 1;
    return n;
}

inline void DecodeDepthNormal(float4 enc, out float depth, out float3 normal)
{
    depth = DecodeFloatRG(enc.zw);
    normal = DecodeViewNormalStereo(enc);
}

void Compare(inout float depthOutline, inout float normalOutline,
                    float baseDepth, float3 baseNormal, float2 uv, float2 offset)
{
                //read neighbor pixel
    float4 neighborDepthnormal = SAMPLE_TEXTURE2D(_CameraDepthNormalsTexture, sampler_CameraDepthNormalsTexture,
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

VertexOutput CopyPassVertex(VertexInput input)
{
    VertexOutput output;
    output.clipPos = float4(input.pos.xy, 0.0, 1.0);
    output.uv = input.pos.xy * 0.5 + 0.5;
    
    if (_ProjectionParams.x < 0.0)
    {
        output.uv.y = 1.0 - output.uv.y;
    }
    
    output.uv = input.uv;
    return output;
}

float4 CopyPassFragment(VertexOutput input) : SV_TARGET
{
     //read depthnormal
    float4 depthnormal = SAMPLE_TEXTURE2D(_CameraDepthNormalsTexture, sampler_CameraDepthNormalsTexture,
    input.uv);

                //decode depthnormal
    float3 normal;
    float depth;
    DecodeDepthNormal(depthnormal, depth, normal);

                //get depth as distance from camera in units 
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

    float outline = normalDifference + depthDifference;
    float4 sourceColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.uv);
    float4 color = lerp(sourceColor, _OutlineColor, outline);
    //return color;
    return SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.uv);;
    
}

#endif // MYRP_POST_EFFECT_STACK_INCLUDED