export interface AsaasPayment {
  token: string,
  status: 'pending' | 'waiting_payment' | 'paid' | 'expired' | 'failed',
  pix_payload: string,
  pix_encoded_image: string,
  pix_expiration_at: string,
}
