/**
 * This component ...
 */

import React from 'react';
import { react2angular } from 'react2angular';
import { Loader } from './loader';
import { IApplication } from '../models/application';
import { useTranslation } from 'react-i18next';
import { FabModal, ModalSize } from './fab-modal';
import { User } from '../models/user';


declare var Application: IApplication;

interface SelectGatewayModalModalProps {
  isOpen: boolean,
  toggleModal: () => void,
  currentUser: User,
}

const SelectGatewayModal: React.FC<SelectGatewayModalModalProps> = ({ isOpen, toggleModal }) => {

  const { t } = useTranslation('admin');


  return (
    <FabModal title={t('app.shared.stripe.online_payment')}
              isOpen={isOpen}
              toggleModal={toggleModal}
              width={ModalSize.medium}
              closeButton={false}
              className="stripe-modal">

    </FabModal>
  );
}

const StripeModalWrapper: React.FC<SelectGatewayModalModalProps> = ({ isOpen, toggleModal,currentUser }) => {
  return (
    <Loader>
      <SelectGatewayModal isOpen={isOpen} toggleModal={toggleModal} currentUser={currentUser} />
    </Loader>
  );
}

Application.Components.component('stripeModal', react2angular(StripeModalWrapper, ['isOpen', 'toggleModal', 'currentUser']));
