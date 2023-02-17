import ApiLib from 'lib/api';

describe('ApiLib', () => {
  test('empty filters to query', () => {
    const res = ApiLib.filtersToQuery({});
    expect(res).toBe('');
  });
  test('no filters to query', () => {
    const res = ApiLib.filtersToQuery(null);
    expect(res).toBe('');
  });
  test('one filter to query', () => {
    const res = ApiLib.filtersToQuery({ foo: 1 });
    expect(res).toBe('?foo=1');
  });
  test('many filters to query', () => {
    const res = ApiLib.filtersToQuery({ foo: 1, bar: 'toto', baz: false });
    expect(res).toBe('?foo=1&bar=toto&baz=false');
  });
  test('drop null values from query', () => {
    const res = ApiLib.filtersToQuery({ foo: null, bar: 'toto', baz: false }, false);
    expect(res).toBe('?bar=toto&baz=false');
  });
  test('keep null values into query', () => {
    const res = ApiLib.filtersToQuery({ foo: null, bar: 'toto', baz: false }, true);
    expect(res).toBe('?foo=null&bar=toto&baz=false');
  });
  test('serialize a single attachment', () => {
    const res = ApiLib.serializeAttachments({ foo: 1, item_file_attributes: { attachment_files: ['bar'] } }, 'item', ['item_file_attributes']);
    expect(res.get('item[foo]')).toBe('1');
    expect(res.get('item[item_file_attributes][attachment]')).toBe('bar');
  });
  test('serialize multiple attachments', () => {
    const res = ApiLib.serializeAttachments({ foo: 1, item_file_attributes: [{ attachment_files: ['bar'] }, { attachment_files: ['poo'] }] }, 'item', ['item_file_attributes']);
    expect(res.get('item[foo]')).toBe('1');
    expect(res.get('item[item_file_attributes][0][attachment]')).toBe('bar');
    expect(res.get('item[item_file_attributes][1][attachment]')).toBe('poo');
  });
  test('serialize some existing attachments', () => {
    const res = ApiLib.serializeAttachments({ foo: 1, item_file_attributes: [{ id: 4, _destroy: true, is_main: false }, { id: 7, _destroy: false, is_main: true }] }, 'item', ['item_file_attributes']);
    expect(res.get('item[foo]')).toBe('1');
    expect(res.get('item[item_file_attributes][0][id]')).toBe('4');
    expect(res.get('item[item_file_attributes][0][_destroy]')).toBe('true');
    expect(res.get('item[item_file_attributes][0][is_main]')).toBeNull();
    expect(res.get('item[item_file_attributes][1][id]')).toBe('7');
    expect(res.get('item[item_file_attributes][1][_destroy]')).toBeNull();
    expect(res.get('item[item_file_attributes][1][is_main]')).toBe('true');
  });
});
