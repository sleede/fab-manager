import _ from 'lodash';
import { ApiFilter } from '../models/api';

export default class ApiLib {
  static filtersToQuery (filters?: ApiFilter, keepNullValues = true): string {
    if (!filters) return '';

    return '?' + Object.entries(filters)
      .filter(filter => keepNullValues || !_.isNil(filter[1]))
      .map(filter => `${filter[0]}=${filter[1]}`)
      .join('&');
  }
}
