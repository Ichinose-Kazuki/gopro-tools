(* Pure: turn batch outcomes into a human summary string.
   Counts successes/failures and lists each failure with a stderr tail. *)

let stderr_tail s =
  let lines = String.split_on_char '\n' s in
  let last_n n xs =
    let len = List.length xs in
    if len <= n then xs else List.filteri (fun i _ -> i >= len - n) xs
  in
  String.concat "\n" (last_n 3 lines)

let summarize (outcomes : (Clip.t * (unit, Error.t) result) list) =
  let total = List.length outcomes in
  let failures =
    List.filter_map
      (fun (clip, r) -> match r with Ok () -> None | Error e -> Some (clip, e))
      outcomes
  in
  let n_fail = List.length failures in
  let n_ok = total - n_fail in
  let header =
    Printf.sprintf "%d clip(s): %d succeeded, %d failed" total n_ok n_fail
  in
  let lines =
    List.map
      (fun (clip, e) ->
        let detail =
          match e with
          | Error.Command_failed { exit_code; stderr; _ } ->
            Printf.sprintf "exit %d: %s" exit_code (stderr_tail stderr)
          | other -> Error.to_string other
        in
        Printf.sprintf "  x %s — %s" clip.Clip.basename detail)
      failures
  in
  String.concat "\n" (header :: lines)
