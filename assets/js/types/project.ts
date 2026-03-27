import type { Organization } from "./organization";

export type Project = {
  id: string;
  insertedAt: string;
  updatedAt: string;
  uid?: string;
  name: string;
  status: "enabled" | "disabled";
  metadata: Record<string, any>;
  organization: Organization;
}