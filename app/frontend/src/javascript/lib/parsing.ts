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
    } else {
      parsedValue = ParsingLib.simpleParse(value);
    }
    return parsedValue;
  };

  /**
   * Try to parse the given value to get the value with the matching type.
   * Arrays are not supported.
   */
  static simpleParse = (value: string): baseType => {
    let parsedValue: baseType = value;
    if (ParsingLib.isBoolean(value)) {
      parsedValue = (value === 'true');
    } else if (ParsingLib.isInteger(value)) {
      parsedValue = parseInt(value, 10);
    }
    return parsedValue;
  };

  /**
   * Check if the provided string represents an integer
   */
  static isInteger = (value: string): boolean => {
    return (parseInt(value, 10).toString() === value);
  };

  /**
   * Check if the provided string represents a boolean value
   */
  static isBoolean = (value: string): boolean => {
    return ['true', 'false'].includes(value);
  };
}
