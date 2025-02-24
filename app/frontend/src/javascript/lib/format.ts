import moment, { unitOfTime } from 'moment-timezone';
import { IFablab } from '../models/fablab';
import { TDateISO, TDateISODate, TDateISOShortTime } from '../typings/date-iso';

declare let Fablab: IFablab;

export default class FormatLib {
  /**
   * Check if the provided variable is a JS Date oject
   */
  static isDate = (value: unknown): boolean => {
    return (value != null) && !isNaN(value as number) && (typeof (value as Date).getDate !== 'undefined');
  };

  /**
   * Check if the provided variable is an ISO 8601 representation of a date
   */
  static isDateISO = (value: string): boolean => {
    if (typeof value !== 'string') return false;
    return !!value?.match(/^\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\d/);
  };

  /**
   * Check if the provided variable is string representing a short date, according to ISO 8601 (e.g. 2023-01-12)
   */
  static isShortDateISO = (value: string): boolean => {
    if (typeof value !== 'string') return false;
    return !!value.match(/^\d\d\d\d-\d\d-\d\d$/);
  };

  /**
   * Check if the provided variable is string representing a short time, according to ISO 8601 (e.g. 14:21)
   */
  static isShortTimeISO = (value: string): boolean => {
    if (typeof value !== 'string') return false;
    return !!value?.match(/^\d\d:\d\d$/);
  };

  /**
   * Return the formatted localized date for the given date
   */
  static date = (date: Date|TDateISO|TDateISODate): string => {
    let tempDate: Date;
    if (FormatLib.isShortDateISO(date as string) || FormatLib.isDateISO(date as string)) {
      tempDate = FormatLib.parseISOdate(date as TDateISO);
    } else {
      tempDate = moment(date).toDate();
    }
    return Intl.DateTimeFormat(Fablab.intl_locale, { timeZone: Fablab.timezone }).format(tempDate);
  };

  /**
   * Parse the provided datetime or date string (as ISO8601 format) and return the equivalent Date object
   */
  private static parseISOdate = (date: TDateISO|TDateISODate): Date => {
    const isoDateMatch = (date as string)?.match(/^(\d\d\d\d-\d\d-\d\d)/);
    return new Date(`${isoDateMatch[1]}T12:00:00${Fablab.timezone_offset}`);
  };

  /**
   * Parse the provided datetime or time string (as ISO8601 format) and return the equivalent Date object
   */
  private static parseISOtime = (date: TDateISO|TDateISOShortTime): Date => {
    const isoTimeMatch = (date as string)?.match(/(^|T)(\d\d:\d\d)/);
    return new Date(`${moment().format('YYYY-MM-DD')}T${isoTimeMatch[2]}:00${Fablab.timezone_offset}`);
  };

  /**
   * Return a date formatted for use within a filename
   */
  static dateFilename = (date: Date|TDateISO|TDateISODate): string => {
    return moment(date).format('DDMMYYYY');
  };

  /**
   * Return the formatted localized time for the given date
   */
  static time = (date: Date|TDateISO|TDateISOShortTime): string => {
    let tempDate: Date;
    if (FormatLib.isShortTimeISO(date as string)) {
      tempDate = FormatLib.parseISOtime(date as TDateISOShortTime);
    } else {
      tempDate = moment.utc(date).toDate();
    }
    return Intl.DateTimeFormat(Fablab.intl_locale, { hour: 'numeric', minute: 'numeric', timeZone: Fablab.timezone }).format(tempDate);
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
