export type Attempt = {
  id: string;
  insertedAt: string;
  status:
    | "scheduled"
    | "processing"
    | "success"
    | "retry"
    | "failed"
    | "discarded";
  reqHeaders?: Record<string, string[]>;
  resHeaders?: Record<string, string[]>;
  resBody?: Record<string, unknown>;
  resStatus?: number;
  latencyMs?: number;
};