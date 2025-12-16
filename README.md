PCX for URP - Point Cloud Importer/Renderer for Unity
======================================================

![GIF](https://i.imgur.com/zc6P96x.gif)
![GIF](https://i.imgur.com/lpWIiXu.gif)

**PCX for URP** is a custom importer and renderer that allows for handling point cloud data
in Unity with **Universal Render Pipeline (URP)** support.

> **Note**: This is a fork of [keijiro/Pcx](https://github.com/keijiro/Pcx), modified for URP compatibility.

## System Requirements

- Unity 6 (6000.0 or later)
- Universal Render Pipeline (URP) 17.0.0 or later

## How To Install / インストール方法

### Option 1: Install via Git URL (推奨)

1. Unity エディタで **Window > Package Manager** を開く
2. 左上の **+** ボタンをクリック
3. **Add package from git URL...** を選択
4. 以下のURLを入力して **Add** をクリック:

```
https://github.com/Atsu-sys/Pcx-URP.git?path=Packages/com.atsusys.pcx-urp
```

> **Note**: 特定のバージョンを指定する場合は、末尾に `#v1.0.0` のようにタグを追加できます。

### Option 2: manifest.json を直接編集

`Packages/manifest.json` を開き、`dependencies` に以下を追加:

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

## Quick Start / クイックスタート

### 方法1: Mesh + MeshRenderer（シンプル）

1. `.ply` ファイルをプロジェクトにインポート（Container Type: `Mesh`）
2. GameObjectに **Mesh Filter** と **Mesh Renderer** を追加
3. マテリアルに `Point Cloud/Point URP` または `Point Cloud/Disk URP` を使用

### 方法2: PointCloudRenderer（ComputeBuffer）

1. `.ply` ファイルをインポート（Container Type: `Compute Buffer`）
2. GameObjectに **Point Cloud Renderer** コンポーネントを追加
3. **Source Data** に PointCloudData アセットを設定

> 詳細は [パッケージREADME](Packages/com.atsusys.pcx-urp/README.md) を参照

## Documentation

See the [package README](Packages/com.atsusys.pcx-urp/README.md) for detailed usage instructions.


## Changes from Original

- **URP Support**: All shaders converted to Universal Render Pipeline
- **Unity 6 Compatible**: Updated minimum Unity version to 6000.0
- **Package Renamed**: Changed from `jp.keijiro.pcx` to `com.atsusys.pcx-urp`

## Acknowledgements

This package is based on [Pcx](https://github.com/keijiro/Pcx) by Keijiro Takahashi.

## License

This package is licensed under the Unlicense. See [LICENSE](LICENSE) for details.
