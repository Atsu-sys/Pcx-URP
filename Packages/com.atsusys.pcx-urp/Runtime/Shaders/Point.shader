// Pcx - Point cloud importer & renderer for Unity
// https://github.com/keijiro/Pcx
// URP version by Atsu-sys

Shader "Point Cloud/Point URP"
{
    Properties
    {
        _Tint("Tint", Color) = (0.5, 0.5, 0.5, 1)
        _PointSize("Point Size", Float) = 0.05
        [Toggle] _Distance("Apply Distance", Float) = 1
        [KeywordEnum(RGB, BGR, GBR, GRB, BRG, RBG)] _ColorOrder("Color Order", Float) = 0
        _Rotation("Rotation", Vector) = (0, 0, 0, 0)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline"="UniversalPipeline" "Queue"="Geometry" }
        
        Pass
        {
            Name "ForwardLit"
            Tags { "LightMode"="UniversalForward" }

            HLSLPROGRAM

            #pragma vertex Vertex
            #pragma fragment Fragment

            #pragma multi_compile_fog
            #pragma multi_compile _ _DISTANCE_ON
            #pragma multi_compile _ _COMPUTE_BUFFER
            #pragma shader_feature_local _COLORORDER_RGB _COLORORDER_BGR _COLORORDER_GBR _COLORORDER_GRB _COLORORDER_BRG _COLORORDER_RBG

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Common.hlsl"

            struct Attributes
            {
                float4 position : POSITION;
                half3 color : COLOR;
            };

            struct Varyings
            {
                float4 position : SV_Position;
                half3 color : COLOR;
                half psize : PSIZE;
                float fogFactor : TEXCOORD0;
            };

            CBUFFER_START(UnityPerMaterial)
                half4 _Tint;
                half _PointSize;
            CBUFFER_END

            float4x4 _Transform;

        #if _COMPUTE_BUFFER
            StructuredBuffer<float4> _PointBuffer;
        #endif

            // Color channel swap function
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
                #else // _COLORORDER_RGB (default)
                    return col.rgb;
                #endif
            }

            half4 _Rotation;

            float3 RotatePoint(float3 p, float3 angles)
            {
                float3 rad = angles * (3.14159265359 / 180.0);
                float3 s, c;
                sincos(rad, s, c);
                
                // Rot X
                float3 p1 = p;
                p1.yz = float2(p.y * c.x - p.z * s.x, p.y * s.x + p.z * c.x);
                // Rot Y
                float3 p2 = p1;
                p2.xz = float2(p1.x * c.y + p1.z * s.y, -p1.x * s.y + p1.z * c.y);
                // Rot Z
                float3 p3 = p2;
                p3.xy = float2(p2.x * c.z - p2.y * s.z, p2.x * s.z + p2.y * c.z);
                return p3;
            }

        #if _COMPUTE_BUFFER
            Varyings Vertex(uint vid : SV_VertexID)
        #else
            Varyings Vertex(Attributes input)
        #endif
            {
            #if _COMPUTE_BUFFER
                float4 pt = _PointBuffer[vid];
                float4 pos = mul(_Transform, float4(pt.xyz, 1));
                half3 col = PcxDecodeColor(asuint(pt.w));
            #else
                float4 pos = input.position;
                half3 col = input.color;
            #endif

                // Apply rotation
                if (any(_Rotation.xyz))
                {
                    pos.xyz = RotatePoint(pos.xyz, _Rotation.xyz);
                }
                
                // Apply color channel swap
                col = SwapColorChannels(col);

                // Apply tint with color space handling
                #if defined(UNITY_COLORSPACE_GAMMA)
                    col *= _Tint.rgb * 2;
                #else
                    half3 tintGamma = pow(max(_Tint.rgb, 0.0001), 1.0 / 2.2);
                    col *= tintGamma * 2;
                    col = pow(max(col, 0.0001), 2.2);
                #endif

                Varyings o;
                o.position = TransformObjectToHClip(pos.xyz);
                o.color = col;
            #ifdef _DISTANCE_ON
                o.psize = _PointSize / o.position.w * _ScreenParams.y;
            #else
                o.psize = _PointSize;
            #endif
                o.fogFactor = ComputeFogFactor(o.position.z);
                return o;
            }

            half4 Fragment(Varyings input) : SV_Target
            {
                half4 c = half4(input.color, _Tint.a);
                c.rgb = MixFog(c.rgb, input.fogFactor);
                return c;
            }

            ENDHLSL
        }
        
        // DepthOnly pass for depth prepass
        Pass
        {
            Name "DepthOnly"
            Tags { "LightMode"="DepthOnly" }
            
            ColorMask 0
            ZWrite On

            HLSLPROGRAM
            #pragma vertex DepthVertex
            #pragma fragment DepthFragment
            #pragma multi_compile _ _COMPUTE_BUFFER

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Common.hlsl"

            struct Attributes
            {
                float4 position : POSITION;
            };

            struct Varyings
            {
                float4 position : SV_Position;
            };

            float4x4 _Transform;

        #if _COMPUTE_BUFFER
            StructuredBuffer<float4> _PointBuffer;
        #endif

        #if _COMPUTE_BUFFER
            Varyings DepthVertex(uint vid : SV_VertexID)
        #else
            Varyings DepthVertex(Attributes input)
        #endif
            {
            #if _COMPUTE_BUFFER
                float4 pt = _PointBuffer[vid];
                float4 pos = mul(_Transform, float4(pt.xyz, 1));
            #else
                float4 pos = input.position;
            #endif

                Varyings o;
                o.position = TransformObjectToHClip(pos.xyz);
                return o;
            }

            half4 DepthFragment(Varyings input) : SV_Target
            {
                return 0;
            }

            ENDHLSL
        }
    }
    
    // Fallback for non-URP
    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue"="Geometry" }
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fog
            #pragma multi_compile _ _DISTANCE_ON
            #pragma multi_compile _COLORORDER_RGB _COLORORDER_BGR _COLORORDER_GBR _COLORORDER_GRB _COLORORDER_BRG _COLORORDER_RBG

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                half3 color : COLOR;
            };

            struct v2f
            {
                float4 pos : SV_Position;
                half3 color : COLOR;
                half psize : PSIZE;
                UNITY_FOG_COORDS(0)
            };

            half4 _Tint;
            half _PointSize;

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

            v2f vert(appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                half3 col = SwapColorChannels(v.color);
                o.color = col * _Tint.rgb * 2;
            #ifdef _DISTANCE_ON
                o.psize = _PointSize / o.pos.w * _ScreenParams.y;
            #else
                o.psize = _PointSize;
            #endif
                UNITY_TRANSFER_FOG(o, o.pos);
                return o;
            }

            half4 frag(v2f i) : SV_Target
            {
                half4 c = half4(i.color, _Tint.a);
                UNITY_APPLY_FOG(i.fogCoord, c);
                return c;
            }
            ENDCG
        }
    }
    
    CustomEditor "Pcx.PointMaterialInspector"
}
