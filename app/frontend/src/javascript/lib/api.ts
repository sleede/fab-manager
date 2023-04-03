import _ from 'lodash';
import { ApiFilter } from '../models/api';
import { serialize } from 'object-to-formdata-tz';

export default class ApiLib {
  static filtersToQuery (filters?: ApiFilter, keepNullValues = true): string {
    if (!filters || Object.keys(filters).length < 1) return '';

    return '?' + Object.entries(filters)
      .filter(filter => keepNullValues || !_.isNil(filter[1]))
      .map(filter => `${filter[0]}=${filter[1]}`)
      .join('&');
  }

  static serializeAttachments<TObject> (object: TObject, name: string, attachmentAttributes: Array<string>): FormData {
    const data = serialize({
      [name]: {
        ...object,
        ...attachmentAttributes.reduce((a, name) => { return { ...a, [name]: null }; }, {})
      }
    }, { dateWithTimezone: true });
    attachmentAttributes.forEach((attr) => {
      data.delete(`${name}[${attr}]`);
      if (Array.isArray(object[attr])) {
        object[attr]?.forEach((file, i) => {
          if (file?.attachment_files && file?.attachment_files[0]) {
            data.set(`${name}[${attr}][${i}][attachment]`, file.attachment_files[0]);
          }
          if (file?.id) {
            data.set(`${name}[${attr}][${i}][id]`, file.id.toString());
          }
          if (file?._destroy) {
            data.set(`${name}[${attr}][${i}][_destroy]`, file._destroy.toString());
          }
          if (file?.is_main) {
            data.set(`${name}[${attr}][${i}][is_main]`, file.is_main.toString());
          }
        });
      } else {
        if (object[attr]?.attachment_files && object[attr]?.attachment_files[0]) {
          data.set(`${name}[${attr}][attachment]`, object[attr]?.attachment_files[0]);
        }
        if (object[attr]?.id) {
          data.set(`${name}[${attr}][id]`, object[attr].id.toString());
        }
        if (object[attr]?._destroy) {
          data.set(`${name}[${attr}][_destroy]`, object[attr]._destroy.toString());
        }
      }
    });
    return data;
  }
}
