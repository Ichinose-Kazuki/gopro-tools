# gopro_linux
GoPro で撮影した MP4 動画を、GoPro 特有のメタデータを維持しながら圧縮する。

## GoPro で撮影した MP4 動画の構造
`ffprobe GH010057.MP4` の結果 (以下、動画ファイルは `input.MP4` に名前を変更)
- Stream #0:0\[0x1\](eng): Video: h264 (High) (avc1 / 0x31637661), ...
    - handler_name: GoPro AVC
    - ここだけ圧縮したい
- Stream #0:1\[0x2\](eng): Audio: aac (LC) (mp4a / 0x6134706D), ...
    - handler_name: GoPro AAC
- Stream #0:2\[0x3\](eng): Data: none (tmcd / 0x64636D74), 0 kb/s (default)
    - handler_name: GoPro TCD 
- Stream #0:3\[0x4\](eng): Data: bin_data (gpmd / 0x646D7067), 61 kb/s (default)
    - handler_name: GoPro MET
- Stream #0:4\[0x5\](eng): Data: none (fdsc / 0x63736466), 14 kb/s (default)
    - handler_name: GoPro SOS

ffmpeg は、Stream #0:2 から Stream #0:4 について、非対応のコーデックだという警告を出す。
`ffmpeg -i input.MP4 -vcodec libx264 -crf 28 output.MP4` とすると、Stream mapping: でこれらは無視される。
`ffprobe output.MP4` をすると、
- Stream #0:2\[0x3\](eng): Data: none (tmcd / 0x64636D74), 0 kb/s の handler_name が GoPro AVC に変わっている
    

`ffprobe GH010057.MP4` の出力
```
[mov,mp4,m4a,3gp,3g2,mj2 @ 0x1367f980] All samples in data stream index:id [4:5] have zero duration, stream set to be discarded by default. Override using AVStream->discard or -discard for ffmpeg command.
Input #0, mov,mp4,m4a,3gp,3g2,mj2, from 'GH010057.MP4':
  Metadata:
    major_brand     : mp41
    minor_version   : 538120216
    compatible_brands: mp41
    creation_time   : 2025-01-25T11:49:43.000000Z
    firmware        : HD9.01.01.72.00
  Duration: 00:00:26.58, start: 0.000000, bitrate: 45364 kb/s
  Stream #0:0[0x1](eng): Video: h264 (High) (avc1 / 0x31637661), yuvj420p(pc, bt709, progressive), 1920x1080 [SAR 1:1 DAR 16:9], 45077 kb/s, 59.94 fps, 59.94 tbr, 60k tbn (default)
      Metadata:
        creation_time   : 2025-01-25T11:49:43.000000Z
        handler_name    : GoPro AVC  
        vendor_id       : [0][0][0][0]
        encoder         : GoPro AVC encoder
        timecode        : 11:49:00:39
      Side data:
        displaymatrix: rotation of -180.00 degrees
  Stream #0:1[0x2](eng): Audio: aac (LC) (mp4a / 0x6134706D), 48000 Hz, stereo, fltp, 189 kb/s (default)
      Metadata:
        creation_time   : 2025-01-25T11:49:43.000000Z
        handler_name    : GoPro AAC  
        vendor_id       : [0][0][0][0]
        timecode        : 11:49:00:39
  Stream #0:2[0x3](eng): Data: none (tmcd / 0x64636D74), 0 kb/s (default)
      Metadata:
        creation_time   : 2025-01-25T11:49:43.000000Z
        handler_name    : GoPro TCD  
        timecode        : 11:49:00:39
  Stream #0:3[0x4](eng): Data: bin_data (gpmd / 0x646D7067), 61 kb/s (default)
      Metadata:
        creation_time   : 2025-01-25T11:49:43.000000Z
        handler_name    : GoPro MET  
  Stream #0:4[0x5](eng): Data: none (fdsc / 0x63736466), 14 kb/s (default)
      Metadata:
        creation_time   : 2025-01-25T11:49:43.000000Z
        handler_name    : GoPro SOS  
Unsupported codec with id 0 for input stream 2
Unsupported codec with id 98314 for input stream 3
Unsupported codec with id 0 for input stream 4
```

`ffmpeg -i input.MP4 -vcodec libx264 -crf 28 output.MP4` の出力
```
[mov,mp4,m4a,3gp,3g2,mj2 @ 0x32657d00] All samples in data stream index:id [4:5] have zero duration, stream set to be discarded by default. Override using AVStream->discard or -discard for ffmpeg command.
Input #0, mov,mp4,m4a,3gp,3g2,mj2, from 'input.MP4':
  Metadata:
    major_brand     : mp41
    minor_version   : 538120216
    compatible_brands: mp41
    creation_time   : 2025-01-25T11:49:43.000000Z
    firmware        : HD9.01.01.72.00
  Duration: 00:00:26.58, start: 0.000000, bitrate: 45364 kb/s
  Stream #0:0[0x1](eng): Video: h264 (High) (avc1 / 0x31637661), yuvj420p(pc, bt709, progressive), 1920x1080 [SAR 1:1 DAR 16:9], 45077 kb/s, 59.94 fps, 59.94 tbr, 60k tbn (default)
      Metadata:
        creation_time   : 2025-01-25T11:49:43.000000Z
        handler_name    : GoPro AVC  
        vendor_id       : [0][0][0][0]
        encoder         : GoPro AVC encoder
        timecode        : 11:49:00:39
      Side data:
        displaymatrix: rotation of -180.00 degrees
  Stream #0:1[0x2](eng): Audio: aac (LC) (mp4a / 0x6134706D), 48000 Hz, stereo, fltp, 189 kb/s (default)
      Metadata:
        creation_time   : 2025-01-25T11:49:43.000000Z
        handler_name    : GoPro AAC  
        vendor_id       : [0][0][0][0]
        timecode        : 11:49:00:39
  Stream #0:2[0x3](eng): Data: none (tmcd / 0x64636D74), 0 kb/s (default)
      Metadata:
        creation_time   : 2025-01-25T11:49:43.000000Z
        handler_name    : GoPro TCD  
        timecode        : 11:49:00:39
  Stream #0:3[0x4](eng): Data: bin_data (gpmd / 0x646D7067), 61 kb/s (default)
      Metadata:
        creation_time   : 2025-01-25T11:49:43.000000Z
        handler_name    : GoPro MET  
  Stream #0:4[0x5](eng): Data: none (fdsc / 0x63736466), 14 kb/s (default)
      Metadata:
        creation_time   : 2025-01-25T11:49:43.000000Z
        handler_name    : GoPro SOS  
Stream mapping:
  Stream #0:0 -> #0:0 (h264 (native) -> h264 (libx264))
  Stream #0:1 -> #0:1 (aac (native) -> aac (native))
Press [q] to stop, [?] for help
[libx264 @ 0x3265eb40] using SAR=1/1
[libx264 @ 0x3265eb40] using cpu capabilities: MMX2 SSE2Fast SSSE3 SSE4.2 AVX FMA3 BMI2 AVX2
[libx264 @ 0x3265eb40] profile High, level 4.2, 4:2:0, 8-bit
[libx264 @ 0x3265eb40] 264 - core 164 - H.264/MPEG-4 AVC codec - Copyleft 2003-2023 - http://www.videolan.org/x264.html - options: cabac=1 ref=3 deblock=1:0:0 analyse=0x3:0x113 me=hex subme=7 psy=1 psy_rd=1.00:0.00 mixed_ref=1 me_range=16 chroma_me=1 trellis=1 8x8dct=1 cqm=0 deadzone=21,11 fast_pskip=1 chroma_qp_offset=-2 threads=34 lookahead_threads=5 sliced_threads=0 nr=0 decimate=1 interlaced=0 bluray_compat=0 constrained_intra=0 bframes=3 b_pyramid=2 b_adapt=1 b_bias=0 direct=1 weightb=1 open_gop=0 weightp=2 keyint=250 keyint_min=25 scenecut=40 intra_refresh=0 rc_lookahead=40 rc=crf mbtree=1 crf=28.0 qcomp=0.60 qpmin=0 qpmax=69 qpstep=4 ip_ratio=1.40 aq=1:1.00
Output #0, mp4, to 'output.MP4':
  Metadata:
    major_brand     : mp41
    minor_version   : 538120216
    compatible_brands: mp41
    firmware        : HD9.01.01.72.00
    encoder         : Lavf61.7.100
  Stream #0:0(eng): Video: h264 (avc1 / 0x31637661), yuvj420p(pc, bt709, progressive), 1920x1080 [SAR 1:1 DAR 16:9], q=2-31, 59.94 fps, 60k tbn (default)
      Metadata:
        creation_time   : 2025-01-25T11:49:43.000000Z
        handler_name    : GoPro AVC  
        vendor_id       : [0][0][0][0]
        timecode        : 11:49:00:39
        encoder         : Lavc61.19.100 libx264
      Side data:
        cpb: bitrate max/min/avg: 0/0/0 buffer size: 0 vbv_delay: N/A
  Stream #0:1(eng): Audio: aac (LC) (mp4a / 0x6134706D), 48000 Hz, stereo, fltp, 128 kb/s (default)
      Metadata:
        creation_time   : 2025-01-25T11:49:43.000000Z
        handler_name    : GoPro AAC  
        vendor_id       : [0][0][0][0]
        timecode        : 11:49:00:39
        encoder         : Lavc61.19.100 aac
[out#0/mp4 @ 0x326d0040] video:10211KiB audio:415KiB subtitle:0KiB other streams:0KiB global headers:0KiB muxing overhead: 0.406878%
frame= 1593 fps=245 q=-1.0 Lsize=   10670KiB time=00:00:26.54 bitrate=3293.1kbits/s speed=4.08x    
[libx264 @ 0x3265eb40] frame I:7     Avg QP:27.14  size: 46883
[libx264 @ 0x3265eb40] frame P:401   Avg QP:30.75  size: 13995
[libx264 @ 0x3265eb40] frame B:1185  Avg QP:33.69  size:  3811
[libx264 @ 0x3265eb40] consecutive B-frames:  0.8%  0.0%  0.0% 99.2%
[libx264 @ 0x3265eb40] mb I  I16..4: 41.4% 50.4%  8.3%
[libx264 @ 0x3265eb40] mb P  I16..4:  4.0%  2.3%  0.1%  P16..4: 18.0%  4.5%  2.9%  0.0%  0.0%    skip:68.2%
[libx264 @ 0x3265eb40] mb B  I16..4:  0.1%  0.1%  0.0%  B16..8: 31.5%  0.9%  0.2%  direct: 0.3%  skip:66.8%  L0:44.8% L1:54.0% BI: 1.2%
[libx264 @ 0x3265eb40] 8x8 transform intra:39.7% inter:72.0%
[libx264 @ 0x3265eb40] coded y,uvDC,uvAC intra: 10.7% 10.3% 0.4% inter: 3.6% 0.5% 0.0%
[libx264 @ 0x3265eb40] i16 v,h,dc,p: 41% 31% 13% 14%
[libx264 @ 0x3265eb40] i8 v,h,dc,ddl,ddr,vr,hd,vl,hu: 12%  8% 71%  2%  1%  1%  2%  1%  2%
[libx264 @ 0x3265eb40] i4 v,h,dc,ddl,ddr,vr,hd,vl,hu: 18% 19% 27%  5%  6%  6% 10%  5%  5%
[libx264 @ 0x3265eb40] i8c dc,h,v,p: 91%  5%  4%  0%
[libx264 @ 0x3265eb40] Weighted P-Frames: Y:0.2% UV:0.2%
[libx264 @ 0x3265eb40] ref P L0: 53.6% 12.8% 25.1%  8.5%  0.0%
[libx264 @ 0x3265eb40] ref B L0: 84.6% 12.4%  3.0%
[libx264 @ 0x3265eb40] ref B L1: 94.2%  5.8%
[libx264 @ 0x3265eb40] kb/s:3147.40
[aac @ 0x335eb200] Qavg: 1546.207
```
