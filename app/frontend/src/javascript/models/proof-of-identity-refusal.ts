
export interface ProofOfIdentityRefusalIndexFilter {
  user_id: number,
}

export interface ProofOfIdentityRefusal {
  id: number,
  message: string,
  user_id: number,
  operator_id: number,
  proof_of_identity_type_ids: Array<number>,
}
