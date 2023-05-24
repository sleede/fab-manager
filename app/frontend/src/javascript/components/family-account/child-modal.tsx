import * as React from 'react';
import { useTranslation } from 'react-i18next';
import { FabModal, ModalSize } from '../base/fab-modal';
import { Child } from '../../models/child';
import ChildAPI from '../../api/child';
import { ChildForm } from './child-form';
import { SupportingDocumentType } from '../../models/supporting-document-type';

interface ChildModalProps {
  child?: Child;
  isOpen: boolean;
  toggleModal: () => void;
  onSuccess: (child: Child) => void;
  onError: (error: string) => void;
  supportingDocumentsTypes: Array<SupportingDocumentType>;
}

/**
 * A modal for creating or editing a child.
 */
export const ChildModal: React.FC<ChildModalProps> = ({ child, isOpen, toggleModal, onSuccess, onError, supportingDocumentsTypes }) => {
  const { t } = useTranslation('public');

  /**
   * Save the child to the API
   */
  const handleSaveChild = async (data: Child): Promise<void> => {
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

  return (
    <FabModal title={t(`app.public.child_modal.${child?.id ? 'edit' : 'new'}_child`)}
      width={ModalSize.large}
      isOpen={isOpen}
      toggleModal={toggleModal}
      closeButton={true}
      confirmButton={false} >
      <ChildForm child={child} onSubmit={handleSaveChild} supportingDocumentsTypes={supportingDocumentsTypes}/>
    </FabModal>
  );
};
