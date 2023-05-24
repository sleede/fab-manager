import { useState, useEffect } from 'react';
import * as React from 'react';
import { useTranslation } from 'react-i18next';
import { react2angular } from 'react2angular';
import _ from 'lodash';
import { Loader } from '../base/loader';
import { User } from '../../models/user';
import { IApplication } from '../../models/application';
import { SupportingDocumentType } from '../../models/supporting-document-type';
import { SupportingDocumentFile } from '../../models/supporting-document-file';
import SupportingDocumentTypeAPI from '../../api/supporting-document-type';
import SupportingDocumentFileAPI from '../../api/supporting-document-file';
import { SupportingDocumentsRefusalModal } from './supporting-documents-refusal-modal';
import { FabButton } from '../base/fab-button';
import { FabPanel } from '../base/fab-panel';

declare const Application: IApplication;

interface SupportingDocumentsValidationProps {
  operator: User,
  member: User
  onSuccess: (message: string) => void,
  onError: (message: string) => void,
}

/**
 * This component shows a list of supporting documents file of member, admin can download and valid
 **/
const SupportingDocumentsValidation: React.FC<SupportingDocumentsValidationProps> = ({ operator, member, onSuccess, onError }) => {
  const { t } = useTranslation('admin');

  // list of supporting documents type
  const [documentsTypes, setDocumentsTypes] = useState<Array<SupportingDocumentType>>([]);
  const [documentsFiles, setDocumentsFiles] = useState<Array<SupportingDocumentFile>>([]);
  const [modalIsOpen, setModalIsOpen] = useState<boolean>(false);

  // get groups
  useEffect(() => {
    SupportingDocumentTypeAPI.index({ group_id: member.group_id }).then(tData => {
      setDocumentsTypes(tData);
    });
    SupportingDocumentFileAPI.index({ supportable_id: member.id, supportable_type: 'User' }).then(fData => {
      setDocumentsFiles(fData);
    });
  }, []);

  /**
   * Return the file associated with the provided type
   */
  const getFileByType = (typeId: number): SupportingDocumentFile => {
    return _.find<SupportingDocumentFile>(documentsFiles, { supporting_document_type_id: typeId });
  };

  /**
   * Check if any supporting documents types has been defined.
   */
  const hasSupportingDocumentsTypes = (): boolean => {
    return documentsTypes.length > 0;
  };

  /**
   * Return the download URL of the given file
   */
  const getProofOfIdentityFileUrl = (documentId: number): string => {
    return `/api/supporting_document_files/${documentId}/download`;
  };

  /**
   * Open/closes the modal dialog to refuse the documents
   */
  const toggleModal = (): void => {
    setModalIsOpen(!modalIsOpen);
  };

  /**
   * Callback triggered when the refusal was successfully saved
   */
  const onSaveRefusalSuccess = (message: string): void => {
    setModalIsOpen(false);
    onSuccess(message);
  };

  return (
    <div className="supporting-documents-validation">
      <FabPanel>
        <h3>{t('app.admin.supporting_documents_validation.title')}</h3>
        <p className="info-area">{t('app.admin.supporting_documents_validation.find_below_documents_files')}</p>
        {documentsTypes.map((documentType: SupportingDocumentType) => {
          return (
            <div key={documentType.id} className="document-type">
              <div className="type-name">{documentType.name}</div>
              {getFileByType(documentType.id) && (
                <a href={getProofOfIdentityFileUrl(getFileByType(documentType.id).id)} target="_blank" rel="noreferrer">
                  <span className="filename">{getFileByType(documentType.id).attachment}</span>
                  <i className="fa fa-download"></i>
                </a>
              )}
              {!getFileByType(documentType.id) && (
                <div className="missing-file">{t('app.admin.supporting_documents_validation.to_complete')}</div>
              )}
            </div>
          );
        })}
      </FabPanel>
      {hasSupportingDocumentsTypes() && !member.validated_at && (
        <FabPanel className="refusal">
          <h3>{t('app.admin.supporting_documents_validation.refuse_documents')}</h3>
          <p className="text-black">{t('app.admin.supporting_documents_validation.refuse_documents_info')}</p>
          <FabButton className="refuse-btn" onClick={toggleModal}>{t('app.admin.supporting_documents_validation.refuse_documents')}</FabButton>
          <SupportingDocumentsRefusalModal
            isOpen={modalIsOpen}
            proofOfIdentityTypes={documentsTypes}
            toggleModal={toggleModal}
            operator={operator}
            member={member}
            onError={onError}
            onSuccess={onSaveRefusalSuccess}/>
        </FabPanel>
      )}
    </div>
  );
};

const SupportingDocumentsValidationWrapper: React.FC<SupportingDocumentsValidationProps> = (props) => {
  return (
    <Loader>
      <SupportingDocumentsValidation {...props} />
    </Loader>
  );
};

export { SupportingDocumentsValidationWrapper as SupportingDocumentsValidation };

Application.Components.component('supportingDocumentsValidation', react2angular(SupportingDocumentsValidationWrapper, ['operator', 'member', 'onSuccess', 'onError']));
