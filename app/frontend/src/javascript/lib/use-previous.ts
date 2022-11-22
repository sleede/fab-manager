import { useEffect, useRef } from 'react';

// provides the previous value of a Prop, in a useEffect hook
// Credits to: https://stackoverflow.com/a/57706747/1039377
export const usePrevious = <T>(value: T): T | undefined => {
  const ref = useRef<T>();
  useEffect(() => {
    ref.current = value;
  });
  return ref.current;
};
