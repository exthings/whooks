export type Attempt = {
  id: string;
  insertedAt: string;
  status: "success" | "failed";
  reqHeaders: Record<string, string[]>;
  resHeaders: Record<string, string[]>;
  resBody: Record<string, unknown>;
  resStatus: number;
  latencyMs: number;
};