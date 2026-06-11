(* Explicit destructive cleanup that compress.sh used to do silently.
   Removes dir/exported. Prompts unless ~assume_yes. *)
let rec rm_rf path =
  if Fs.is_dir path then (
    List.iter (fun e -> rm_rf (Filename.concat path e)) (Fs.entries path);
    try Unix.rmdir path with Unix.Unix_error _ -> ())
  else try Sys.remove path with Sys_error _ -> ()

let confirm prompt =
  Printf.printf "%s [y/N] " prompt;
  flush stdout;
  match input_line stdin with
  | exception End_of_file -> false
  | s ->
    (match String.lowercase_ascii (String.trim s) with
     | "y" | "yes" -> true
     | _ -> false)

let run ~dir ~assume_yes : int =
  let exported = Filename.concat dir "exported" in
  if not (Fs.is_dir exported) then (
    Printf.printf "nothing to clean: %s does not exist\n" exported;
    0)
  else if assume_yes || confirm (Printf.sprintf "Remove %s ?" exported) then (
    rm_rf exported;
    Printf.printf "removed %s\n" exported;
    0)
  else (
    print_endline "aborted";
    0)
