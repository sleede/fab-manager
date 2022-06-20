// from https://gist.github.com/MrChocolatine/367fb2a35d02f6175cc8ccb3d3a20054

type TYear = `${number}${number}${number}${number}`;
type TMonth = `${number}${number}`;
type TDay = `${number}${number}`;
type THours = `${number}${number}`;
type TMinutes = `${number}${number}`;
type TSeconds = `${number}${number}`;
type TMilliseconds = `${number}${number}${number}`;

/**
 * Represent a string like `2021-01-08`
 */
type TDateISODate = `${TYear}-${TMonth}-${TDay}`;

/**
 * Represent a string like `14:42:34.678`
 */
type TDateISOTime = `${THours}:${TMinutes}:${TSeconds}.${TMilliseconds}`;

/**
 * Represent a string like `2021-01-08T14:42:34.678Z` (format: ISO 8601).
 *
 * It is not possible to type more precisely (list every possible values for months, hours etc) as
 * it would result in a warning from TypeScript:
 *   "Expression produces a union type that is too complex to represent. ts(2590)
 */
export type TDateISO = `${TDateISODate}T${TDateISOTime}Z`;
