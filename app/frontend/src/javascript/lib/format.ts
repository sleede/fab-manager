import moment from 'moment';
import { IFablab } from '../models/fablab';

declare let Fablab: IFablab;

export default class FormatLib {
  /**
   * Return the formatted localized date for the given date
   */
  static date = (date: Date): string => {
    return Intl.DateTimeFormat().format(moment(date).toDate());
  }

  /**
   * Return the formatted localized amount for the given price (eg. 20.5 => "20,50 €")
   */
  static price = (price: number): string => {
    return new Intl.NumberFormat(Fablab.intl_locale, { style: 'currency', currency: Fablab.intl_currency }).format(price);
  }
}
