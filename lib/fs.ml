let is_dir p = try Sys.is_directory p with Sys_error _ -> false

let entries dir =
  try Array.to_list (Sys.readdir dir) with Sys_error _ -> []

let has_suffix_ci s suffix =
  let s = String.lowercase_ascii s and suffix = String.lowercase_ascii suffix in
  let ls = String.length s and lx = String.length suffix in
  ls >= lx && String.sub s (ls - lx) lx = suffix

(* compress: pair each exported/<base>.mp4 with its original <base>.MP4 in dir.
   work_dir is dir/<base>. *)
let discover_clips ~dir : (Clip.t list, Error.t) result =
  let exported = Filename.concat dir "exported" in
  if not (is_dir exported) then Error (Error.Missing_file exported)
  else
    let clips =
      entries exported
      |> List.filter (fun f -> has_suffix_ci f ".mp4")
      |> List.filter_map (fun f ->
             let base = Filename.remove_extension f in
             let original_upper = Filename.concat dir (base ^ ".MP4") in
             let original_lower = Filename.concat dir (base ^ ".mp4") in
             let original =
               if Sys.file_exists original_upper then Some original_upper
               else if Sys.file_exists original_lower then Some original_lower
               else None
             in
             match original with
             | None -> None
             | Some original ->
               Some
                 { Clip.source = Filename.concat exported f;
                   original;
                   work_dir = Filename.concat dir base;
                   basename = base })
    in
    Ok clips

(* overlay-all: subdirectories of dir that contain a *.gpx file *)
let clip_dirs ~dir : string list =
  entries dir
  |> List.map (Filename.concat dir)
  |> List.filter is_dir
  |> List.filter (fun d ->
         entries d |> List.exists (fun f -> has_suffix_ci f ".gpx"))

(* True if p is a symlink (do NOT descend these — avoids directory cycles). *)
let is_symlink p =
  try (Unix.lstat p).Unix.st_kind = Unix.S_LNK with Unix.Unix_error _ -> false

(* gather: all .mp4/.jpg files anywhere under dir, excluding the dest dir.
   Symlinked directories are not descended, so a cycle (e.g. sub -> ..) cannot
   cause infinite recursion. *)
let gather_targets ~dir ~dest : string list =
  let rec walk acc d =
    List.fold_left
      (fun acc name ->
        let p = Filename.concat d name in
        if is_dir p && not (is_symlink p) then
          if p = dest then acc else walk acc p
        else if (not (is_dir p))
                && (has_suffix_ci p ".mp4" || has_suffix_ci p ".jpg")
        then p :: acc
        else acc)
      acc (entries d)
  in
  List.rev (walk [] dir)

let mkdir_p dir =
  let rec go d =
    if d = "" || d = "/" || Sys.file_exists d then ()
    else (
      go (Filename.dirname d);
      try Unix.mkdir d 0o755
      with Unix.Unix_error (Unix.EEXIST, _, _) -> ())
  in
  go dir
