import FormatLib from 'lib/format';
import { IFablab } from 'models/fablab';

declare const Fablab: IFablab;
describe('FormatLib', () => {
  test('format a Date object in french format', () => {
    Fablab.intl_locale = 'fr-FR';
    Fablab.timezone = 'Europe/Paris';
    Fablab.timezone_offset = '+01:00';
    const str = FormatLib.date(new Date('2023-01-12T23:59:00+0100'));
    expect(str).toBe('12/01/2023');
  });
  test('format a Date object in canadian format', () => {
    Fablab.intl_locale = 'fr-CA';
    Fablab.timezone = 'America/Toronto';
    Fablab.timezone_offset = '-05:00';
    const str = FormatLib.date(new Date('2023-01-12T23:59:00-0500'));
    expect(str).toBe('2023-01-12');
  });
  test('format an iso8601 short date in french format', () => {
    Fablab.intl_locale = 'fr-FR';
    Fablab.timezone = 'Europe/Paris';
    Fablab.timezone_offset = '+01:00';
    const str = FormatLib.date('2023-01-12');
    expect(str).toBe('12/01/2023');
  });
  test('format an iso8601 short date in canadian format', () => {
    Fablab.intl_locale = 'fr-CA';
    Fablab.timezone = 'America/Toronto';
    Fablab.timezone_offset = '-05:00';
    const str = FormatLib.date('2023-02-27');
    expect(str).toBe('2023-02-27');
  });
  test('format an iso8601 date in french format', () => {
    Fablab.intl_locale = 'fr-FR';
    Fablab.timezone = 'Europe/Paris';
    Fablab.timezone_offset = '+01:00';
    const str = FormatLib.date('2023-01-12T23:59:14+0100');
    expect(str).toBe('12/01/2023');
  });
  test('format an iso8601 date in canadian format', () => {
    Fablab.intl_locale = 'fr-CA';
    Fablab.timezone = 'America/Toronto';
    Fablab.timezone_offset = '-05:00';
    const str = FormatLib.date('2023-01-12T23:59:14-0500');
    expect(str).toBe('2023-01-12');
  });
  test('format a time from a Date object', () => {
    Fablab.intl_locale = 'fr-FR';
    Fablab.timezone = 'Europe/Paris';
    Fablab.timezone_offset = '+01:00';
    const str = FormatLib.time(new Date('2023-01-12T23:59:14+0100'));
    expect(str).toBe('23:59');
  });
  test('format a time from a Date object in canadian format', () => {
    Fablab.intl_locale = 'fr-CA';
    Fablab.timezone = 'America/Toronto';
    Fablab.timezone_offset = '-05:00';
    const str = FormatLib.time(new Date('2023-01-12T23:59:14-0500'));
    expect(str).toBe('23 h 59');
  });
  test('format an iso8601 short time', () => {
    Fablab.intl_locale = 'fr-FR';
    Fablab.timezone = 'Europe/Paris';
    Fablab.timezone_offset = '+01:00';
    const str = FormatLib.time('23:59');
    expect(str).toBe('23:59');
  });
  test('format an iso8601 time', () => {
    Fablab.intl_locale = 'fr-CA';
    Fablab.timezone = 'America/Toronto';
    Fablab.timezone_offset = '-05:00';
    const str = FormatLib.time('2023-01-12T23:59:14-0500');
    expect(str).toBe('23 h 59');
  });
});
