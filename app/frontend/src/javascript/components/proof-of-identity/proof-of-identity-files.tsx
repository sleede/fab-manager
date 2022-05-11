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

declare let Fablab: IFablab;

declare const Application: IApplication;

interface ProofOfIdentityFilesProps {
  currentUser: User,
  onSuccess: (message: string) => void,
  onError: (message: string) => void,
}

interface FilesType {
  number?: File
}

/**
 * This component upload the proof of identity file of member
 */
const ProofOfIdentityFiles: React.FC<ProofOfIdentityFilesProps> = ({ currentUser, onSuccess, onError }) => {
  const { t } = useTranslation('admin');

  const maxProofOfIdentityFileSizeMb = (Fablab.maxProofOfIdentityFileSize / 1024 / 1024).toFixed();

  // list of proof of identity type
  const [proofOfIdentityTypes, setProofOfIdentityTypes] = useState<Array<ProofOfIdentityType>>([]);
  const [proofOfIdentityFiles, setProofOfIdentityFiles] = useState<Array<ProofOfIdentityFile>>([]);
  const [files, setFiles] = useState<FilesType>({});
  const [errors, setErrors] = useState<Array<number>>([]);

  // get proof of identity type and files
  useEffect(() => {
    ProofOfIdentityTypeAPI.index({ group_id: currentUser.group_id }).then(tData => {
      setProofOfIdentityTypes(tData);
    });
    ProofOfIdentityFileAPI.index({ user_id: currentUser.id }).then(fData => {
      setProofOfIdentityFiles(fData);
    });
  }, []);

  const getProofOfIdentityFileByType = (proofOfIdentityTypeId: number): ProofOfIdentityFile => {
    return _.find<ProofOfIdentityFile>(proofOfIdentityFiles, { proof_of_identity_type_id: proofOfIdentityTypeId });
  };

  const hasFile = (proofOfIdentityTypeId: number): boolean => {
    return files[proofOfIdentityTypeId] || getProofOfIdentityFileByType(proofOfIdentityTypeId);
  };

  /**
   * Check if the current collection of proof of identity types is empty or not.
   */
  const hasProofOfIdentityTypes = (): boolean => {
    return proofOfIdentityTypes.length > 0;
  };

  const onFileChange = (poitId: number) => {
    return (event) => {
      const fileSize = event.target.files[0].size;
      let _errors = errors;
      if (fileSize > Fablab.maxProofOfIdentityFileSize) {
        _errors = errors.concat(poitId);
        setErrors(_errors);
      } else {
        _errors = errors.filter(e => e !== poitId);
      }
      setErrors(_errors);
      setFiles({
        ...files,
        [poitId]: event.target.files[0]
      });
    };
  };

  const onFileUpload = async () => {
    try {
      for (const proofOfIdentityTypeId of Object.keys(files)) {
        const formData = new FormData();

        formData.append('proof_of_identity_file[user_id]', currentUser.id.toString());
        formData.append('proof_of_identity_file[proof_of_identity_type_id]', proofOfIdentityTypeId);
        formData.append('proof_of_identity_file[attachment]', files[proofOfIdentityTypeId]);
        const proofOfIdentityFile = getProofOfIdentityFileByType(parseInt(proofOfIdentityTypeId, 10));
        if (proofOfIdentityFile) {
          await ProofOfIdentityFileAPI.update(proofOfIdentityFile.id, formData);
        } else {
          await ProofOfIdentityFileAPI.create(formData);
        }
      }
      if (Object.keys(files).length > 0) {
        ProofOfIdentityFileAPI.index({ user_id: currentUser.id }).then(fData => {
          setProofOfIdentityFiles(fData);
          setFiles({});
          onSuccess(t('app.admin.members_edit.proof_of_identity_files_successfully_uploaded'));
        });
      }
    } catch (e) {
      onError(t('app.admin.members_edit.proof_of_identity_files_unable_to_upload') + e);
    }
  };

  const getProofOfIdentityFileUrl = (poifId: number) => {
    return `/api/proof_of_identity_files/${poifId}/download`;
  };

  return (
    <section className="panel panel-default bg-light m-lg col-sm-12 col-md-12 col-lg-9">
      <h3>{t('app.admin.members_edit.proof_of_identity_files')}</h3>
      <p className="text-black font-sbold">{t('app.admin.members_edit.my_documents_info')}</p>
      <div className="alert alert-warning">
        <HtmlTranslate trKey="app.admin.members_edit.my_documents_alert" options={{ SIZE: maxProofOfIdentityFileSizeMb }}/>
      </div>
      <div className="widget-content no-bg auto">
        {proofOfIdentityTypes.map((poit: ProofOfIdentityType) => {
          return (
            <div className={`form-group ${errors.includes(poit.id) ? 'has-error' : ''}`} key={poit.id}>
              <label className="control-label m-r">{poit.name}</label>
              <div className="fileinput input-group">
                <div className="form-control">
                  {hasFile(poit.id) && (
                    <div>
                      <i className="glyphicon glyphicon-file fileinput-exists"></i> <span className="fileinput-filename">{files[poit.id]?.name || getProofOfIdentityFileByType(poit.id).attachment}</span>
                    </div>
                  )}
                  {getProofOfIdentityFileByType(poit.id) && !files[poit.id] && (
                    <a href={getProofOfIdentityFileUrl(getProofOfIdentityFileByType(poit.id).id)} target="_blank" style={{ position: 'absolute', right: '10px' }} rel="noreferrer"><i className="fa fa-download text-black "></i></a>
                  )}
                </div>
                <span className="input-group-addon btn btn-default btn-file">
                  {!hasFile(poit.id) && (
                    <span className="fileinput-new">Parcourir</span>
                  )}
                  {hasFile(poit.id) && (
                    <span className="fileinput-exists">Modifier</span>
                  )}
                  <input type="file"
                    accept="application/pdf,image/jpeg,image/jpg,image/png"
                    onChange={onFileChange(poit.id)}
                    required />
                </span>
              </div>
              {errors.includes(poit.id) && <span className="help-block">{t('app.admin.members_edit.proof_of_identity_file_size_error', { SIZE: maxProofOfIdentityFileSizeMb })}</span>}
            </div>
          );
        })}
      </div>
      {hasProofOfIdentityTypes() && (
        <button type="button" className="btn btn-warning m-b m-t pull-right" onClick={onFileUpload} disabled={errors.length > 0}>{t('app.admin.members_edit.save')}</button>
      )}
    </section>
  );
};

const ProofOfIdentityFilesWrapper: React.FC<ProofOfIdentityFilesProps> = ({ currentUser, onSuccess, onError }) => {
  return (
    <Loader>
      <ProofOfIdentityFiles currentUser={currentUser} onSuccess={onSuccess} onError={onError} />
    </Loader>
  );
};

Application.Components.component('proofOfIdentityFiles', react2angular(ProofOfIdentityFilesWrapper, ['currentUser', 'onSuccess', 'onError']));
