import * as React from 'react';
import { useEffect, useState } from 'react';
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
  onSuccess: (child: Child) => void;
  onError: (error: string) => void;
}

/**
 * A modal for creating or editing a child.
 */
export const ChildModal: React.FC<ChildModalProps> = ({ child, isOpen, toggleModal, onSuccess, onError }) => {
  const { t } = useTranslation('public');
  const [data, setData] = useState<Child>(child);

  useEffect(() => {
    setData(child);
  }, [child]);

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
      onSuccess(data);
    } catch (error) {
      onError(error);
    }
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
      confirmButton={false}
      onConfirm={handleSaveChild} >
      <ChildForm child={child} onChange={handleChildChanged} onSubmit={handleSaveChild} />
    </FabModal>
  );
};
