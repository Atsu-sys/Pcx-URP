// Pcx - Point cloud importer & renderer for Unity
// https://github.com/keijiro/Pcx

using UnityEngine;
using UnityEditor;

namespace Pcx
{
    class PointMaterialInspector : ShaderGUI
    {
        public override void OnGUI(MaterialEditor editor, MaterialProperty[] props)
        {
            EditorGUI.BeginChangeCheck();
            
            editor.ShaderProperty(FindProperty("_Tint", props), "Tint");
            editor.ShaderProperty(FindProperty("_ColorOrder", props), "Color Order");
            editor.ShaderProperty(FindProperty("_PointSize", props), "Point Size");
            editor.ShaderProperty(FindProperty("_Distance", props), "Apply Distance");
            
            // Rotation as Vector3
            MaterialProperty rotProp = FindProperty("_Rotation", props);
            Vector4 rotVec = rotProp.vectorValue;
            Vector3 newRot = EditorGUILayout.Vector3Field("Rotation", new Vector3(rotVec.x, rotVec.y, rotVec.z));
            rotProp.vectorValue = new Vector4(newRot.x, newRot.y, newRot.z, 0);

            if (EditorGUI.EndChangeCheck())
            {
                foreach (var m in editor.targets)
                    if (m is Material mat)
                    {
                        EditorUtility.SetDirty(mat);
                    }
            }

            EditorGUILayout.HelpBox(
                "Only some platform support these point size properties.",
                MessageType.None
            );
        }
    }

    class DiskMaterialInspector : ShaderGUI
    {
        public override void OnGUI(MaterialEditor editor, MaterialProperty[] props)
        {
            EditorGUI.BeginChangeCheck();

            editor.ShaderProperty(FindProperty("_Tint", props), "Tint");
            editor.ShaderProperty(FindProperty("_ColorOrder", props), "Color Order");
            editor.ShaderProperty(FindProperty("_PointSize", props), "Point Size");
            
            // Rotation as Vector3
            MaterialProperty rotProp = FindProperty("_Rotation", props);
            Vector4 rotVec = rotProp.vectorValue;
            Vector3 newRot = EditorGUILayout.Vector3Field("Rotation", new Vector3(rotVec.x, rotVec.y, rotVec.z));
            rotProp.vectorValue = new Vector4(newRot.x, newRot.y, newRot.z, 0);

            if (EditorGUI.EndChangeCheck())
            {
                foreach (var m in editor.targets)
                    if (m is Material mat) EditorUtility.SetDirty(mat);
            }
        }
    }
}
