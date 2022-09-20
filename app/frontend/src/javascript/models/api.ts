// ApiFilter should be extended by an interface listing all the filters allowed for a given API
export type ApiFilter = Record<string, unknown>;

export interface PaginatedIndex<T> {
  page: number,
  total_pages: number,
  page_size: number,
  total_count: number,
  data: Array<T>
}

export type SortOption = `${string}-${'asc' | 'desc'}` | '';
