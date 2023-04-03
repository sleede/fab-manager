import * as React from 'react';
import { useState } from 'react';
import { useTranslation } from 'react-i18next';
import { FabModal, ModalSize } from '../base/fab-modal';
import { Child } from '../../models/child';
import { TDateISODate } from '../../typings/date-iso';
import ChildAPI from '../../api/child';
import { ChildForm } from './child-form';

interface ChildModalProps {
  child?: Child;
  isOpen: boolean;
  toggleModal: () => void;
}

/**
 * A modal for creating or editing a child.
 */
export const ChildModal: React.FC<ChildModalProps> = ({ child, isOpen, toggleModal }) => {
  const { t } = useTranslation('public');
  const [data, setData] = useState<Child>(child);
  console.log(child, data);

  /**
   * Save the child to the API
   */
  const handleSaveChild = async (): Promise<void> => {
    try {
      if (child?.id) {
        await ChildAPI.update(data);
      } else {
        await ChildAPI.create(data);
      }
      toggleModal();
    } catch (error) {
      console.error(error);
    }
  };

  /**
   * Check if the form is valid to save the child
   */
  const isPreventedSaveChild = (): boolean => {
    return !data?.first_name || !data?.last_name;
  };

  /**
   * Handle the change of a child form field
   */
  const handleChildChanged = (field: string, value: string | TDateISODate): void => {
    setData({
      ...data,
      [field]: value
    });
  };

  return (
    <FabModal title={t(`app.public.child_modal.${child?.id ? 'edit' : 'new'}_child`)}
      width={ModalSize.large}
      isOpen={isOpen}
      toggleModal={toggleModal}
      closeButton={true}
      confirmButton={t('app.public.child_modal.save')}
      onConfirm={handleSaveChild}
      preventConfirm={isPreventedSaveChild()}>
      <ChildForm child={child} onChange={handleChildChanged} />
    </FabModal>
  );
};
