import type { Endpoint } from "./endpoint";

export type Consumer = {
  id: string;
  uid: string;
  name: string;
  metadata: any;
  insertedAt: string;
  updatedAt: string;
  endpoints?: Endpoint[];
}