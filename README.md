# gopro-tools
- 作ってから気づいたけど公式からこんなソフトが出ていた: https://gopro.com/en/us/info/gopro-player
  - 一括エクスポートでは
    - メタデータが失われる
    - 圧縮品質の設定がほとんどできない
    - 手ぶれ補正がかかった状態の動画がエクスポートされる
      - 手ブレ補正は公式のを使うべき
  - したがって、一括エクスポートとは別にメタデータ抽出と圧縮もしたほうがよさそう
- GoPro で撮影した MP4 動画を、GoPro 特有のメタデータを維持しながら圧縮する。
- GPS 情報を重ねた動画を作成する。

## 使い方
- GoPro HERO 13 を想定
- （Windows）GoPro Player でとりあえず exported という名前のフォルダにエクスポートする
  -　コーデックは HEVC
  - 解像度最大
  - ビットレートは最大にする
  - HyperSmooth Pro を有効にする
    - 設定はとりあえずデフォルト（滑らかさ: 50, トリミング速度: 50, レンズ補正: 0）
    - アスペクト比だけ 1:1 に修正する
- 以下 Linux
- （これはやらない）ディレクトリの中の全 MP4 ファイルの名前を撮影日時に変更
  
  [issue のコメント](https://github.com/time4tea/gopro-dashboard-overlay/issues/117#issuecomment-1464979791) によれば、録画ボタンを押して起動したときは `GPS never locked` エラーになる。たしかに ffprobe で見たときに `creation_time` の日時が明らかに撮影日時と異なる。
  rename はしないほうがよさそう。
  
  ```shell
  .venv/bin/gopro-rename.py --yes --dirs [ディレクトリへのパス]
  ```
- ディレクトリの中の全 MP4 ファイルを圧縮
  
  ffmpeg で圧縮しても gpmd は維持されるが、メタデータが取れなかったりする。creation_time だけは復元できたが、dashboard を作ったときに速度表示がおかしくなった。しかたないので gopro-telemetry を使って gpx とその他メタデータを分離する方針とする。

  exported ディレクトリの一個上で実行する。

  動画サイズは横幅 1920 になる。
  
  ```shell
  bash bin/compress.sh [ディレクトリへのパス]
  ```

  metadata ファイルの中に出てくるキー一覧

  ```
  """streams""ACCL""samples""value""cts""date""TZ""sticky""temperature °C""name""Accelerometer""units""m/s²""GYRO""Gyroscope""rad/s""SHUT""Exposure time (shutter speed)""s""WBAL""White Balance temperature (Kelvin)""WRGB""White Balance RGB gains""ISOE""Sensor ISO""YAVG""Average luminance""UNIF""Image uniformity""SCEN""Scene classification  | CLASSIFIER (snowurbanindoorwatervegetationbeach)""prob""HUES""Predominant hue  | hue ()""weight""GPS""altitude system""MSLV""GPS (Lat Long Alt D D days secs DOP fix)""deg""m""m/s""CORI""CameraOrientation""IORI""ImageOrientation""GRAV""Gravity Vector""WNDM""Wind Processingwind_enable meter_value(  )""MWET""Microphone Wetmic_wet all_mics confidence""AALP""AGC audio levelrms_level peak_level""dBFS""MSKP""MRV Frame Skip""LSKP""LRVO""LRVS""LRV Frame Skip""CSCM""Compression Score Main""FACE""Face Coordinates and details (verconfidence %xywhsmile % blink %)""subStreamName""ID""LOGS"null"device name""HERO Black""frames/second"% 
  ```

- ディレクトリ内の動画に gpx ファイルの情報を重ねた動画をそのディレクトリ内に作成

  GPS5 の値が全く変わらない動画があることがある。撮影方法に問題があるのかは謎。gpx ファイルの抽出に問題があるわけではなくて、動画内のメタデータの値に変化がないということは公式の [gpmf-parser](https://github.com/gopro/gpmf-parser/tree/main) を使って確認済み。

  原因がわかった。
  > GoProのGPS機能は、録画開始前に衛星信号をしっかり「ロック」する必要があります。カメラの画面にGPSアイコンが表示され、白く点灯（固まる）するまで待たないと、位置データが正しく記録されないか、最初の位置だけが固定されて変化しなくなります。ロックには20〜60秒かかることがあり、スキー場のような山岳地帯では信号が弱く、時間がさらにかかるか失敗しやすいです。
  
  gopro-rename のところで書いたことも合わせると、電源オフ状態から録画ボタンを押して起動 & 録画開始したときは、GPS がロックされず、位置情報が得られないということっぽい。

  GPS がロックされている動画全部に対して実行

  ```shell
  python bin/make-dashboard-all.py [ディレクトリへのパス]
  ```

  または一つの動画のみに対して実行

  ```shell
  bash bin/make-dashboard.sh [動画個別ディレクトリへのパス]
  ```

- Google Photos に保存する動画・画像を集める

  ```shell
  python bin/gather_videos_photos.py [ディレクトリへのパス]
  ```

- 動画の作成日時等を修正

  TOOD: 写真についてもやる。電源オフ状態から撮影ボタンを押して撮影されたと思われる写真は Create Date 等がデフォルト値だった。

  ```shell
  python bin/set_date.py [ディレクトリへのパス]
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

## GoPro's MP4 Structure
Telemetry carrying MP4 files will have a minimum of four tracks: Video, audio, timecode and telemetry (GPMF). A fifth track ('SOS') is used in file recovery in HERO4 and HERO5, can be ignored.
