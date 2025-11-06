# gopro-tools
- GoPro で撮影した MP4 動画を、GoPro 特有のメタデータを維持しながら圧縮する。
- GPS 情報を重ねた動画を作成する。

## 使い方
- ディレクトリの中の全 MP4 ファイルの名前を撮影日時に変更
  [issue のコメント](https://github.com/time4tea/gopro-dashboard-overlay/issues/117#issuecomment-1464979791) によれば、録画ボタンを押して起動したときは `GPS never locked` エラーになる。たしかに ffprobe で見たときに `creation_time` の日時が明らかに撮影日時と異なる。
  rename はしないほうがよさそう。
  ```shell
  .venv/bin/gopro-rename.py --yes --dirs [ディレクトリへのパス]
  ```
- ディレクトリの中の全 MP4 ファイルを圧縮
  ```shell
  bash bin/compress.sh [ディレクトリへのパス]
  ```
- ディレクトリ内の動画に gpx ファイルの情報を重ねた動画をそのディレクトリ内に作成
  ```shell
  bash bin/make-dashboard.sh [ディレクトリへのパス]
  ```

## 圧縮率
- 元動画: 144M
- 圧縮後動画: 27M
- gpx メタデータ: 104K
- json メタデータ: 2.6M (gpx とかぶるデータを消しても 0.1M しか消えない（当たり前）)

## GPX ファイルの利用方法
- https://github.com/time4tea/gopro-dashboard-overlay を使う
  - 引数: https://github.com/time4tea/gopro-dashboard-overlay/tree/main/docs/bin
  - 実行例
    ```shell
    .venv/bin/gopro-dashboard.py --gpx output.gpx --use-gpx-only --layout-xml dashboard/layout-1920x1080.xml --units-speed kph --units-altitude meter --units-distance meter videos/video-compressed.MP4 video-compressed-dashboard.MP4
    ```

## GoPro から動画を取り込む方法
1. GoPro を USB で接続する
2. GoPro の電源を入れる
   - ここで `lsusb` すると GoPro HERO9 などの名前でデバイスが認識されているはず
3. GoPro9 は、USB 接続モードを MTP にする
   - [GoPro Support](https://community.gopro.com/s/article/GoPro-Quik-Wired-Camera-Connection?language=ja)
4. `sudo mtp-detect` が成功すれば接続完了
5. 適当なディレクトリを作って `sudo jmtpfs [dirName] -o allow_other` でマウントすると、通常ユーザーで動画ファイルにアクセスできるようになる
   - DCIM/100GOPRO の中には 3 種類のファイルが入っている。MP4 だけコピーすればいい。
   - 写真を撮ったときは JPG も忘れずに！
6. 動画のコピーが終わったら `sudo umount [dirName]` でアンマウント

| ファイル形式 | 用途 | 解像度/サイズ | 特徴 |
| --- | --- | --- | --- |
| MP4 | 高品質な映像保存 | 高解像度、大容量 | 編集・共有向け、高い互換性 |
| LRV | プレビュー・クイック編集用 | 240p、小容量 | 操作負荷軽減、拡張子変更で再生可能 |
| THM | サムネイル表示 | 160x120ピクセル | 動画識別用、小さな画像 |
