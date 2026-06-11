(* Recursively copy .mp4/.jpg into dir/google_photos, skipping existing. *)
let copy_file src dst =
  let ic = open_in_bin src and oc = open_out_bin dst in
  Fun.protect
    ~finally:(fun () -> close_in_noerr ic; close_out_noerr oc)
    (fun () ->
      let len = 65536 in
      let buf = Bytes.create len in
      let rec loop () =
        let n = input ic buf 0 len in
        if n > 0 then (output oc buf 0 n; loop ())
      in
      loop ())

let run ~dir : int =
  let dest = Filename.concat dir "google_photos" in
  Fs.mkdir_p dest;
  Printf.printf "Destination: %s\n" dest;
  let targets = Fs.gather_targets ~dir ~dest in
  let count = ref 0 in
  List.iter
    (fun src ->
      let dst = Filename.concat dest (Filename.basename src) in
      if Sys.file_exists dst then
        Printf.printf "Skipping (exists): %s\n" (Filename.basename src)
      else
        try
          copy_file src dst;
          incr count;
          Printf.printf "Copied: %s\n" (Filename.basename src)
        with Sys_error msg -> Printf.eprintf "Error copying %s: %s\n" src msg)
    targets;
  Printf.printf "--- Completed. %d files copied. ---\n" !count;
  0
