type stats_init = {
  start: float;
  scales: Rrd_timescales.t list;
} [@@deriving yojson]
