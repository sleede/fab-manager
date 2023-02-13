import { BaseSyntheticEvent, useState } from 'react';
import * as React from 'react';
import { useTranslation } from 'react-i18next';
import { SupportingDocumentType } from '../../models/supporting-document-type';

interface SupportingDocumentsRefusalFormProps {
  proofOfIdentityTypes: Array<SupportingDocumentType>,
  onChange: (field: string, value: string | Array<number>) => void,
}

/**
 * Form to set the refuse the uploaded supporting documents
 */
export const SupportingDocumentsRefusalForm: React.FC<SupportingDocumentsRefusalFormProps> = ({ proofOfIdentityTypes, onChange }) => {
  const { t } = useTranslation('admin');

  const [values, setValues] = useState<Array<number>>([]);
  const [message, setMessage] = useState<string>('');

  /**
   * Callback triggered when the message has changed.
   */
  const handleMessageChange = (e: BaseSyntheticEvent): void => {
    const { value } = e.target;
    setMessage(value);
    onChange('message', value);
  };

  /**
   * Callback triggered when the document type checkbox is ticked or unticked.
   */
  const handleTypeSelectionChange = (value: number) => {
    return (event: BaseSyntheticEvent) => {
      let newValues: Array<number>;
      if (event.target.checked) {
        newValues = values.concat(value);
      } else {
        newValues = values.filter(x => x !== value);
      }
      setValues(newValues);
      onChange('supporting_document_type_ids', newValues);
    };
  };

  /**
   * Verify if the provided type is currently ticked (i.e. about to be refused)
   */
  const isChecked = (typeId: number) => {
    return values.includes(typeId);
  };

  return (
    <div className="supporting-documents-refusal-form">
      <form name="proofOfIdentityRefusalForm">
        <div>
          {proofOfIdentityTypes.map(type => <div key={type.id}>
            <label htmlFor={`checkbox-${type.id}`}>{type.name}</label>
            <input id={`checkbox-${type.id}`}
              type="checkbox"
              checked={isChecked(type.id)}
              onChange={handleTypeSelectionChange(type.id)} />
          </div>)}
        </div>
        <div className="refusal-comment">
          <label htmlFor="proof-of-identity-refusal-comment">
            {t('app.admin.supporting_documents_refusal_form.refusal_comment')}
          </label>
          <textarea
            id="proof-of-identity-refusal-comment"
            value={message}
            placeholder={t('app.admin.supporting_documents_refusal_form.comment_placeholder')}
            onChange={handleMessageChange}
            style={{ width: '100%' }}
            rows={5}
            required/>
        </div>
      </form>
    </div>
  );
};
