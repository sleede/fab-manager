export interface GoogleTagManager {
  enableAnalytics: (trackingId: string) => void,
  trackPage: (url: string, title: string) => void,
  trackLogin: () => void,
  trackPurchase: (transactionId: number, value: number) => void,
}
