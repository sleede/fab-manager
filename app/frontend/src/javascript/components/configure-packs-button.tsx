import React, { useEffect, useState } from 'react';
import PrepaidPackAPI from '../api/prepaid-pack';
import { IndexFilter, PrepaidPack } from '../models/prepaid-pack';
import { Loader } from './base/loader';
import { react2angular } from 'react2angular';
import { IApplication } from '../models/application';

declare var Application: IApplication;

interface ConfigurePacksButtonParams {
  groupId: number,
  priceableId: number,
  priceableType: string,
  onError: (message: string) => void,
}

/**
 * This component is a button that shows the list of prepaid-packs when moving the mouse over it.
 * When clicked, it opens a modal dialog to configure (add/delete/edit/remove) prepaid-packs.
 */
const ConfigurePacksButton: React.FC<ConfigurePacksButtonParams> = ({ groupId, priceableId, priceableType, onError }) => {
  const [packs, setPacks] = useState<Array<PrepaidPack>>(null);
  const [showList, setShowList] = useState<boolean>(false);

  useEffect(() => {
    PrepaidPackAPI.index(buildFilters())
      .then(data => setPacks(data))
      .catch(error => onError(error))
  }, [])

  /**
   * Build the filters for the current ConfigurePackButton, to query the API and get the concerned packs.
   */
  const buildFilters = (): Array<IndexFilter> => {
    const res = [];
    if (groupId) res.push({ key: 'group_id', value: groupId });
    if (priceableId) res.push({ key: 'priceable_id', value: priceableId });
    if (priceableType) res.push({ key: 'priceable_type', value: priceableType });

    return res;
  }

  const toggleShowList = (): void => {
    setShowList(!showList);
  }

  return (
    <div className="configure-packs-button" onMouseOver={toggleShowList}>
      {packs && showList && <div className="packs-overview">
        {packs.map(p => <div>{p.minutes / 60}h - {p.amount}</div>)}
      </div>}
    </div>
  );
}
const ConfigurePacksButtonWrapper: React.FC<ConfigurePacksButtonParams> = ({ groupId, priceableId, priceableType, onError }) => {
  return (
    <Loader>
      <ConfigurePacksButton groupId={groupId} priceableId={priceableId} priceableType={priceableType} onError={onError}/>
    </Loader>
  );
}

Application.Components.component('configurePacksButton', react2angular(ConfigurePacksButtonWrapper, ['groupId', 'priceableId', 'priceableType', 'onError']));


