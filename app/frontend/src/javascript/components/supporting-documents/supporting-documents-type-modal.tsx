import { useState, useEffect } from 'react';
import * as React from 'react';
import { useTranslation } from 'react-i18next';
import { FabModal } from '../base/fab-modal';
import { ProofOfIdentityType } from '../../models/proof-of-identity-type';
import { Group } from '../../models/group';
import ProofOfIdentityTypeAPI from '../../api/proof-of-identity-type';
import { SupportingDocumentsTypeForm } from './supporting-documents-type-form';

interface SupportingDocumentsTypeModalProps {
  isOpen: boolean,
  toggleModal: () => void,
  onSuccess: (message: string) => void,
  onError: (message: string) => void,
  groups: Array<Group>,
  proofOfIdentityType?: ProofOfIdentityType,
}

/**
 * Modal dialog to create/edit a supporting documents type
 */
export const SupportingDocumentsTypeModal: React.FC<SupportingDocumentsTypeModalProps> = ({ isOpen, toggleModal, onSuccess, onError, proofOfIdentityType, groups }) => {
  const { t } = useTranslation('admin');

  const [data, setData] = useState<ProofOfIdentityType>({ id: proofOfIdentityType?.id, group_ids: proofOfIdentityType?.group_ids || [], name: proofOfIdentityType?.name || '' });

  useEffect(() => {
    setData({ id: proofOfIdentityType?.id, group_ids: proofOfIdentityType?.group_ids || [], name: proofOfIdentityType?.name || '' });
  }, [proofOfIdentityType]);

  /**
   * Callback triggered when an inner form field has changed: updates the internal state accordingly
   */
  const handleTypeChanged = (field: string, value: string | Array<number>) => {
    setData({
      ...data,
      [field]: value
    });
  };

  /**
   * Save the current type to the API
   */
  const handleSaveType = async (): Promise<void> => {
    try {
      if (proofOfIdentityType?.id) {
        await ProofOfIdentityTypeAPI.update(data);
        onSuccess(t('app.admin.settings.account.supporting_documents_type_modal.successfully_updated'));
      } else {
        await ProofOfIdentityTypeAPI.create(data);
        onSuccess(t('app.admin.settings.account.supporting_documents_type_modal.successfully_created'));
      }
    } catch (e) {
      if (proofOfIdentityType?.id) {
        onError(t('app.admin.settings.account.supporting_documents_type_modal.unable_to_update') + e);
      } else {
        onError(t('app.admin.settings.account.supporting_documents_type_modal.unable_to_create') + e);
      }
    }
  };

  /**
   * Check if the form is valid (not empty)
   */
  const isPreventedSaveType = (): boolean => {
    return !data.name || data.group_ids.length === 0;
  };

  return (
    <FabModal title={t(`app.admin.settings.account.supporting_documents_type_modal.${proofOfIdentityType ? 'edit' : 'new'}_type`)}
      isOpen={isOpen}
      toggleModal={toggleModal}
      closeButton={false}
      confirmButton={t(`app.admin.settings.account.supporting_documents_type_modal.${proofOfIdentityType ? 'edit' : 'create'}`)}
      onConfirm={handleSaveType}
      preventConfirm={isPreventedSaveType()}>
      <SupportingDocumentsTypeForm proofOfIdentityType={proofOfIdentityType} groups={groups} onChange={handleTypeChanged}/>
    </FabModal>
  );
};
