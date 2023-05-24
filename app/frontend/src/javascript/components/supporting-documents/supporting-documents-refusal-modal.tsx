import { useState } from 'react';
import * as React from 'react';
import { useTranslation } from 'react-i18next';
import { FabModal } from '../base/fab-modal';
import { SupportingDocumentType } from '../../models/supporting-document-type';
import { SupportingDocumentRefusal } from '../../models/supporting-document-refusal';
import { User } from '../../models/user';
import SupportingDocumentRefusalAPI from '../../api/supporting-document-refusal';
import { SupportingDocumentsRefusalForm } from './supporting-documents-refusal-form';

interface SupportingDocumentsRefusalModalProps {
  isOpen: boolean,
  toggleModal: () => void,
  onSuccess: (message: string) => void,
  onError: (message: string) => void,
  proofOfIdentityTypes: Array<SupportingDocumentType>,
  operator: User,
  member: User
}

/**
 * Modal dialog to notify the member that his documents are refused
 */
export const SupportingDocumentsRefusalModal: React.FC<SupportingDocumentsRefusalModalProps> = ({ isOpen, toggleModal, onSuccess, proofOfIdentityTypes, operator, member, onError }) => {
  const { t } = useTranslation('admin');

  const [data, setData] = useState<SupportingDocumentRefusal>({
    id: null,
    operator_id: operator.id,
    supportable_id: member.id,
    supportable_type: 'User',
    supporting_document_type_ids: [],
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
      await SupportingDocumentRefusalAPI.create(data);
      onSuccess(t('app.admin.supporting_documents_refusal_modal.refusal_successfully_sent'));
    } catch (e) {
      onError(t('app.admin.supporting_documents_refusal_modal.unable_to_send') + e);
    }
  };

  /**
   * Check if the refusal can be saved (i.e. is not empty)
   */
  const isPreventedSaveRefusal = (): boolean => {
    return !data.message || data.supporting_document_type_ids.length === 0;
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
