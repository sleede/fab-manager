export interface IFablab {
  plansModule: boolean,
  spacesModule: boolean,
  walletModule: boolean,
  statisticsModule: boolean,
  defaultHost: string,
  trackingId: string,
  adminSysId: number,
  baseHostUrl: string,
  locale: string,
  moment_locale: string,
  summernote_locale: string,
  fullcalendar_locale: string,
  intl_locale: string,
  intl_currency: string,
  timezone: string,
  weekStartingDay: string,
  d3DateFormat: string,
  uibDateFormat: string,
  maxProofOfIdentityFileSize: number,
  sessionTours: Array<string>,
  translations: {
    app: {
      shared: {
        buttons: Record<string, string>,
        messages: Record<string, string>,
      }
    }
  }
}
