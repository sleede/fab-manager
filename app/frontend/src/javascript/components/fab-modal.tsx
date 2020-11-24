/**
 * This component is a template for a modal dialog that wraps the application style
 */

import React, { ReactNode } from 'react';
import Modal from 'react-modal';
import { useTranslation } from 'react-i18next';
import { Loader } from './loader';
import CustomAssetAPI from '../api/custom-asset';
import { CustomAssetName } from '../models/custom-asset';

Modal.setAppElement('body');

interface FabModalProps {
  title: string,
  isOpen: boolean,
  toggleModal: () => void,
  confirmButton?: ReactNode
}

const blackLogoFile = CustomAssetAPI.get(CustomAssetName.LogoBlackFile);

export const FabModal: React.FC<FabModalProps> = ({ title, isOpen, toggleModal, children, confirmButton }) => {
  const { t } = useTranslation('shared');
  const blackLogo = blackLogoFile.read();

  /**
   * Check if the confirm button should be present
   */
  const hasConfirmButton = (): boolean => {
    return confirmButton !== undefined;
  }

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
          <button className="modal-btn--close" onClick={toggleModal}>{t('app.shared.buttons.close')}</button>
          {hasConfirmButton() && <span className="modal-btn--confirm">{confirmButton}</span>}
        </Loader>
      </div>
    </Modal>
  );
}

