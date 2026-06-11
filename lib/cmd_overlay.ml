open Batch

(* Probe WxH of the compressed file via ffprobe. *)
let probe_wxh (clip : Clip.t) : (string, Error.t) result =
  let argv =
    [ "ffprobe"; "-v"; "error"; "-select_streams"; "v:0";
      "-show_entries"; "stream=width,height";
      "-of"; "csv=s=x:p=0"; Clip.compressed_path clip ]
  in
  match Proc.run argv with
  | Error _ as e -> e
  | Ok out -> Ok (String.trim out)

(* Build a clip value for an existing per-clip directory (overlay works on the
   directory produced by compress; source/original are not needed here). *)
let clip_of_dir d : Clip.t =
  let basename = Filename.basename d in
  { source = ""; original = ""; work_dir = d; basename }

let overlay_one ~layout_dir ~venv (clip : Clip.t) : (unit, Error.t) result =
  let* wxh = probe_wxh clip in
  let* _ = Proc.run (Clip.dashboard_argv ~layout_dir ~venv ~wxh clip) in
  return ()

(* single clip dir *)
let run_one ~layout_dir ~venv ~clip_dir : int =
  match overlay_one ~layout_dir ~venv (clip_of_dir clip_dir) with
  | Ok () -> print_endline "dashboard created"; 0
  | Error e -> prerr_endline (Error.to_string e); 1

(* all clip dirs under dir, skipping GPS-unlocked clips per Gpx.decide *)
let run_all ~layout_dir ~venv ~dir : int =
  let dirs = Fs.clip_dirs ~dir in
  let runnable =
    List.filter
      (fun d ->
        let clip = clip_of_dir d in
        match Gpx.parse (Clip.gpx_path clip) with
        | Error e ->
          Printf.printf "[SKIP] %s: %s\n" clip.basename (Error.to_string e);
          false
        | Ok pts ->
          (match Gpx.decide pts with
           | Gpx.Run -> true
           | Gpx.Skip reason ->
             let why =
               match reason with
               | Gpx.No_data -> "no GPS data"
               | Gpx.Origin_fix -> "GPS off (0,0)"
               | Gpx.No_movement -> "no movement"
             in
             Printf.printf "[SKIP] %s: %s\n" clip.basename why;
             false))
      dirs
  in
  let outcomes =
    run_batch runnable (fun d -> overlay_one ~layout_dir ~venv (clip_of_dir d))
  in
  let outcomes = List.map (fun (d, r) -> (clip_of_dir d, r)) outcomes in
  print_endline (Report.summarize outcomes);
  if List.exists (fun (_, r) -> Result.is_error r) outcomes then 1 else 0
