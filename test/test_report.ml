open Gopro

(* substring check — OCaml stdlib has no String.contains for substrings *)
let contains hay needle =
  let nlen = String.length needle and hlen = String.length hay in
  let rec go i =
    if i + nlen > hlen then false
    else if String.sub hay i nlen = needle then true
    else go (i + 1)
  in
  go 0

let clip base : Clip.t =
  { source = base ^ ".mp4"; original = base ^ ".MP4";
    work_dir = base; basename = base }

let test_all_ok () =
  let outcomes = [ (clip "A", Ok ()); (clip "B", Ok ()) ] in
  let s = Report.summarize outcomes in
  Alcotest.(check bool) "mentions 2 succeeded" true (contains s "2 succeeded");
  Alcotest.(check bool) "0 failed" true (contains s "0 failed")

let test_one_failed () =
  let outcomes =
    [ (clip "A", Ok ());
      (clip "GX010017",
       Error (Error.Command_failed
                { argv = [ "ffmpeg"; "-i"; "x" ]; exit_code = 1;
                  stderr = "boom" })) ]
  in
  let s = Report.summarize outcomes in
  Alcotest.(check bool) "1 succeeded" true (contains s "1 succeeded");
  Alcotest.(check bool) "1 failed" true (contains s "1 failed");
  Alcotest.(check bool) "names clip" true (contains s "GX010017")

let () =
  Alcotest.run "report"
    [ ( "summarize",
        [ Alcotest.test_case "all ok" `Quick test_all_ok;
          Alcotest.test_case "one failed" `Quick test_one_failed ] ) ]
