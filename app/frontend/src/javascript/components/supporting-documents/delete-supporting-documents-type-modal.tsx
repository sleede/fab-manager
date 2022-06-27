import React from 'react';
import { useTranslation } from 'react-i18next';
import { FabModal } from '../base/fab-modal';
import ProofOfIdentityTypeAPI from '../../api/proof-of-identity-type';

interface DeleteSupportingDocumentsTypeModalProps {
  isOpen: boolean,
  proofOfIdentityTypeId: number,
  toggleModal: () => void,
  onSuccess: (message: string) => void,
  onError: (message: string) => void,
}

/**
 * Modal dialog to remove a requested type of supporting documents
 */
export const DeleteSupportingDocumentsTypeModal: React.FC<DeleteSupportingDocumentsTypeModalProps> = ({ isOpen, toggleModal, onSuccess, proofOfIdentityTypeId, onError }) => {
  const { t } = useTranslation('admin');

  /**
   * The user has confirmed the deletion of the requested type of supporting documents
   */
  const handleDeleteProofOfIdentityType = async (): Promise<void> => {
    try {
      await ProofOfIdentityTypeAPI.destroy(proofOfIdentityTypeId);
      onSuccess(t('app.admin.settings.account.delete_supporting_documents_type_modal.deleted'));
    } catch (e) {
      onError(t('app.admin.settings.account.delete_supporting_documents_type_modal.unable_to_delete') + e);
    }
  };

  return (
    <FabModal title={t('app.admin.settings.account.delete_supporting_documents_type_modal.confirmation_required')}
      isOpen={isOpen}
      toggleModal={toggleModal}
      closeButton={true}
      confirmButton={t('app.admin.settings.account.delete_supporting_documents_type_modal.confirm')}
      onConfirm={handleDeleteProofOfIdentityType}
      className="delete-supporting-documents-type-modal">
      <p>{t('app.admin.settings.account.delete_supporting_documents_type_modal.confirm_delete_supporting_documents_type')}</p>
    </FabModal>
  );
};
