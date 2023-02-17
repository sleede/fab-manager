import Deferred from 'lib/deferred';

describe('Deferred', () => {
  test('resolve a deferred promise', () => {
    const deferred = new Deferred();
    deferred.resolve(4);
    expect(deferred.promise).resolves.toBe(4);
  });
  test('reject a deferred promise', () => {
    const deferred = new Deferred();
    deferred.reject('error');
    expect(deferred.promise).rejects.toBe('error');
  });
});
