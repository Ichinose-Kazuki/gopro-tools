type t =
  | Command_failed of { argv : string list; exit_code : int; stderr : string }
  | Gpx_parse_error of { path : string; msg : string }
  | Missing_file of string

let to_string = function
  | Command_failed { argv; exit_code; stderr } ->
    let cmd = String.concat " " argv in
    Printf.sprintf "command failed (exit %d): %s\n%s" exit_code cmd stderr
  | Gpx_parse_error { path; msg } ->
    Printf.sprintf "GPX parse error in %s: %s" path msg
  | Missing_file path -> Printf.sprintf "missing file: %s" path
