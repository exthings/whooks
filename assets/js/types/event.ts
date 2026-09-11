export type Event = {
  id: string;
  uid: string;
  insertedAt: string;
  updatedAt: string;
  status: "scheduled" | "pending" | "processing" | "processed" | "unprocessed";
  data: Record<string, any>;
  tags: string[];
  metadata: Record<string, any>;
};