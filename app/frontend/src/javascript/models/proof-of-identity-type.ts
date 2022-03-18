export interface ProofOfIdentityTypeIndexfilter {
  group_id?: number,
}

export interface ProofOfIdentityType {
  id: number,
  name: string,
  group_ids: Array<number>
}
