type point = { lat : float; lon : float }

type skip_reason = No_data | Origin_fix | No_movement
type decision = Run | Skip of skip_reason

(* Minimum span (in degrees) across the whole track for it to count as real
   movement. ~1e-4 deg is roughly 11 m of latitude — below GPS jitter we treat
   the track as stationary. Named, not a magic number. *)
let movement_min_deg = 1e-4

(* GoPro emits a literal (0.0, 0.0) when GPS is OFF. This is a sentinel flag,
   NOT a measurement, so EXACT equality is correct. Do not replace with an
   epsilon proximity test — a genuine coordinate near (0,0) would be wrongly
   skipped. *)
let is_gps_off_sentinel p = p.lat = 0.0 && p.lon = 0.0

(* Parse every trkpt (any element carrying lat & lon attributes) in document
   order using xmlm's streaming pull parser. *)
let parse path =
  match open_in path with
  | exception Sys_error msg -> Error (Error.Missing_file (path ^ ": " ^ msg))
  | ic ->
    Fun.protect
      ~finally:(fun () -> close_in_noerr ic)
      (fun () ->
        let input = Xmlm.make_input (`Channel ic) in
        let points = ref [] in
        let read_attrs attrs =
          let find n =
            List.find_map
              (fun ((_, name), v) -> if name = n then Some v else None)
              attrs
          in
          match (find "lat", find "lon") with
          | Some lat_s, Some lon_s ->
            (match (float_of_string_opt lat_s, float_of_string_opt lon_s) with
             | Some lat, Some lon -> points := { lat; lon } :: !points
             | _ -> ())
          | _ -> ()
        in
        try
          while not (Xmlm.eoi input) do
            match Xmlm.input input with
            | `El_start (_, attrs) -> read_attrs attrs
            | _ -> ()
          done;
          Ok (List.rev !points)
        with Xmlm.Error (_, e) ->
          Error (Error.Gpx_parse_error { path; msg = Xmlm.error_message e }))

let decide points =
  match points with
  | [] -> Skip No_data
  | first :: _ when is_gps_off_sentinel first -> Skip Origin_fix
  | _ ->
    (* whole-track span: fixes the old "first 100 points only" bug *)
    let lats = List.map (fun p -> p.lat) points in
    let lons = List.map (fun p -> p.lon) points in
    let span xs =
      List.fold_left max neg_infinity xs -. List.fold_left min infinity xs
    in
    if span lats < movement_min_deg && span lons < movement_min_deg then
      Skip No_movement
    else Run
