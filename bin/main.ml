open Cmdliner
open Gopro

(* default helper locations relative to the repo root passed as --repo *)
let repo_arg =
  let doc = "Repo root holding extract/, dashboard/, and .venv (default: cwd)." in
  Arg.(value & opt string "." & info [ "repo" ] ~doc ~docv:"DIR")

let dir_arg =
  let doc = "Target directory to process." in
  Arg.(required & pos 0 (some string) None & info [] ~doc ~docv:"DIR")

let compress_cmd =
  let run repo dir =
    exit (Cmd_compress.run ~dir ~extract_dir:(Filename.concat repo "extract"))
  in
  let doc = "Compress exported MP4s and extract telemetry (gpx+json)." in
  Cmd.v (Cmd.info "compress" ~doc) Term.(const run $ repo_arg $ dir_arg)

let overlay_cmd =
  let run repo clip_dir =
    exit
      (Cmd_overlay.run_one
         ~layout_dir:(Filename.concat repo "dashboard")
         ~venv:(Filename.concat repo ".venv") ~clip_dir)
  in
  let doc = "Burn a GPS dashboard overlay onto one clip directory." in
  Cmd.v (Cmd.info "overlay" ~doc) Term.(const run $ repo_arg $ dir_arg)

let overlay_all_cmd =
  let run repo dir =
    exit
      (Cmd_overlay.run_all
         ~layout_dir:(Filename.concat repo "dashboard")
         ~venv:(Filename.concat repo ".venv") ~dir)
  in
  let doc = "Overlay all GPS-locked clips under a directory." in
  Cmd.v (Cmd.info "overlay-all" ~doc) Term.(const run $ repo_arg $ dir_arg)

let gather_cmd =
  let run dir = exit (Cmd_gather.run ~dir) in
  let doc = "Collect .mp4/.jpg into google_photos/." in
  Cmd.v (Cmd.info "gather" ~doc) Term.(const run $ dir_arg)

let set_date_cmd =
  let run dir = exit (Cmd_set_date.run ~dir) in
  let doc = "Copy EXIF dates from originals onto compressed/dashboard files." in
  Cmd.v (Cmd.info "set-date" ~doc) Term.(const run $ dir_arg)

let clean_cmd =
  let yes =
    Arg.(value & flag & info [ "yes"; "y" ] ~doc:"Do not prompt for confirmation.")
  in
  let run dir assume_yes = exit (Cmd_clean.run ~dir ~assume_yes) in
  let doc = "Explicitly remove the exported/ source directory." in
  Cmd.v (Cmd.info "clean" ~doc) Term.(const run $ dir_arg $ yes)

let () =
  let doc = "GoPro footage post-processing tools." in
  let info = Cmd.info "gopro" ~version:"0.1.0" ~doc in
  let group =
    Cmd.group info
      [ compress_cmd; overlay_cmd; overlay_all_cmd; gather_cmd; set_date_cmd;
        clean_cmd ]
  in
  exit (Cmd.eval group)
