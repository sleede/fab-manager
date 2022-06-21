import React, { useState, useEffect } from 'react';
import { useTranslation } from 'react-i18next';
import { react2angular } from 'react2angular';
import _ from 'lodash';
import { HtmlTranslate } from '../base/html-translate';
import { Loader } from '../base/loader';
import { User } from '../../models/user';
import { IApplication } from '../../models/application';
import { ProofOfIdentityType } from '../../models/proof-of-identity-type';
import { ProofOfIdentityFile } from '../../models/proof-of-identity-file';
import ProofOfIdentityTypeAPI from '../../api/proof-of-identity-type';
import ProofOfIdentityFileAPI from '../../api/proof-of-identity-file';
import { IFablab } from '../../models/fablab';
import { FabAlert } from '../base/fab-alert';

declare let Fablab: IFablab;

declare const Application: IApplication;

interface SupportingDocumentsFilesProps {
  currentUser: User,
  onSuccess: (message: string) => void,
  onError: (message: string) => void,
}

interface FilesType {
  number?: File
}

/**
 * This component upload the supporting documents file of the member
 */
export const SupportingDocumentsFiles: React.FC<SupportingDocumentsFilesProps> = ({ currentUser, onSuccess, onError }) => {
  const { t } = useTranslation('logged');

  const maxProofOfIdentityFileSizeMb = (Fablab.maxProofOfIdentityFileSize / 1024 / 1024).toFixed();

  // list of supporting documents type
  const [supportingDocumentsTypes, setSupportingDocumentsTypes] = useState<Array<ProofOfIdentityType>>([]);
  const [supportingDocumentsFiles, setSupportingDocumentsFiles] = useState<Array<ProofOfIdentityFile>>([]);
  const [files, setFiles] = useState<FilesType>({});
  const [errors, setErrors] = useState<Array<number>>([]);

  // get supporting documents type and files
  useEffect(() => {
    ProofOfIdentityTypeAPI.index({ group_id: currentUser.group_id }).then(tData => {
      setSupportingDocumentsTypes(tData);
    });
    ProofOfIdentityFileAPI.index({ user_id: currentUser.id }).then(fData => {
      setSupportingDocumentsFiles(fData);
    });
  }, []);

  /**
   * Return the files matching the given type id
   */
  const getSupportingDocumentsFileByType = (supportingDocumentsTypeId: number): ProofOfIdentityFile => {
    return _.find<ProofOfIdentityFile>(supportingDocumentsFiles, {
      proof_of_identity_type_id: supportingDocumentsTypeId
    });
  };

  /**
   * Check if the given type has any uploaded files
   */
  const hasFile = (proofOfIdentityTypeId: number): boolean => {
    return files[proofOfIdentityTypeId] || getSupportingDocumentsFileByType(proofOfIdentityTypeId);
  };

  /**
   * Check if the current collection of supporting documents types is empty or not.
   */
  const hasProofOfIdentityTypes = (): boolean => {
    return supportingDocumentsTypes.length > 0;
  };

  /**
   * Callback triggered when a file is selected by the member: check if the file does not exceed the maximum allowed size
   */
  const onFileChange = (documentId: number) => {
    return (event) => {
      const fileSize = event.target.files[0].size;
      let _errors: Array<number>;
      if (fileSize > Fablab.maxProofOfIdentityFileSize) {
        _errors = errors.concat(documentId);
        setErrors(_errors);
      } else {
        _errors = errors.filter(e => e !== documentId);
      }
      setErrors(_errors);
      setFiles({
        ...files,
        [documentId]: event.target.files[0]
      });
    };
  };

  /**
   * Callback triggered when the user clicks on save: upload the file to the API
   */
  const onFileUpload = async () => {
    try {
      for (const proofOfIdentityTypeId of Object.keys(files)) {
        const formData = new FormData();

        formData.append('proof_of_identity_file[user_id]', currentUser.id.toString());
        formData.append('proof_of_identity_file[proof_of_identity_type_id]', proofOfIdentityTypeId);
        formData.append('proof_of_identity_file[attachment]', files[proofOfIdentityTypeId]);
        const proofOfIdentityFile = getSupportingDocumentsFileByType(parseInt(proofOfIdentityTypeId, 10));
        if (proofOfIdentityFile) {
          await ProofOfIdentityFileAPI.update(proofOfIdentityFile.id, formData);
        } else {
          await ProofOfIdentityFileAPI.create(formData);
        }
      }
      if (Object.keys(files).length > 0) {
        ProofOfIdentityFileAPI.index({ user_id: currentUser.id }).then(fData => {
          setSupportingDocumentsFiles(fData);
          setFiles({});
          onSuccess(t('app.logged.dashboard.supporting_documents_files.file_successfully_uploaded'));
        });
      }
    } catch (e) {
      onError(t('app.logged.dashboard.supporting_documents_files.unable_to_upload') + e);
    }
  };

  /**
   * Return the download URL of the given file
   */
  const getSupportingDocumentsFileUrl = (documentId: number) => {
    return `/api/proof_of_identity_files/${documentId}/download`;
  };

  return (
    <section className="supporting-documents-files">
      <h3>{t('app.logged.dashboard.supporting_documents_files.supporting_documents_files')}</h3>
      <p className="info-area">{t('app.logged.dashboard.supporting_documents_files.my_documents_info')}</p>
      <FabAlert level="warning">
        <HtmlTranslate trKey="app.logged.dashboard.supporting_documents_files.upload_limits_alert_html"
          options={{ SIZE: maxProofOfIdentityFileSizeMb }}/>
      </FabAlert>
      <div className="files-list">
        {supportingDocumentsTypes.map((documentType: ProofOfIdentityType) => {
          return (
            <div className={`file-item ${errors.includes(documentType.id) ? 'has-error' : ''}`} key={documentType.id}>
              <label>{documentType.name}</label>
              <div className="fileinput">
                <div className="filename-container">
                  {hasFile(documentType.id) && (
                    <div>
                      <i className="fa fa-file fileinput-exists" />
                      <span className="fileinput-filename">
                        {files[documentType.id]?.name || getSupportingDocumentsFileByType(documentType.id).attachment}
                      </span>
                    </div>
                  )}
                  {getSupportingDocumentsFileByType(documentType.id) && !files[documentType.id] && (
                    <a href={getSupportingDocumentsFileUrl(getSupportingDocumentsFileByType(documentType.id).id)}
                      target="_blank"
                      className="file-download"
                      rel="noreferrer">
                      <i className="fa fa-download"/>
                    </a>
                  )}
                </div>
                <span className="fileinput-button">
                  {!hasFile(documentType.id) && (
                    <span className="fileinput-new">{t('app.logged.dashboard.supporting_documents_files.browse')}</span>
                  )}
                  {hasFile(documentType.id) && (
                    <span className="fileinput-exists">{t('app.logged.dashboard.supporting_documents_files.edit')}</span>
                  )}
                  <input type="file"
                    accept="application/pdf,image/jpeg,image/jpg,image/png"
                    onChange={onFileChange(documentType.id)}
                    required />
                </span>
              </div>
              {errors.includes(documentType.id) && <span className="errors-area">
                {t('app.logged.dashboard.supporting_documents_files.file_size_error', { SIZE: maxProofOfIdentityFileSizeMb })}
              </span>}
            </div>
          );
        })}
      </div>
      {hasProofOfIdentityTypes() && (
        <button type="button" className="save-btn" onClick={onFileUpload} disabled={errors.length > 0}>
          {t('app.logged.dashboard.supporting_documents_files.save')}
        </button>
      )}
    </section>
  );
};

const SupportingDocumentsFilesWrapper: React.FC<SupportingDocumentsFilesProps> = ({ currentUser, onSuccess, onError }) => {
  return (
    <Loader>
      <SupportingDocumentsFiles currentUser={currentUser} onSuccess={onSuccess} onError={onError} />
    </Loader>
  );
};

Application.Components.component('supportingDocumentsFiles', react2angular(SupportingDocumentsFilesWrapper, ['currentUser', 'onSuccess', 'onError']));
