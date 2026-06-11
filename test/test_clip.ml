open Gopro

let sample : Clip.t =
  { source = "/data/exported/GX010017.mp4";
    original = "/data/GX010017.MP4";
    work_dir = "/data/GX010017";
    basename = "GX010017" }

let list_eq = Alcotest.(list string)

let test_compressed_path () =
  Alcotest.(check string) "compressed path"
    "/data/GX010017/GX010017-compressed.MP4"
    (Clip.compressed_path sample)

let test_compress_argv () =
  Alcotest.check list_eq "compress argv"
    [ "ffmpeg"; "-i"; "/data/exported/GX010017.mp4";
      "-vf"; "scale=1920:-1";
      "-map"; "0:v:m:vendor_id"; "-map"; "0:a";
      "-c:v:m:vendor_id"; "libx265"; "-crf"; "23";
      "-c:a"; "copy";
      "/data/GX010017/GX010017-compressed.MP4" ]
    (Clip.compress_argv sample)

let test_small_argv () =
  Alcotest.check list_eq "small argv"
    [ "ffmpeg"; "-i"; "/data/GX010017.MP4";
      "-vf"; "scale=320:-1";
      "-map"; "0:0"; "-map"; "0:1"; "-map"; "0:3";
      "-codec:v"; "mpeg2video"; "-codec:d"; "copy"; "-codec:a"; "copy";
      "-y"; "/data/GX010017/GX010017-small.MP4" ]
    (Clip.small_argv sample)

let test_extract_gpx_argv () =
  Alcotest.check list_eq "extract gpx argv"
    [ "node"; "/repo/extract/extract_gpx.js";
      "/data/GX010017/GX010017-small.MP4";
      "/data/GX010017/GX010017-GPS5.gpx" ]
    (Clip.extract_gpx_argv ~extract_dir:"/repo/extract" sample)

let test_extract_json_argv () =
  Alcotest.check list_eq "extract json argv"
    [ "node"; "/repo/extract/extract_json.js";
      "/data/GX010017/GX010017-small.MP4";
      "/data/GX010017/GX010017-metadata.json" ]
    (Clip.extract_json_argv ~extract_dir:"/repo/extract" sample)

let test_set_date_argv () =
  Alcotest.check list_eq "set-date argv"
    [ "exiftool"; "-overwrite_original";
      "-TagsFromFile"; "/data/GX010017.MP4";
      "-TrackCreateDate<MediaCreateDate";
      "-TrackModifyDate<MediaCreateDate";
      "-MediaCreateDate<MediaCreateDate";
      "-MediaModifyDate<MediaCreateDate";
      "-CreateDate<MediaCreateDate";
      "-ModifyDate<MediaCreateDate";
      "/data/out/GX010017-compressed.MP4" ]
    (Clip.set_date_argv ~source:"/data/GX010017.MP4"
       ~target:"/data/out/GX010017-compressed.MP4")

let () =
  Alcotest.run "clip"
    [ ( "paths", [ Alcotest.test_case "compressed" `Quick test_compressed_path ] );
      ( "argv",
        [ Alcotest.test_case "compress" `Quick test_compress_argv;
          Alcotest.test_case "small" `Quick test_small_argv;
          Alcotest.test_case "extract_gpx" `Quick test_extract_gpx_argv;
          Alcotest.test_case "extract_json" `Quick test_extract_json_argv;
          Alcotest.test_case "set_date" `Quick test_set_date_argv ] ) ]
