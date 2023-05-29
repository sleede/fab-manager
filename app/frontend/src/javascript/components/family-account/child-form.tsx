import React, { useState } from 'react';
import { useForm, useWatch } from 'react-hook-form';
import { useTranslation } from 'react-i18next';
import moment from 'moment';
import { Child } from '../../models/child';
import { FormInput } from '../form/form-input';
import { FabButton } from '../base/fab-button';
import { FormFileUpload } from '../form/form-file-upload';
import { FileType } from '../../models/file';
import { SupportingDocumentType } from '../../models/supporting-document-type';
import { User } from '../../models/user';
import { SupportingDocumentsRefusalModal } from '../supporting-documents/supporting-documents-refusal-modal';

interface ChildFormProps {
  child: Child;
  operator: User;
  onSubmit: (data: Child) => void;
  supportingDocumentsTypes: Array<SupportingDocumentType>;
  onSuccess: (message: string) => void,
  onError: (message: string) => void,
}

/**
 * A form for creating or editing a child.
 */
export const ChildForm: React.FC<ChildFormProps> = ({ child, onSubmit, supportingDocumentsTypes, operator, onSuccess, onError }) => {
  const { t } = useTranslation('public');

  const { register, formState, handleSubmit, setValue, control } = useForm<Child>({
    defaultValues: child
  });
  const output = useWatch<Child>({ control }); // eslint-disable-line
  const [refuseModalIsOpen, setRefuseModalIsOpen] = useState<boolean>(false);

  /**
   * get the name of the supporting document type by id
   */
  const getSupportingDocumentsTypeName = (id: number): string => {
    const supportingDocumentType = supportingDocumentsTypes.find((supportingDocumentType) => supportingDocumentType.id === id);
    return supportingDocumentType ? supportingDocumentType.name : '';
  };

  /**
   * Check if the current operator has administrative rights or is a normal member
   */
  const isPrivileged = (): boolean => {
    return (operator?.role === 'admin' || operator?.role === 'manager');
  };

  /**
   * Open/closes the modal dialog to refuse the documents
   */
  const toggleRefuseModal = (): void => {
    setRefuseModalIsOpen(!refuseModalIsOpen);
  };

  /**
   * Callback triggered when the refusal was successfully saved
   */
  const onSaveRefusalSuccess = (message: string): void => {
    setRefuseModalIsOpen(false);
    onSuccess(message);
  };

  return (
    <div className="child-form">
      {!isPrivileged() &&
        <div className="info-area">
          {t('app.public.child_form.child_form_info')}
        </div>
      }
      <form onSubmit={handleSubmit(onSubmit)}>
        <FormInput id="first_name"
          register={register}
          rules={{ required: true }}
          formState={formState}
          label={t('app.public.child_form.first_name')}
        />
        <FormInput id="last_name"
          register={register}
          rules={{ required: true }}
          formState={formState}
          label={t('app.public.child_form.last_name')}
        />
        <FormInput id="birthday"
          register={register}
          rules={{ required: true, validate: (value) => moment(value).isAfter(moment().subtract(18, 'year')) }}
          formState={formState}
          label={t('app.public.child_form.birthday')}
          type="date"
          max={moment().format('YYYY-MM-DD')}
          min={moment().subtract(18, 'year').format('YYYY-MM-DD')}
        />
        <FormInput id="phone"
          register={register}
          formState={formState}
          label={t('app.public.child_form.phone')}
          type="tel"
        />
        <FormInput id="email"
          register={register}
          formState={formState}
          label={t('app.public.child_form.email')}
        />
        {output.supporting_document_files_attributes.map((sf, index) => {
          if (isPrivileged()) {
            return (
              <div key={index} className="document-type">
                <div className="type-name">{getSupportingDocumentsTypeName(sf.supporting_document_type_id)}</div>
                {sf.attachment_url && (
                  <a href={sf.attachment_url} target="_blank" rel="noreferrer">
                    <span className="filename">{sf.attachment}</span>
                    <i className="fa fa-download"></i>
                  </a>
                )}
                {!sf.attachment_url && (
                  <div className="missing-file">{t('app.public.child_form.to_complete')}</div>
                )}
              </div>
            );
          }
          return (
            <FormFileUpload key={index}
              defaultFile={sf as FileType}
              id={`supporting_document_files_attributes.${index}`}
              accept="application/pdf"
              setValue={setValue}
              label={getSupportingDocumentsTypeName(sf.supporting_document_type_id)}
              showRemoveButton={false}
              register={register}
              formState={formState} />
          );
        })}

        <div className="actions">
          <FabButton type="button" onClick={handleSubmit(onSubmit)}>
            {t('app.public.child_form.save')}
          </FabButton>
          {isPrivileged() &&
            <div>
              <FabButton className="refuse-btn" onClick={toggleRefuseModal}>{t('app.public.child_form.refuse_documents')}</FabButton>
              <SupportingDocumentsRefusalModal
                isOpen={refuseModalIsOpen}
                proofOfIdentityTypes={supportingDocumentsTypes}
                toggleModal={toggleRefuseModal}
                operator={operator}
                supportable={child}
                documentType="Child"
                onError={onError}
                onSuccess={onSaveRefusalSuccess} />
            </div>
          }
        </div>
      </form>
    </div>
  );
};
