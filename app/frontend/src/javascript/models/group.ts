export interface GroupIndexFilter {
  disabled?: boolean,
  admins?: boolean,
}

export interface Group {
  id: number,
  slug: string,
  name: string,
  disabled: boolean,
  users: number
}
