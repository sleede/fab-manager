import React, { useState } from 'react';
import { PrepaidPack } from '../../models/prepaid-pack';
import { FabModal } from '../base/fab-modal';
import { useTranslation } from 'react-i18next';

interface ConfigurePacksButtonProps {
  packs: Array<PrepaidPack>,
  onError: (message: string) => void,
}

/**
 * This component is a button that shows the list of prepaid-packs when moving the mouse over it.
 * When clicked, it opens a modal dialog to configure (add/delete/edit/remove) prepaid-packs.
 */
export const ConfigurePacksButton: React.FC<ConfigurePacksButtonProps> = ({ packs, onError }) => {
  const { t } = useTranslation('admin');
  const [showList, setShowList] = useState<boolean>(false);
  const [addPackModal, setAddPackModal] = useState<boolean>(false);

  const toggleShowList = (): void => {
    setShowList(!showList);
  }

  const toggleAddPackModal = (): void => {
    setAddPackModal(!addPackModal);
  }

  const handleAddPack = (): void => {
    toggleAddPackModal();
  }

  return (
    <div className="configure-packs-button" onClick={toggleShowList}>
      <button className="packs-button">
        <i className="fas fa-box" />
      </button>
      {showList && <div className="packs-popover">
        <div className="popover-title">
          <h3>{t('app.admin.configure_packs_button.packs')}</h3>
          <button className="add-pack-button" onClick={handleAddPack}><i className="fas fa-plus"/></button>
        </div>
        <div className="popover-content">
          <ul>
            {packs?.map(p => <li key={p.id}>{p.minutes / 60}h - {p.amount}</li>)}
          </ul>
          {packs?.length === 0 && <span>{t('app.admin.configure_packs_button.no_packs')}</span>}
        </div>
      </div>}
    <FabModal isOpen={addPackModal} toggleModal={toggleAddPackModal}>NEW PACK</FabModal>
    </div>
  );
}
