export type Event = {
  id: string;
  uid: string;
  insertedAt: string;
  updatedAt: string;
  status: "pending" | "scheduled" | "processing" | "retry" | "success" | "failed";
  data: Record<string, any>;
  tags: string[];
  metadata: Record<string, any>;
};