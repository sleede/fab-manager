/**
 * This component is a modal dialog that can wraps the application style
 */

import React from 'react';
import Modal from 'react-modal';
import { useTranslation } from 'react-i18next';
import { Loader } from './loader';
import CustomAsset from '../api/custom-asset';

Modal.setAppElement('body');

interface FabModalProps {
  title: string,
  isOpen: boolean,
  toggleModal: () => void
}

const blackLogoFile = CustomAsset.get('logo-black-file');

export const FabModal: React.FC<FabModalProps> = ({ title, isOpen, toggleModal, children }) => {
  const { t } = useTranslation('shared');
  const blackLogo = blackLogoFile.read();

  return (
    <Modal isOpen={isOpen}
           className="fab-modal"
           overlayClassName="fab-modal-overlay"
           onRequestClose={toggleModal}>
      <div className="fab-modal-header">
        <Loader>
          <img src={blackLogo.custom_asset_file_attributes.attachment_url}
               alt={blackLogo.custom_asset_file_attributes.attachment}
               className="modal-logo" />
        </Loader>
        <h1>{ title }</h1>
      </div>
      <div className="fab-modal-content">
        {children}
      </div>
      <div className="fab-modal-footer">
        <Loader>
          <button className="close-modal-btn" onClick={toggleModal}>{t('app.shared.buttons.close')}</button>
        </Loader>
      </div>
    </Modal>
  );
}

