open Gopro

let test_true () =
  match Proc.run [ "true" ] with
  | Ok _ -> ()
  | Error e -> Alcotest.failf "expected Ok: %s" (Error.to_string e)

let test_false () =
  match Proc.run [ "false" ] with
  | Ok _ -> Alcotest.fail "expected Error for `false`"
  | Error (Error.Command_failed { exit_code; _ }) ->
    Alcotest.(check int) "exit code nonzero, expected 1" 1 exit_code
  | Error e -> Alcotest.failf "wrong error: %s" (Error.to_string e)

let test_stderr_capture () =
  match Proc.run [ "sh"; "-c"; "echo oops 1>&2; exit 2" ] with
  | Error (Error.Command_failed { exit_code; stderr; _ }) ->
    Alcotest.(check int) "exit 2" 2 exit_code;
    Alcotest.(check bool) "captured stderr" true (String.length stderr > 0)
  | _ -> Alcotest.fail "expected Command_failed with stderr"

let test_stdout_capture () =
  match Proc.run [ "sh"; "-c"; "echo hello" ] with
  | Ok out -> Alcotest.(check bool) "captured stdout" true (String.length out > 0)
  | Error e -> Alcotest.failf "expected Ok: %s" (Error.to_string e)

let () =
  Alcotest.run "proc"
    [ ( "run",
        [ Alcotest.test_case "true" `Quick test_true;
          Alcotest.test_case "false" `Quick test_false;
          Alcotest.test_case "stderr" `Quick test_stderr_capture;
          Alcotest.test_case "stdout" `Quick test_stdout_capture ] ) ]
