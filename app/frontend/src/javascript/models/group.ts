export interface GroupIndexFilter {
  key: 'disabled',
  value: boolean,
}

export interface Group {
  id: number,
  slug: string,
  name: string,
  disabled: boolean,
  users: number
}
