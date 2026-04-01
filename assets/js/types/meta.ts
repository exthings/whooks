export type Filter<T = string> = {
  value: T;
  op: string;
  field: string;
};

export type Meta<T = string> = {
  filters: Filter<T>[];
  currentPage: number;
  pageSize: number;
  totalCount: number;
  totalPages: number;
  hasNextPage: boolean;
  hasPreviousPage: boolean;
  nextPage: number | null;
  previousPage: number | null;
};
