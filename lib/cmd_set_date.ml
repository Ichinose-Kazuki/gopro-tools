open Batch

(* For each *-compressed.mp4 in dir/google_photos, copy EXIF dates from the
   matching original in dir/exported onto it (and onto the dashboard file if
   present). Mirrors set_date.py. *)
let run ~dir : int =
  let target_dir = Filename.concat dir "google_photos" in
  let source_dir = Filename.concat dir "exported" in
  if not (Fs.is_dir target_dir && Fs.is_dir source_dir) then (
    Printf.eprintf "missing google_photos/ or exported/ under %s\n" dir;
    1)
  else
    let compressed =
      Fs.entries target_dir
      |> List.filter (fun f ->
             Fs.has_suffix_ci f ".mp4"
             &&
             let b = Filename.remove_extension f in
             String.length b >= 11
             && String.sub b (String.length b - 11) 11 = "-compressed")
    in
    let jobs =
      List.filter_map
        (fun f ->
          let base =
            let b = Filename.remove_extension f in
            String.sub b 0 (String.length b - 11) (* strip -compressed *)
          in
          let src_u = Filename.concat source_dir (base ^ ".MP4") in
          let src_l = Filename.concat source_dir (base ^ ".mp4") in
          let source =
            if Sys.file_exists src_u then Some src_u
            else if Sys.file_exists src_l then Some src_l
            else None
          in
          match source with
          | None ->
            Printf.printf "skip (no source): %s\n" base;
            None
          | Some source ->
            let targets = [ Filename.concat target_dir f ] in
            let dash = Filename.concat target_dir (base ^ "-dashboard.MP4") in
            let targets =
              if Sys.file_exists dash then targets @ [ dash ] else targets
            in
            Some (source, targets))
        compressed
    in
    (* one batch item per (source,target) pair *)
    let pairs =
      List.concat_map
        (fun (source, targets) -> List.map (fun t -> (source, t)) targets)
        jobs
    in
    let outcomes =
      run_batch pairs (fun (source, target) ->
          let* _ = Proc.run (Clip.set_date_argv ~source ~target) in
          return ())
    in
    let n_ok =
      List.length (List.filter (fun (_, r) -> Result.is_ok r) outcomes)
    in
    let n_fail = List.length outcomes - n_ok in
    Printf.printf "set-date: %d succeeded, %d failed\n" n_ok n_fail;
    List.iter
      (fun ((_, t), r) ->
        match r with
        | Error e ->
          Printf.eprintf "  x %s — %s\n" (Filename.basename t)
            (Error.to_string e)
        | Ok () -> ())
      outcomes;
    if n_fail > 0 then 1 else 0
