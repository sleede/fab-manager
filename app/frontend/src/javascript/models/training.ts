export interface Training {
  id?: number,
  name: string,
  description: string,
  machine_ids: number[],
  nb_total_places: number,
  slug: string,
  public_page?: boolean,
  disabled?: boolean,
  plan_ids?: number[],
  training_image?: string,
}

export interface TrainingIndexFilter {
  disabled?: boolean,
  public_page?: boolean,
  requested_attributes?: ['availabillities'],
}
