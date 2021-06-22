import React, { useState } from 'react';
import { PrepaidPack } from '../../models/prepaid-pack';

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

  const toggleShowList = (): void => {
    setShowList(!showList);
  }
  const handleAddPack = (): void => {
    //TODO, open a modal to add a new pack
  }

  return (
    <div className="configure-packs-button" onMouseOver={toggleShowList} onClick={handleAddPack}>
      {packs && showList && <div className="packs-overview">
        {packs.map(p => <div>{p.minutes / 60}h - {p.amount}</div>)}
      </div>}
    </div>
  );
}
