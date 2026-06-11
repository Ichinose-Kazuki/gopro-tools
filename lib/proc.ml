(* The ONLY executor. Runs argv via Unix, captures stdout+stderr,
   maps nonzero exit (or signal) to Error.Command_failed.

   Uses select(2) to drain stdout and stderr concurrently: reading them
   sequentially can deadlock if the child fills one pipe's buffer (~64KB)
   while we are still blocked reading the other. *)

let drain fds =
  let bufs = Hashtbl.create 2 in
  List.iter (fun fd -> Hashtbl.replace bufs fd (Buffer.create 4096)) fds;
  let open_fds = ref fds in
  let chunk = Bytes.create 4096 in
  while !open_fds <> [] do
    let ready, _, _ = Unix.select !open_fds [] [] (-1.0) in
    List.iter
      (fun fd ->
        let n = Unix.read fd chunk 0 (Bytes.length chunk) in
        if n = 0 then open_fds := List.filter (fun f -> f <> fd) !open_fds
        else Buffer.add_subbytes (Hashtbl.find bufs fd) chunk 0 n)
      ready
  done;
  fun fd -> Buffer.contents (Hashtbl.find bufs fd)

let run ?cwd argv =
  match argv with
  | [] ->
    Error (Error.Command_failed { argv; exit_code = -1; stderr = "empty argv" })
  | prog :: _ ->
    let out_r, out_w = Unix.pipe () in
    let err_r, err_w = Unix.pipe () in
    (* Spawn while temporarily chdir'd to ~cwd. Any exception here (bad cwd,
       missing program, EINTR) must not leak the four pipe fds nor escape the
       Result model — close fds and map to Error.Command_failed. *)
    let spawn () =
      let cwd_save = Unix.getcwd () in
      (match cwd with Some d -> Unix.chdir d | None -> ());
      Fun.protect
        ~finally:(fun () -> match cwd with Some _ -> Unix.chdir cwd_save | None -> ())
        (fun () ->
          Unix.create_process prog (Array.of_list argv) Unix.stdin out_w err_w)
    in
    (match spawn () with
     | exception e ->
       List.iter (fun fd -> try Unix.close fd with Unix.Unix_error _ -> ())
         [ out_r; out_w; err_r; err_w ];
       Error
         (Error.Command_failed
            { argv; exit_code = -1; stderr = Printexc.to_string e })
     | pid ->
       Unix.close out_w;
       Unix.close err_w;
       let get = drain [ out_r; err_r ] in
       let stdout = get out_r in
       let stderr = get err_r in
       Unix.close out_r;
       Unix.close err_r;
       let _, status = Unix.waitpid [] pid in
       (match status with
        | Unix.WEXITED 0 -> Ok stdout
        | Unix.WEXITED code ->
          Error (Error.Command_failed { argv; exit_code = code; stderr })
        | Unix.WSIGNALED s | Unix.WSTOPPED s ->
          Error (Error.Command_failed { argv; exit_code = 128 + s; stderr })))
