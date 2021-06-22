import React, { useState } from 'react';
import { PrepaidPack } from '../../models/prepaid-pack';
import { FabModal } from '../base/fab-modal';

interface ConfigurePacksButtonProps {
  packs: Array<PrepaidPack>,
  onError: (message: string) => void,
}

/**
 * This component is a button that shows the list of prepaid-packs when moving the mouse over it.
 * When clicked, it opens a modal dialog to configure (add/delete/edit/remove) prepaid-packs.
 */
export const ConfigurePacksButton: React.FC<ConfigurePacksButtonProps> = ({ packs, onError }) => {
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
    <div className="configure-packs-button" onMouseOver={toggleShowList} onClick={handleAddPack}>
      <i className="fas fa-box-open" />
      {packs && showList && <div className="packs-overview">
        {packs.map(p => <div>{p.minutes / 60}h - {p.amount}</div>)}
      </div>}
      <FabModal isOpen={addPackModal} toggleModal={toggleAddPackModal}>NEW PACK</FabModal>
    </div>
  );
}
