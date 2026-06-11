open Gopro

let fixture name = "fixtures/" ^ name

let parse_ok path =
  match Gpx.parse (fixture path) with
  | Ok pts -> pts
  | Error e -> Alcotest.failf "parse failed: %s" (Error.to_string e)

let decision_testable =
  let pp fmt d =
    Format.pp_print_string fmt
      (match d with
       | Gpx.Run -> "Run"
       | Gpx.Skip Gpx.No_data -> "Skip No_data"
       | Gpx.Skip Gpx.Origin_fix -> "Skip Origin_fix"
       | Gpx.Skip Gpx.No_movement -> "Skip No_movement")
  in
  Alcotest.testable pp ( = )

let check_decision name path expected =
  Alcotest.test_case name `Quick (fun () ->
    let pts = parse_ok path in
    Alcotest.check decision_testable name expected (Gpx.decide pts))

let test_empty () =
  let pts = parse_ok "empty.gpx" in
  Alcotest.check decision_testable "empty -> No_data"
    (Gpx.Skip Gpx.No_data) (Gpx.decide pts)

let () =
  Alcotest.run "gpx"
    [ ( "decide",
        [ check_decision "origin" "origin.gpx" (Gpx.Skip Gpx.Origin_fix);
          check_decision "flat" "flat.gpx" (Gpx.Skip Gpx.No_movement);
          check_decision "moving" "moving.gpx" Gpx.Run;
          check_decision "late_lock" "late_lock.gpx" Gpx.Run;
          Alcotest.test_case "empty" `Quick test_empty ] ) ]
