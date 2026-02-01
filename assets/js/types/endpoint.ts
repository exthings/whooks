export type Endpoint = {
  id: string;
  uid: string;
  insertedAt: string;
  updatedAt: string;
  name: string;
  status: "enabled" | "disabled";
  url: string;
  description: string;
  headers: string;
  metadata: Record<string, any>;
  secret: string;
  oldSecret: string;
  consumerId: string;
  projectId: string;
}