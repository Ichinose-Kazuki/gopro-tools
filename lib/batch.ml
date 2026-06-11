(* Skip-and-continue: attempt every item regardless of earlier failures,
   collect each outcome. Within an item, the step function may short-circuit
   with let* — that is the caller's concern. *)
let run_batch (items : 'a list) (f : 'a -> (unit, Error.t) result) :
    ('a * (unit, Error.t) result) list =
  List.map (fun item -> (item, f item)) items

(* result monad bind for within-item chaining *)
let ( let* ) r f = match r with Ok x -> f x | Error _ as e -> e
let return x = Ok x
