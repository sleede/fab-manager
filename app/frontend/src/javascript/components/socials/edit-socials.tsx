import { useState, useReducer } from 'react';
import { FormState, UseFormRegister, UseFormSetValue } from 'react-hook-form';
import { FieldValues } from 'react-hook-form/dist/types/fields';
import { User } from '../../models/user';
import { SocialNetwork } from '../../models/social-network';
import Icons from '../../../../images/icons.svg';
import { FormInput } from '../form/form-input';
import { Trash } from 'phosphor-react';
import { useTranslation } from 'react-i18next';
import ValidationLib from '../../lib/validation';

interface EditSocialsProps<TFieldValues> {
  register: UseFormRegister<TFieldValues>,
  setValue: UseFormSetValue<User>,
  networks: SocialNetwork[],
  formState: FormState<TFieldValues>,
  disabled: boolean|((id: string) => boolean),
}

/**
 * Allow a user to edit its personnal social networks
 */
export const EditSocials = <TFieldValues extends FieldValues>({ register, setValue, networks, formState, disabled }: EditSocialsProps<TFieldValues>) => {
  const { t } = useTranslation('shared');

  const initSelectedNetworks = networks.filter(el => !['', null, undefined].includes(el.url));
  const [selectedNetworks, setSelectedNetworks] = useState(initSelectedNetworks);

  /**
   * Callback triggered when the user adds a network, from the list of available networks, to the editable networks.
   */
  const selectNetwork = (network) => {
    setSelectedNetworks([...selectedNetworks, network]);
  };

  /**
   * Return a derivated state of the selected networks list, depending on the given action.
   */
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
          !selectedNetworks.includes(network) && <svg key={index} onClick={() => selectNetwork(network)} viewBox="0 0 24 24" >
            <use href={`${Icons}#${network.name}`} />
        </svg>
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
                         value: ValidationLib.urlRegex,
                         message: t('app.shared.edit_socials.website_invalid')
                       }
                     }}
                     formState={formState}
                     defaultValue={network.url}
                     label={network.name}
                     disabled={disabled}
                     placeholder={t('app.shared.edit_socials.url_placeholder')}
                     icon={<svg viewBox="0 0 24 24"><use href={`${Icons}#${network.name}`}/></svg>}
                     addOn={<Trash size={16} />}
                     addOnAction={() => dispatch({ type: 'delete', payload: { network, field: `profile_attributes.${network.name}` } })} />
        )}
      </div>}
    </>
  );
};
