export type User = {
  id: string;
  externalId: string;
  name: string;
  email: string;
  role: "root" | "admin" | "support";
  confirmedAt: string;
  disabledAt: string;
  insertedAt: string;
  updatedAt: string;
};

export type Scope = {
  user: User;
};