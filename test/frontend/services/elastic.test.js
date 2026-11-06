const fs = require('fs');
const path = require('path');
const vm = require('vm');

describe('statistics Rails HTTP service', () => {
  let service;
  let http;
  beforeEach(() => {
    http = { post: jest.fn().mockResolvedValue({ data: { hits: { total: 47 } } }), delete: jest.fn().mockResolvedValue({ status: 204 }) };
    service = {};
    const Application = { Services: { service: (_name, declaration) => declaration[declaration.length - 1].call(service, http, { reject: Promise.reject.bind(Promise) }) } };
    const file = path.resolve(__dirname, '../../../app/frontend/src/javascript/services/elastic.js');
    vm.runInNewContext(fs.readFileSync(file, 'utf8'), { Application });
  });

  test('table and graph requests retain body, callbacks, query parameters and Rails paths', async () => {
    const callback = jest.fn();
    const body = { aggs: { calendar: { date_histogram: { interval: 'week', field: 'date' } } } };
    const result = await service.search({ index: 'stats', type: 'machine', body, size: 20, scroll: '1m', searchType: 'query_then_fetch',
      'stat-type': 'hour', 'custom-query': '{}', 'start-date': '2026-03-08', 'end-date': '2026-03-09' }, callback);
    expect(http.post).toHaveBeenCalledWith('/stats/machine/_search', body, { params: { size: 20, scroll: '1m', search_type: 'query_then_fetch',
      'stat-type': 'hour', 'custom-query': '{}', 'start-date': '2026-03-08', 'end-date': '2026-03-09' }, headers: { Accept: 'application/json' } });
    expect(result.hits.total).toBe(47);
    expect(callback).toHaveBeenCalledWith(null, result);
  });

  test('all supported families use fixed Rails routes and destination options cannot redirect requests', async () => {
    for (const family of ['account', 'event', 'machine', 'project', 'subscription', 'training', 'user', 'space', 'order']) {
      await service.search({ index: 'stats', type: family, body: {}, host: 'https://other.invalid' });
      expect(http.post).toHaveBeenLastCalledWith(`/stats/${family}/_search`, {}, { params: {}, headers: { Accept: 'application/json' } });
    }
    await expect(service.search({ index: 'secret', type: 'machine', body: {} })).rejects.toThrow('Unknown statistics family');
    await expect(service.search({ index: 'stats', type: '../_cluster', body: {} })).rejects.toThrow('Unknown statistics family');
    expect(http.post).toHaveBeenCalledTimes(9);
  });

  test('scroll and release keep the signed cursor and Rails error responses', async () => {
    await service.scroll({ scroll: '1m', body: { scrollId: 'signed-cursor' } });
    expect(http.post).toHaveBeenCalledWith('/_search/scroll', { scroll: '1m', scrollId: 'signed-cursor' }, { headers: { Accept: 'application/json' } });
    await service.clearScroll('signed-cursor');
    expect(http.delete).toHaveBeenCalledWith('/_search/scroll', { data: { scrollId: 'signed-cursor' }, headers: { Accept: 'application/json', 'Content-Type': 'application/json' } });
    const error = { status: 403, data: { error: 'forbidden' } };
    const callback = jest.fn();
    http.post.mockRejectedValueOnce(error);
    await expect(service.search({ index: 'stats', type: 'machine', body: {} }, callback)).rejects.toEqual(error);
    expect(callback).toHaveBeenCalledWith(error);
  });
});
