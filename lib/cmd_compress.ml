open Batch

(* Process one clip: compress -> small -> extract gpx+json -> delete small.
   Within the clip, steps short-circuit (no point extracting from a missing
   small file). Returns one result for the clip. *)
let process_clip ~extract_dir (clip : Clip.t) : (unit, Error.t) result =
  Fs.mkdir_p clip.work_dir;
  let* _ = Proc.run (Clip.compress_argv clip) in
  let* _ = Proc.run (Clip.small_argv clip) in
  let* _ = Proc.run (Clip.extract_json_argv ~extract_dir clip) in
  let* _ = Proc.run (Clip.extract_gpx_argv ~extract_dir clip) in
  (try Sys.remove (Clip.small_path clip) with Sys_error _ -> ());
  return ()

(* dir contains exported/ and the original .MP4 files. extract_dir holds the
   node extractor scripts (repo's extract/). *)
let run ~dir ~extract_dir : int =
  match Fs.discover_clips ~dir with
  | Error e ->
    prerr_endline (Error.to_string e);
    1
  | Ok [] ->
    print_endline "no clips found (need exported/*.mp4 + matching originals)";
    0
  | Ok clips ->
    let outcomes = run_batch clips (process_clip ~extract_dir) in
    print_endline (Report.summarize outcomes);
    if List.exists (fun (_, r) -> Result.is_error r) outcomes then 1 else 0
