// Pcx - Point cloud importer & renderer for Unity
// https://github.com/keijiro/Pcx
// URP version by Atsu-sys

Shader "Point Cloud/Disk URP"
{
    Properties
    {
        _Tint("Tint", Color) = (0.5, 0.5, 0.5, 1)
        _PointSize("Point Size", Float) = 0.05
        [KeywordEnum(RGB, BGR, GBR, GRB, BRG, RBG)] _ColorOrder("Color Order", Float) = 0
        _Rotation("Rotation", Vector) = (0, 0, 0, 0)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline"="UniversalPipeline" "Queue"="Geometry" }
        Cull Off
        
        Pass
        {
            Name "ForwardLit"
            Tags { "LightMode"="UniversalForward" }
            
            HLSLPROGRAM
            #pragma vertex Vertex
            #pragma geometry Geometry
            #pragma fragment Fragment
            #pragma multi_compile_fog
            #pragma multi_compile _ _COMPUTE_BUFFER
            #pragma shader_feature_local _COLORORDER_RGB _COLORORDER_BGR _COLORORDER_GBR _COLORORDER_GRB _COLORORDER_BRG _COLORORDER_RBG
            #pragma multi_compile_instancing
            #include "Disk.hlsl"
            ENDHLSL
        }
        
        Pass
        {
            Name "ShadowCaster"
            Tags { "LightMode"="ShadowCaster" }
            
            HLSLPROGRAM
            #pragma vertex Vertex
            #pragma geometry Geometry
            #pragma fragment Fragment
            #pragma multi_compile _ _COMPUTE_BUFFER
            #pragma multi_compile_instancing
            #define PCX_SHADOW_CASTER 1
            #include "Disk.hlsl"
            ENDHLSL
        }
        
        Pass
        {
            Name "DepthOnly"
            Tags { "LightMode"="DepthOnly" }
            
            ColorMask 0
            ZWrite On
            
            HLSLPROGRAM
            #pragma vertex Vertex
            #pragma geometry Geometry
            #pragma fragment Fragment
            #pragma multi_compile _ _COMPUTE_BUFFER
            #pragma multi_compile_instancing
            #define PCX_SHADOW_CASTER 1
            #include "Disk.hlsl"
            ENDHLSL
        }
    }
    
    // Fallback for non-URP
    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue"="Geometry" }
        Cull Off
        Pass
        {
            Tags { "LightMode"="ForwardBase" }
            CGPROGRAM
            #pragma vertex Vertex
            #pragma geometry Geometry
            #pragma fragment Fragment
            #pragma multi_compile_fog
            #pragma multi_compile _ UNITY_COLORSPACE_GAMMA
            #pragma multi_compile _ _COMPUTE_BUFFER
            #pragma multi_compile _COLORORDER_RGB _COLORORDER_BGR _COLORORDER_GBR _COLORORDER_GRB _COLORORDER_BRG _COLORORDER_RBG
            
            #include "UnityCG.cginc"
            
            half4 _Tint;
            half _PointSize;
            float4x4 _Transform;
            
            half3 SwapColorChannels(half3 col)
            {
                #if defined(_COLORORDER_BGR)
                    return col.bgr;
                #elif defined(_COLORORDER_GBR)
                    return col.gbr;
                #elif defined(_COLORORDER_GRB)
                    return col.grb;
                #elif defined(_COLORORDER_BRG)
                    return col.brg;
                #elif defined(_COLORORDER_RBG)
                    return col.rbg;
                #else
                    return col.rgb;
                #endif
            }
            
            struct Attributes
            {
            #if _COMPUTE_BUFFER
                uint vertexID : SV_VertexID;
            #else
                float4 position : POSITION;
                half3 color : COLOR;
            #endif
            };
            
            struct Varyings
            {
                float4 position : SV_POSITION;
                half3 color : COLOR;
                UNITY_FOG_COORDS(0)
            };
            
            Varyings Vertex(Attributes input)
            {
            #if _COMPUTE_BUFFER
                float4 pos = float4(0, 0, 0, 1);
                half3 col = half3(1, 1, 1);
            #else
                float4 pos = input.position;
                half3 col = SwapColorChannels(input.color);
            #endif
                col *= _Tint.rgb * 2;
                
                Varyings o;
                o.position = UnityObjectToClipPos(pos);
                o.color = col;
                UNITY_TRANSFER_FOG(o, o.position);
                return o;
            }
            
            [maxvertexcount(36)]
            void Geometry(point Varyings input[1], inout TriangleStream<Varyings> outStream)
            {
                float4 origin = input[0].position;
                float2 extent = abs(UNITY_MATRIX_P._11_22 * _PointSize);
                
                Varyings o = input[0];
                
                float radius = extent.y / origin.w * _ScreenParams.y;
                uint slices = min((radius + 1) / 5, 4) + 2;
                
                if (slices == 2) extent *= 1.2;
                
                o.position.y = origin.y + extent.y;
                o.position.xzw = origin.xzw;
                outStream.Append(o);
                
                for (uint i = 1; i < slices; i++)
                {
                    float sn, cs;
                    sincos(UNITY_PI / slices * i, sn, cs);
                    
                    o.position.xy = origin.xy + extent * float2(sn, cs);
                    outStream.Append(o);
                    
                    o.position.x = origin.x - extent.x * sn;
                    outStream.Append(o);
                }
                
                o.position.x = origin.x;
                o.position.y = origin.y - extent.y;
                outStream.Append(o);
                
                outStream.RestartStrip();
            }
            
            half4 Fragment(Varyings input) : SV_Target
            {
                half4 c = half4(input.color, _Tint.a);
                UNITY_APPLY_FOG(input.fogCoord, c);
                return c;
            }
            ENDCG
        }
    }
    
    CustomEditor "Pcx.DiskMaterialInspector"
}
