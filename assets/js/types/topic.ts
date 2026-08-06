export type Topic = {
  id: string;
  insertedAt: string;
  updatedAt: string;
  name: string;
  status: "enabled" | "disabled";
  description?: string;
  jsonSchema: Record<string, any>;
  validateSchema: boolean;
  example?: Record<string, any>;
};