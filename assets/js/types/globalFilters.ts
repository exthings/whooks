export type Interval = "minute" | "hour" | "day";
export type Last = "1m" | "1h" | "12h" | "24h" | "48h" | "1w" | "1mo";

export type GlobalFilters = { last: Last; interval: Interval }