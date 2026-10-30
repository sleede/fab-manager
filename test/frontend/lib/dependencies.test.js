import lodash from 'lodash';
import underscore from 'underscore/underscore.js';
import ApiLib from 'lib/api';

describe('browser dependency compatibility', () => {
  test('keeps empty and false form values while omitting null filters', () => {
    expect(ApiLib.filtersToQuery({ empty: '', enabled: false, missing: null }, false))
      .toBe('?empty=&enabled=false');
    expect(lodash.get({ member: { name: 'Local' } }, 'member.name')).toBe('Local');
  });

  test('keeps the legacy Underscore browser entry and collection behavior', () => {
    const members = [{ id: 1, active: true }, { id: 2, active: false }];

    expect(underscore.pluck(underscore.where(members, { active: true }), 'id')).toEqual([1]);
    expect(underscore.template('<%- name %>')({ name: '<Local>' })).toBe('&lt;Local&gt;');
  });
});
