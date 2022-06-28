import { ApiFilter } from '../models/api';

export default class ApiLib {
  static filtersToQuery (filters?: ApiFilter): string {
    if (!filters) return '';

    return '?' + Object.entries(filters).map(f => `${f[0]}=${f[1]}`).join('&');
  }
}
