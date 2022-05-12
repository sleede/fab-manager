import React, { useState, useReducer } from 'react';
import { FormState, UseFormRegister, UseFormSetValue } from 'react-hook-form';
import { FieldValues } from 'react-hook-form/dist/types/fields';
import { User } from '../../models/user';
import { SocialNetwork } from '../../models/social-network';
import Icons from '../../../../images/social-icons.svg';
import { FormInput } from '../form/form-input';
import { Trash } from 'phosphor-react';
import { useTranslation } from 'react-i18next';

interface EditSocialsProps<TFieldValues> {
  register: UseFormRegister<TFieldValues>,
  setValue: UseFormSetValue<User>,
  networks: SocialNetwork[],
  formState: FormState<TFieldValues>,
  disabled: boolean|((id: string) => boolean),
}

export const EditSocials = <TFieldValues extends FieldValues>({ register, setValue, networks, formState, disabled }: EditSocialsProps<TFieldValues>) => {
  const { t } = useTranslation('shared');
  // regular expression to validate the the input fields
  const urlRegex = /^(https?:\/\/)([\da-z.-]+)\.([-a-z\d.]{2,30})([/\w .-]*)*\/?$/;

  const initSelectedNetworks = networks.filter(el => !['', null, undefined].includes(el.url));
  const [selectedNetworks, setSelectedNetworks] = useState(initSelectedNetworks);
  const selectNetwork = (network) => {
    setSelectedNetworks([...selectedNetworks, network]);
  };

  const reducer = (state, action) => {
    switch (action.type) {
      case 'delete':
        setSelectedNetworks(selectedNetworks.filter(el => el !== action.payload.network));
        setValue(action.payload.field, '');
        return state.map(el => el === action.payload.network
          ? { ...el, url: '' }
          : el);
      case 'update':
        return state.map(el => el === action.payload
          ? { ...el, url: action.payload.url }
          : el);
      default:
        return state;
    }
  };
  const [userNetworks, dispatch] = useReducer(reducer, networks);

  return (
    <>
      <div className='social-icons'>
        {userNetworks.map((network, index) =>
          !selectedNetworks.includes(network) && <img key={index} src={`${Icons}#${network.name}`} onClick={() => selectNetwork(network)}></img>
        )}
      </div>
      {selectNetwork.length && <div className='social-inputs'>
        {userNetworks.map((network, index) =>
          selectedNetworks.includes(network) &&
          <FormInput key={index}
                     id={`profile_attributes.${network.name}`}
                     register={register}
                     rules= {{
                       pattern: {
                         value: urlRegex,
                         message: t('app.shared.user_profile_form.website_invalid')
                       }
                     }}
                     formState={formState}
                     defaultValue={network.url}
                     label={network.name}
                     disabled={disabled}
                     placeholder={t('app.shared.text_editor.url_placeholder')}
                     icon={<img src={`${Icons}#${network.name}`}></img>}
                     addOn={<Trash size={16} />}
                     addOnAction={() => dispatch({ type: 'delete', payload: { network, field: `profile_attributes.${network.name}` } })} />
        )}
      </div>}
    </>
  );
};
