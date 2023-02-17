import ParsingLib from 'lib/parsing';

describe('ParsingLib', () => {
  test('parse a boolean', () => {
    const res = ParsingLib.simpleParse('true');
    expect(res).toBe(true);
  });
  test('parse a number', () => {
    const res = ParsingLib.simpleParse('10');
    expect(res).toBe(10);
  });
  test('parse an array of numbers', () => {
    const res = ParsingLib.parse(['10', '20', '30']);
    expect(res).toEqual([10, 20, 30]);
  });
  test('parse an array of booleans', () => {
    const res = ParsingLib.parse(['true', 'false']);
    expect(res).toEqual([true, false]);
  });
  test('parse a mixed array', () => {
    const res = ParsingLib.parse(['true', '10', 'foo']);
    expect(res).toEqual([true, 10, 'foo']);
  });
  test('parse an array of arrays', () => {
    const res = ParsingLib.parse([['bar', '10'], ['true', 'foo'], 'baz']);
    expect(res).toEqual([['bar', 10], [true, 'foo'], 'baz']);
  });
});
