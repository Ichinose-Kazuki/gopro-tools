type t = {
  source : string;    (* exported/<base>.mp4 — GoPro Player export *)
  original : string;  (* <base>.MP4 — untouched original (telemetry/dates) *)
  work_dir : string;  (* <dir>/<base>/ — per-clip output dir *)
  basename : string;  (* e.g. GX010017 *)
}

let derived t suffix = Filename.concat t.work_dir (t.basename ^ suffix)

let compressed_path t = derived t "-compressed.MP4"
let small_path t = derived t "-small.MP4"
let gpx_path t = derived t "-GPS5.gpx"
let metadata_path t = derived t "-metadata.json"
let dashboard_path t = derived t "-dashboard.MP4"

(* Mirror compress.sh exactly. *)
let compress_argv t =
  [ "ffmpeg"; "-i"; t.source;
    "-vf"; "scale=1920:-1";
    "-map"; "0:v:m:vendor_id"; "-map"; "0:a";
    "-c:v:m:vendor_id"; "libx265"; "-crf"; "23";
    "-c:a"; "copy";
    compressed_path t ]

let small_argv t =
  [ "ffmpeg"; "-i"; t.original;
    "-vf"; "scale=320:-1";
    "-map"; "0:0"; "-map"; "0:1"; "-map"; "0:3";
    "-codec:v"; "mpeg2video"; "-codec:d"; "copy"; "-codec:a"; "copy";
    "-y"; small_path t ]

let extract_gpx_argv ~extract_dir t =
  [ "node"; Filename.concat extract_dir "extract_gpx.js";
    small_path t; gpx_path t ]

let extract_json_argv ~extract_dir t =
  [ "node"; Filename.concat extract_dir "extract_json.js";
    small_path t; metadata_path t ]

(* Mirror set_date.py's six tag copies. *)
let set_date_argv ~source ~target =
  [ "exiftool"; "-overwrite_original";
    "-TagsFromFile"; source;
    "-TrackCreateDate<MediaCreateDate";
    "-TrackModifyDate<MediaCreateDate";
    "-MediaCreateDate<MediaCreateDate";
    "-MediaModifyDate<MediaCreateDate";
    "-CreateDate<MediaCreateDate";
    "-ModifyDate<MediaCreateDate";
    target ]

(* layout file chosen by resolution string e.g. "1920x1080". *)
let dashboard_argv ~layout_dir ~venv ~wxh t =
  [ Filename.concat venv "bin/gopro-dashboard.py";
    "--gpx"; gpx_path t;
    "--use-gpx-only";
    "--layout-xml"; Filename.concat layout_dir (Printf.sprintf "layout-%s.xml" wxh);
    "--units-speed"; "kph";
    "--units-altitude"; "meter";
    "--units-distance"; "meter";
    compressed_path t;
    dashboard_path t ]
