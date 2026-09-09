export type Interval =
  | "1s"
  | "15s"
  | "30s"
  | "45s"
  | "1m"
  | "15m"
  | "30m"
  | "45m"
  | "1h"
  | "1d"
  | "1w"
  | "1mo"
  | "minute"
  | "hour"
  | "day";

export type Last = "1m" | "1h" | "12h" | "24h" | "48h" | "1w" | "1mo";

export type GlobalFilters = { last: Last; interval: Interval };