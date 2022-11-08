import moment, { unitOfTime } from 'moment';
import { IFablab } from '../models/fablab';
import { TDateISO, TDateISODate, THours, TMinutes } from '../typings/date-iso';

declare let Fablab: IFablab;

export default class FormatLib {
  /**
   * Return the formatted localized date for the given date
   */
  static date = (date: Date|TDateISO|TDateISODate): string => {
    return Intl.DateTimeFormat().format(moment(date).toDate());
  };

  /**
   * Return the formatted localized time for the given date
   */
  static time = (date: Date|TDateISO|`${THours}:${TMinutes}`): string => {
    let tempDate: Date;
    const isoTimeMatch = (date as string).match(/^(\d\d):(\d\d)$/);
    if (isoTimeMatch) {
      tempDate = new Date();
      tempDate.setHours(parseInt(isoTimeMatch[1], 10));
      tempDate.setMinutes(parseInt(isoTimeMatch[2], 10));
    } else {
      tempDate = moment(date).toDate();
    }
    return Intl.DateTimeFormat(Fablab.intl_locale, { hour: 'numeric', minute: 'numeric' }).format(tempDate);
  };

  /**
   * Return the formatted localized duration
   */
  static duration = (interval: unitOfTime.DurationConstructor, intervalCount: number): string => {
    return moment.duration(intervalCount, interval).locale(Fablab.moment_locale).humanize();
  };

  /**
   * Return the formatted localized amount for the given price (eg. 20.5 => "20,50 €")
   */
  static price = (price: number): string => {
    return new Intl.NumberFormat(Fablab.intl_locale, { style: 'currency', currency: Fablab.intl_currency }).format(price);
  };

  /**
   * Return currency symbol for currency setting
   */
  static currencySymbol = (): string => {
    return new Intl.NumberFormat(Fablab.intl_locale, { style: 'currency', currency: Fablab.intl_currency }).formatToParts().filter(p => p.type === 'currency')[0].value;
  };
}
