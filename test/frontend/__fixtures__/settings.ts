import { Setting } from '../../../app/frontend/src/javascript/models/setting';
import { TDateISO } from '../../../app/frontend/src/javascript/typings/date-iso';

export const setting = (name, value): Setting => {
  return {
    last_update: new Date().toISOString() as TDateISO,
    localized: name[0].toUpperCase() + name.substring(1),
    name,
    value: value.toString()
  };
};

export const settings = (names: Array<string>): Record<string, string> => {
  const res = {};
  names.forEach(name => {
    res[name] = 'true';
  });
  return res;
};
