import React, { BaseSyntheticEvent, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { ProofOfIdentityType } from '../../models/proof-of-identity-type';

interface ProofOfIdentityRefusalFormProps {
  proofOfIdentityTypes: Array<ProofOfIdentityType>,
  onChange: (field: string, value: string | Array<number>) => void,
}

/**
 * Form to set the stripe's public and private keys
 */
export const ProofOfIdentityRefusalForm: React.FC<ProofOfIdentityRefusalFormProps> = ({ proofOfIdentityTypes, onChange }) => {
  const { t } = useTranslation('admin');

  const [values, setValues] = useState<Array<number>>([]);
  const [message, setMessage] = useState<string>('');

  /**
   * Callback triggered when the name has changed.
   */
  const handleMessageChange = (e: BaseSyntheticEvent): void => {
    const { value } = e.target;
    setMessage(value);
    onChange('message', value);
  };

  /**
   * Callback triggered when a checkbox is ticked or unticked.
   * This function construct the resulting string, by adding or deleting the provided option identifier.
   */
  const handleProofOfIdnentityTypesChange = (value: number) => {
    return (event: BaseSyntheticEvent) => {
      let newValues: Array<number>;
      if (event.target.checked) {
        newValues = values.concat(value);
      } else {
        newValues = values.filter(x => x !== value);
      }
      setValues(newValues);
      onChange('proof_of_identity_type_ids', newValues);
    };
  };

  /**
   * Verify if the provided option is currently ticked (i.e. included in the value string)
   */
  const isChecked = (value: number) => {
    return values.includes(value);
  };

  return (
    <div className="proof-of-identity-type-form">
      <form name="proofOfIdentityRefusalForm">
        <div>
          {proofOfIdentityTypes.map(type => <div key={type.id} className="">
            <label htmlFor={`checkbox-${type.id}`}>{type.name}</label>
            <input id={`checkbox-${type.id}`} className="pull-right" type="checkbox" checked={isChecked(type.id)} onChange={handleProofOfIdnentityTypesChange(type.id)} />
          </div>)}
        </div>
        <div className="proof-of-identity-refusal-comment-textarea m-t">
          <label htmlFor="proof-of-identity-refusal-comment">{t('app.admin.members_edit.proof_of_identity_refusal_comment')}</label>
          <textarea
            id="proof-of-identity-refusal-comment"
            value={message}
            placeholder={t('app.admin.members_edit.proof_of_identity_refuse_input_message')}
            onChange={handleMessageChange}
            style={{ width: '100%' }}
            rows={5}
            required/>
        </div>
      </form>
    </div>
  );
};
