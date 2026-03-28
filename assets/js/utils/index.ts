import type { Filter } from "$types/meta";
import { page } from '@inertiajs/svelte';
import { get } from 'svelte/store';

export const getFilterValue = <T = string>(
  filters: Filter[],
  field: string | string[],
  parseFn: ((value: string) => T) | undefined = undefined,
) => {
  return filters.reduce((values, filter) => {
    if (Array.isArray(field)) {
      if (field.includes(filter.field)) {
        return [
          ...values,
          {
            ...filter,
            value: parseFn ? parseFn(filter.value) : filter.value,
          },
        ] as Filter<T>[];
      }
    } else {
      if (filter.field === field) {
        return [
          ...values,
          {
            ...filter,
            value: parseFn ? parseFn(filter.value) : filter.value,
          },
        ] as Filter<T>[];
      }
    }

    return values;
  }, [] as Filter<T>[]);
};

export const buildHref = (path: string) => {
  const orgId = get(page).props.organizationId
  return `/ui/admin/${orgId}${path}`;
}