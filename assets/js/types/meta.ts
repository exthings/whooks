export type Filter<T = string> = {
  value: T;
  op: string;
  field: string;
};

export type Meta<T = string> = {
  filters: Filter<T>[];
  current_page: number;
  page_size: number;
  total_count: number;
  total_pages: number;
  has_next_page: boolean;
  has_previous_page: boolean;
  next_page: number | null;
  previous_page: number | null;
};
