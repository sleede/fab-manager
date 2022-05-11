import React, { useState } from 'react';
import { useTranslation } from 'react-i18next';
import { FabModal } from '../base/fab-modal';
import { ProofOfIdentityType } from '../../models/proof-of-identity-type';
import { ProofOfIdentityRefusal } from '../../models/proof-of-identity-refusal';
import { User } from '../../models/user';
import ProofOfIdentityRefusalAPI from '../../api/proof-of-identity-refusal';
import { ProofOfIdentityRefusalForm } from './proof-of-identity-refusal-form';

interface ProofOfIdentityRefusalModalProps {
  isOpen: boolean,
  toggleModal: () => void,
  onSuccess: (message: string) => void,
  onError: (message: string) => void,
  proofOfIdentityTypes: Array<ProofOfIdentityType>,
  operator: User,
  member: User
}

export const ProofOfIdentityRefusalModal: React.FC<ProofOfIdentityRefusalModalProps> = ({ isOpen, toggleModal, onSuccess, proofOfIdentityTypes, operator, member, onError }) => {
  const { t } = useTranslation('admin');

  const [data, setData] = useState<ProofOfIdentityRefusal>({
    id: null,
    operator_id: operator.id,
    user_id: member.id,
    proof_of_identity_type_ids: [],
    message: ''
  });

  const handleProofOfIdentityRefusalChanged = (field: string, value: string | Array<number>) => {
    setData({
      ...data,
      [field]: value
    });
  };

  const handleSaveProofOfIdentityRefusal = async (): Promise<void> => {
    try {
      await ProofOfIdentityRefusalAPI.create(data);
      onSuccess(t('app.admin.members_edit.proof_of_identity_refusal_successfully_sent'));
    } catch (e) {
      onError(t('app.admin.members_edit.proof_of_identity_refusal_unable_to_send') + e);
    }
  };

  const isPreventSaveProofOfIdentityRefusal = (): boolean => {
    return !data.message || data.proof_of_identity_type_ids.length === 0;
  };

  return (
    <FabModal title={t('app.admin.members_edit.proof_of_identity_refusal')}
      isOpen={isOpen}
      toggleModal={toggleModal}
      closeButton={false}
      confirmButton={t('app.admin.members_edit.confirm')}
      onConfirm={handleSaveProofOfIdentityRefusal}
      preventConfirm={isPreventSaveProofOfIdentityRefusal()}
      className="proof-of-identity-type-modal">
      <ProofOfIdentityRefusalForm proofOfIdentityTypes={proofOfIdentityTypes} onChange={handleProofOfIdentityRefusalChanged}/>
    </FabModal>
  );
};
