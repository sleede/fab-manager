import React, { useState, useEffect } from 'react';
import { useTranslation } from 'react-i18next';
import { react2angular } from 'react2angular';
import _ from 'lodash';
import { Loader } from '../base/loader';
import { User } from '../../models/user';
import { IApplication } from '../../models/application';
import { ProofOfIdentityType } from '../../models/proof-of-identity-type';
import { ProofOfIdentityFile } from '../../models/proof-of-identity-file';
import ProofOfIdentityTypeAPI from '../../api/proof-of-identity-type';
import ProofOfIdentityFileAPI from '../../api/proof-of-identity-file';
import { ProofOfIdentityRefusalModal } from './proof-of-identity-refusal-modal';

declare const Application: IApplication;

interface ProofOfIdentityValidationProps {
  operator: User,
  member: User
  onSuccess: (message: string) => void,
  onError: (message: string) => void,
}

/**
 * This component shows a list of proof of identity file of member, admin can download and valid
 **/
const ProofOfIdentityValidation: React.FC<ProofOfIdentityValidationProps> = ({ operator, member, onSuccess, onError }) => {
  const { t } = useTranslation('admin');

  // list of proof of identity type
  const [proofOfIdentityTypes, setProofOfIdentityTypes] = useState<Array<ProofOfIdentityType>>([]);
  const [proofOfIdentityFiles, setProofOfIdentityFiles] = useState<Array<ProofOfIdentityFile>>([]);
  const [modalIsOpen, setModalIsOpen] = useState<boolean>(false);

  // get groups
  useEffect(() => {
    ProofOfIdentityTypeAPI.index({ group_id: member.group_id }).then(tData => {
      setProofOfIdentityTypes(tData);
    });
    ProofOfIdentityFileAPI.index({ user_id: member.id }).then(fData => {
      setProofOfIdentityFiles(fData);
    });
  }, []);

  const getProofOfIdentityFileByType = (proofOfIdentityTypeId: number): ProofOfIdentityFile => {
    return _.find<ProofOfIdentityFile>(proofOfIdentityFiles, { proof_of_identity_type_id: proofOfIdentityTypeId });
  };

  /**
   * Check if the current collection of proof of identity types is empty or not.
   */
  const hasProofOfIdentityTypes = (): boolean => {
    return proofOfIdentityTypes.length > 0;
  };

  const getProofOfIdentityFileUrl = (poifId: number): string => {
    return `/api/proof_of_identity_files/${poifId}/download`;
  };

  const openProofOfIdentityRefusalModal = (): void => {
    setModalIsOpen(true);
  };

  const toggleModal = (): void => {
    setModalIsOpen(false);
  };

  const saveProofOfIdentityRefusalOnSuccess = (message: string): void => {
    setModalIsOpen(false);
    onSuccess(message);
  };

  return (
    <div>
      <section className="panel panel-default bg-light m-lg col-sm-12 col-md-12 col-lg-7">
        <h3>{t('app.admin.members_edit.proof_of_identity_files')}</h3>
        <p className="text-black font-sbold">{t('app.admin.members_edit.find_below_the_proof_of_identity_files')}</p>
        {proofOfIdentityTypes.map((poit: ProofOfIdentityType) => {
          return (
            <div key={poit.id} className="m-b">
              <div className="m-b-xs">{poit.name}</div>
              {getProofOfIdentityFileByType(poit.id) && (
                <a href={getProofOfIdentityFileUrl(getProofOfIdentityFileByType(poit.id).id)} target="_blank" rel="noreferrer">
                  <span className="m-r">{getProofOfIdentityFileByType(poit.id).attachment}</span>
                  <i className="fa fa-download"></i>
                </a>
              )}
              {!getProofOfIdentityFileByType(poit.id) && (
                <div className="text-danger">{t('app.admin.members_edit.to_complete')}</div>
              )}
            </div>
          );
        })}
      </section>
      {hasProofOfIdentityTypes() && !member.validated_at && (
        <section className="panel panel-default bg-light m-t-lg col-sm-12 col-md-12 col-lg-4">
          <h3>{t('app.admin.members_edit.refuse_proof_of_identity_files')}</h3>
          <p className="text-black">{t('app.admin.members_edit.refuse_proof_of_identity_files_info')}</p>
          <button type="button" className="btn btn-warning m-b m-t" onClick={openProofOfIdentityRefusalModal}>{t('app.admin.members_edit.proof_of_identity_refusal')}</button>
          <ProofOfIdentityRefusalModal
            isOpen={modalIsOpen}
            proofOfIdentityTypes={proofOfIdentityTypes}
            toggleModal={toggleModal}
            operator={operator}
            member={member}
            onError={onError}
            onSuccess={saveProofOfIdentityRefusalOnSuccess}/>
        </section>
      )}
    </div>
  );
};

const ProofOfIdentityValidationWrapper: React.FC<ProofOfIdentityValidationProps> = ({ operator, member, onSuccess, onError }) => {
  return (
    <Loader>
      <ProofOfIdentityValidation operator={operator} member={member} onSuccess={onSuccess} onError={onError} />
    </Loader>
  );
};

Application.Components.component('proofOfIdentityValidation', react2angular(ProofOfIdentityValidationWrapper, ['operator', 'member', 'onSuccess', 'onError']));
