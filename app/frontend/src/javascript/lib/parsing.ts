type baseType = string|number|boolean;
type ValueOrArray<T> = T | ValueOrArray<T>[];
type NestedBaseArray = ValueOrArray<baseType>;

export default class ParsingLib {
  /**
   * Try to parse the given value to get the value with the matching type.
   * It supports parsing arrays.
   */
  static parse = (value: string|string[]): NestedBaseArray => {
    let parsedValue: NestedBaseArray = value;
    if (Array.isArray(value)) {
      parsedValue = [];
      for (const item of value) {
        parsedValue.push(ParsingLib.parse(item));
      }
    } else if (['true', 'false'].includes(value)) {
      parsedValue = (value === 'true');
    } else if (parseInt(value, 10).toString() === value) {
      parsedValue = parseInt(value, 10);
    }
    return parsedValue;
  };
}
