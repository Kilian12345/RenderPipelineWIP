#ifndef MYRP_POST_EFFECT_STACK_INCLUDED
#define MYRP_POST_EFFECT_STACK_INCLUDED

#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"

TEXTURE2D(_MainTex);
SAMPLER(sampler_MainTex);
float4 _ProjectionParams;

struct VertexInput
{
    float4 pos : POSITION;
};

struct VertexOutput
{
    float4 clipPos : SV_POSITION;
    float2 uv : TEXCOORD0;
};

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
    return SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.uv);
}

#endif // MYRP_POST_EFFECT_STACK_INCLUDED