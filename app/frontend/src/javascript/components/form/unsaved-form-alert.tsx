import React, { PropsWithChildren, useEffect } from 'react';
import { UIRouter } from '@uirouter/angularjs';
import { FormState } from 'react-hook-form/dist/types/form';
import { FieldValues } from 'react-hook-form/dist/types/fields';

interface UnsavedFormAlertProps<TFieldValues> {
  uiRouter: UIRouter,
  formState: FormState<TFieldValues>,
}

/**
 * Alert the user about unsaved changes in the given form, before leaving the current page
 */
export const UnsavedFormAlert = <TFieldValues extends FieldValues>({ uiRouter, formState, children }: PropsWithChildren<UnsavedFormAlertProps<TFieldValues>>) => {
  useEffect(() => {
    const { transitionService, globals: { current } } = uiRouter;
    transitionService.onBefore({ from: current.name }, () => {
      const { isDirty } = formState;
      console.log('transition start', isDirty);
    });
  }, []);

  return (
    <div className="unsaved-form-alert">
      {children}
    </div>
  );
};
