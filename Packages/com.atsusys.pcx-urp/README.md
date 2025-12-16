PCX for URP - Point Cloud Importer/Renderer for Unity
======================================================

![GIF](https://i.imgur.com/zc6P96x.gif)
![GIF](https://i.imgur.com/lpWIiXu.gif)

**PCX for URP** is a custom importer and renderer that allows for handling point cloud data
in Unity with **Universal Render Pipeline (URP)** support.

> **Note**: This is a fork of [keijiro/Pcx](https://github.com/keijiro/Pcx), modified for URP compatibility.

System Requirements
-------------------

- Unity 6 (6000.0 or later)
- Universal Render Pipeline (URP) 17.0.0 or later

Supported Formats
-----------------

Currently PCX only supports PLY binary little-endian format.

How To Install / インストール方法
----------------------------------

### Option 1: Install via Git URL (推奨)

1. Unity エディタで **Window > Package Manager** を開く
2. 左上の **+** ボタンをクリック
3. **Add package from git URL...** を選択
4. 以下のURLを入力して **Add** をクリック:

```
https://github.com/Atsu-sys/Pcx-URP.git?path=Packages/com.atsusys.pcx-urp
```

> **Tip**: 特定のバージョンを指定する場合は、末尾に `#v1.0.0` のようにタグを追加できます。

### Option 2: manifest.json を直接編集

プロジェクトの `Packages/manifest.json` を開き、`dependencies` に以下を追加:

```json
{
  "dependencies": {
    "com.atsusys.pcx-urp": "https://github.com/Atsu-sys/Pcx-URP.git?path=Packages/com.atsusys.pcx-urp",
    ...
  }
}
```

### Option 3: ローカルにクローンして追加

1. このリポジトリをクローン
2. Package Manager で **Add package from disk...** をクリック
3. `Packages/com.atsusys.pcx-urp/package.json` を選択

使い方 / How To Use
-------------------

### Step 1: PLYファイルのインポート

1. `.ply` ファイル（バイナリ・リトルエンディアン形式）をプロジェクトにドラッグ＆ドロップ
2. インポート設定で以下を選択:
   - **Container Type**: `Mesh`, `Compute Buffer`, または `Texture` を選択

![Import Settings](https://i.imgur.com/Da0p6uV.png)

### Step 2A: Mesh方式（シンプル）

MeshRendererを使用する最もシンプルな方法:

1. シーンに空のGameObjectを作成
2. **Mesh Filter** コンポーネントを追加し、インポートしたPLYメッシュを設定
3. **Mesh Renderer** コンポーネントを追加
4. マテリアルを作成し、シェーダーを選択:
   - `Point Cloud/Point URP` - ポイントプリミティブ（軽量）
   - `Point Cloud/Disk URP` - ディスク形状（高品質）
5. マテリアルをMesh Rendererに割り当て

```
GameObject
├── Mesh Filter (PLYメッシュを設定)
└── Mesh Renderer (Point Cloud/Disk URPマテリアル)
```

### Step 2B: PointCloudRenderer方式（ComputeBuffer）

より高度なレンダリング方法:

1. PLYインポート時に **Container Type** を `Compute Buffer` に設定
2. シーンに空のGameObjectを作成
3. **Point Cloud Renderer** コンポーネントを追加
4. **Source Data** にインポートしたPointCloudDataアセットを設定
5. **Point Size** と **Tint** を調整

```
GameObject
└── Point Cloud Renderer
    ├── Source Data: (PointCloudDataアセット)
    ├── Point Tint: 色を設定
    └── Point Size: 0.05 (0=ポイント、0より大=ディスク)
```

### マテリアル設定

| プロパティ | 説明 |
|-----------|------|
| **Tint** | ポイントの色合い |
| **Point Size** | ポイントのサイズ |
| **Apply Distance** | カメラ距離に応じてサイズを調整 |

> **Note**: Point Sizeプロパティは一部のプラットフォーム（OpenGLCore, Metal）でのみサポート。D3D11/12では機能しません。



Container Types
---------------

![Inspector](https://i.imgur.com/Da0p6uV.png)

There are three types of container for point clouds.

### Mesh

Points are to be contained in a `Mesh` object. They can be rendered with the
standard `MeshRenderer` component. It's recommended to use the custom shaders
included in PCX (`Point Cloud/Point URP` and `Point Cloud/Disk URP`).

### ComputeBuffer

Points are to be contained in a `PointCloudData` object, which uses
`ComputeBuffer` to store point data. It can be rendered with using the
`PointCloudRenderer` component.

### Texture

Points are baked into `Texture2D` objects that can be used as attribute maps
in [Visual Effect Graph].

[Visual Effect Graph]: https://unity.com/visual-effect-graph

Rendering Methods
-----------------

There are two types of rendering methods in PCX.

### Point (point primitives)

Points are rendered as point primitives when using the `Point Cloud/Point URP`
shader.

![Points](https://i.imgur.com/aY4QMtb.png)
![Points](https://i.imgur.com/jJAhLI2.png)

The size of points can be adjusted by changing the material properties.

![Inspector](https://i.imgur.com/gEMmxTH.png)

These size properties are only supported on some platforms; It may work with
OpenGLCore and Metal, but never work with D3D11/12.

This method is also used when the point size is set to zero in
`PointCloudRenderer`.

### Disk (geometry shader)

Points are rendered as small disks when using the `Point Cloud/Disk URP` shader or
`PointCloudRenderer`.

![Disks](https://i.imgur.com/fcq5E3m.png)

This method requires geometry shader support.

Changes from Original
---------------------

- **URP Support**: All shaders converted to Universal Render Pipeline
- **Unity 6 Compatible**: Updated minimum Unity version to 6000.0
- **Package Renamed**: Changed from `jp.keijiro.pcx` to `com.atsusys.pcx-urp`

Acknowledgements
----------------

This package is based on [Pcx](https://github.com/keijiro/Pcx) by Keijiro Takahashi.

The point cloud files used in the examples of PCX are created by authors listed
below. These files are licensed under the Creative Commons Attribution license
([CC BY 4.0]). Please see the following original pages for further details.

- richmond-azaelias.ply - Azaleas, Isabella Plantation, Richmond Park.
  Created by [Thomas Flynn].
  https://sketchfab.com/models/188576acfe89480f90c38d9df9a4b19a

- anthidium-forcipatum.ply - Anthidium forcipatum ♀ (Point Cloud).
  Created by [Thomas Flynn].
  https://sketchfab.com/models/3493da15a8db4f34929fc38d9d0fcb2c

- Guanyin.ply - Guanyin (Avalokitesvara). Created by [Geoffrey Marchal].
  https://sketchfab.com/models/9db9a5dfb6744a5586dfcb96cb8a7dc5

[Thomas Flynn]: https://sketchfab.com/nebulousflynn
[Geoffrey Marchal]: https://sketchfab.com/geoffreymarchal
[CC BY 4.0]: https://creativecommons.org/licenses/by/4.0/

License
-------

This package is licensed under the Unlicense. See [LICENSE](LICENSE) for details.
