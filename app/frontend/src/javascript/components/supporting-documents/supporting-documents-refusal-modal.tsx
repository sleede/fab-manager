import React, { useState } from 'react';
import { useTranslation } from 'react-i18next';
import { FabModal } from '../base/fab-modal';
import { ProofOfIdentityType } from '../../models/proof-of-identity-type';
import { ProofOfIdentityRefusal } from '../../models/proof-of-identity-refusal';
import { User } from '../../models/user';
import ProofOfIdentityRefusalAPI from '../../api/proof-of-identity-refusal';
import { SupportingDocumentsRefusalForm } from './supporting-documents-refusal-form';

interface SupportingDocumentsRefusalModalProps {
  isOpen: boolean,
  toggleModal: () => void,
  onSuccess: (message: string) => void,
  onError: (message: string) => void,
  proofOfIdentityTypes: Array<ProofOfIdentityType>,
  operator: User,
  member: User
}

/**
 * Modal dialog to notify the member that his documents are refused
 */
export const SupportingDocumentsRefusalModal: React.FC<SupportingDocumentsRefusalModalProps> = ({ isOpen, toggleModal, onSuccess, proofOfIdentityTypes, operator, member, onError }) => {
  const { t } = useTranslation('admin');

  const [data, setData] = useState<ProofOfIdentityRefusal>({
    id: null,
    operator_id: operator.id,
    user_id: member.id,
    proof_of_identity_type_ids: [],
    message: ''
  });

  /**
   * Callback triggered when any field has changed in the child form
   */
  const handleRefusalChanged = (field: string, value: string | Array<number>) => {
    setData({
      ...data,
      [field]: value
    });
  };

  /**
   * Save the refusal to the API and send a result message to the parent component
   */
  const handleSaveRefusal = async (): Promise<void> => {
    try {
      await ProofOfIdentityRefusalAPI.create(data);
      onSuccess(t('app.admin.supporting_documents_refusal_modal.refusal_successfully_sent'));
    } catch (e) {
      onError(t('app.admin.supporting_documents_refusal_modal.unable_to_send') + e);
    }
  };

  /**
   * Check if the refusal can be saved (i.e. is not empty)
   */
  const isPreventedSaveRefusal = (): boolean => {
    return !data.message || data.proof_of_identity_type_ids.length === 0;
  };

  return (
    <FabModal title={t('app.admin.supporting_documents_refusal_modal.title')}
      isOpen={isOpen}
      toggleModal={toggleModal}
      closeButton={false}
      confirmButton={t('app.admin.supporting_documents_refusal_modal.confirm')}
      onConfirm={handleSaveRefusal}
      preventConfirm={isPreventedSaveRefusal()}
      className="supporting-documents-refusal-modal">
      <SupportingDocumentsRefusalForm proofOfIdentityTypes={proofOfIdentityTypes} onChange={handleRefusalChanged}/>
    </FabModal>
  );
};
