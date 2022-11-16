import { ReactNode, BaseSyntheticEvent, useEffect } from 'react';
import * as React from 'react';
import Modal from 'react-modal';
import { useTranslation } from 'react-i18next';
import { Loader } from './loader';
import { FabButton } from './fab-button';

Modal.setAppElement('body');

export enum ModalSize {
  small = 'sm',
  medium = 'md',
  large = 'lg'
}

interface FabModalProps {
  title?: string,
  isOpen: boolean,
  toggleModal: () => void,
  confirmButton?: ReactNode,
  closeButton?: boolean,
  className?: string,
  width?: ModalSize,
  customHeader?: ReactNode,
  customFooter?: ReactNode,
  onConfirm?: (event: BaseSyntheticEvent) => void,
  onClose?: (event: BaseSyntheticEvent) => void,
  preventConfirm?: boolean,
  onCreation?: () => void,
  onConfirmSendFormId?: string,
}

/**
 * This component is a template for a modal dialog that wraps the application style
 */
export const FabModal: React.FC<FabModalProps> = ({ title, isOpen, toggleModal, children, confirmButton, className, width = 'sm', closeButton, customHeader, customFooter, onConfirm, onClose, preventConfirm, onCreation, onConfirmSendFormId }) => {
  const { t } = useTranslation('shared');

  useEffect(() => {
    if (typeof onCreation === 'function' && isOpen) {
      onCreation();
    }
  }, [isOpen]);

  /**
   * Callback triggered when the user request to close the modal without confirming.
   */
  const handleClose = (event) => {
    if (typeof onClose === 'function') onClose(event);
    toggleModal();
  };

  return (
    <Modal isOpen={isOpen}
      className={`fab-modal fab-modal-${width} ${className || ''}`}
      overlayClassName="fab-modal-overlay"
      onRequestClose={handleClose}>
      {closeButton && <FabButton className="modal-btn--close" onClick={handleClose}>{t('app.shared.fab_modal.close')}</FabButton>}
      <div className="fab-modal-header">
        {!customHeader && <h1>{ title }</h1>}
        {customHeader && customHeader}
      </div>
      <div className="fab-modal-content">
        {children}
      </div>
      {(customFooter || confirmButton) && <div className="fab-modal-footer">
        <Loader>
          {confirmButton && !onConfirmSendFormId && <FabButton className="modal-btn--confirm" disabled={preventConfirm} onClick={onConfirm}>{confirmButton}</FabButton>}
          {confirmButton && onConfirmSendFormId && <FabButton className="modal-btn--confirm" disabled={preventConfirm} type="submit" form={onConfirmSendFormId}>{confirmButton}</FabButton>}
          {customFooter && customFooter}
        </Loader>
      </div>}
    </Modal>
  );
};
