import { PropsWithChildren, useCallback, useEffect, useState } from 'react';
import { UIRouter } from '@uirouter/angularjs';
import { FormState } from 'react-hook-form/dist/types/form';
import { FieldValues } from 'react-hook-form/dist/types/fields';
import { FabModal } from '../base/fab-modal';
import Deferred from '../../lib/deferred';
import { useTranslation } from 'react-i18next';

interface UnsavedFormAlertProps<TFieldValues> {
  uiRouter: UIRouter,
  formState: FormState<TFieldValues>,
}

/**
 * Alert the user about unsaved changes in the given form, before leaving the current page.
 * This component is highly dependent of these external libraries:
 *   - [react-hook-form](https://react-hook-form.com/)
 *   - [ui-router](https://ui-router.github.io/)
 */
export const UnsavedFormAlert = <TFieldValues extends FieldValues>({ uiRouter, formState, children }: PropsWithChildren<UnsavedFormAlertProps<TFieldValues>>) => {
  const { t } = useTranslation('shared');

  const [showAlertModal, setShowAlertModal] = useState<boolean>(false);
  const [promise, setPromise] = useState<Deferred<boolean>>(null);
  const [dirty, setDirty] = useState<boolean>(formState.isDirty);

  useEffect(() => {
    const submitStatus = (!formState.isSubmitting && (!formState.isSubmitted || !formState.isSubmitSuccessful));
    setDirty(submitStatus && Object.keys(formState.dirtyFields).length > 0);
  }, [formState]);

  /**
   * Check if the current form is dirty. If so, show the confirmation modal and return a promise
   */
  const alertOnDirtyForm = (isDirty: boolean): Promise<boolean>|void => {
    if (isDirty) {
      toggleAlertModal();
      const userChoicePromise = new Deferred<boolean>();
      setPromise(userChoicePromise);
      return userChoicePromise.promise;
    }
  };

  // memoised version of the alertOnDirtyForm function, will be updated only when the form becames dirty
  const alertDirty = useCallback<() => Promise<boolean>|void>(() => alertOnDirtyForm(dirty), [dirty]);

  // we should place this useEffect after the useCallback declaration (because it's a scoped variable)
  useEffect(() => {
    const { transitionService, globals: { current } } = uiRouter;
    const deregisters = transitionService.onBefore({ from: current.name }, alertDirty);
    return () => {
      deregisters();
    };
  }, [alertDirty]);

  /**
   * When the user tries to close the current page (tab/window), we alert him about unsaved changes
   */
  const alertOnExit = (event: BeforeUnloadEvent, isDirty: boolean) => {
    if (isDirty) {
      event.preventDefault();
      event.returnValue = '';
    }
  };

  // memoised version of the alertOnExit function, will be updated only when the form becames dirty
  const alertExit = useCallback<(event: BeforeUnloadEvent) => void>((event) => alertOnExit(event, dirty), [dirty]);

  // we should place this useEffect after the useCallback declaration (because it's a scoped variable)
  useEffect(() => {
    window.addEventListener('beforeunload', alertExit);
    return () => {
      window.removeEventListener('beforeunload', alertExit);
    };
  }, [alertExit]);

  /**
   * Hide/show the alert modal "you have some unsaved content, are you sure you want to leave?"
   */
  const toggleAlertModal = () => {
    setShowAlertModal(!showAlertModal);
  };

  /**
   * Callback triggered when the user has choosen: continue and exit
   */
  const handleConfirmation = () => {
    promise.resolve(true);
  };

  /**
   * Callback triggered when the user has choosen: cancel and stay
   */
  const handleCancel = () => {
    promise.resolve(false);
  };

  return (
    <div className="unsaved-form-alert">
      {children}
      <FabModal isOpen={showAlertModal}
                toggleModal={toggleAlertModal}
                confirmButton={t('app.shared.unsaved_form_alert.confirmation_button')}
                title={t('app.shared.unsaved_form_alert.modal_title')}
                onConfirm={handleConfirmation}
                onClose={handleCancel}
                closeButton>
        {t('app.shared.unsaved_form_alert.confirmation_message')}
      </FabModal>
    </div>
  );
};
