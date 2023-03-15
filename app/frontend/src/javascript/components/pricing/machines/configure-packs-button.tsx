import { ReactNode, useState } from 'react';
import * as React from 'react';
import { PrepaidPack } from '../../../models/prepaid-pack';
import { useTranslation } from 'react-i18next';
import { FabPopover } from '../../base/fab-popover';
import { CreatePack } from './create-pack';
import PrepaidPackAPI from '../../../api/prepaid-pack';
import FormatLib from '../../../lib/format';
import { EditDestroyButtons } from '../../base/edit-destroy-buttons';
import { FabModal } from '../../base/fab-modal';
import { PackForm } from './pack-form';

interface ConfigurePacksButtonProps {
  packsData: Array<PrepaidPack>,
  onError: (message: string) => void,
  onSuccess: (message: string) => void,
  groupId: number,
  priceableId: number,
  priceableType: string,
}

/**
 * This component is a button that shows the list of prepaid-packs when moving the mouse over it.
 * It also triggers modal dialogs to configure (add/delete/edit/remove) prepaid-packs.
 */
export const ConfigurePacksButton: React.FC<ConfigurePacksButtonProps> = ({ packsData, onError, onSuccess, groupId, priceableId, priceableType }) => {
  const { t } = useTranslation('admin');

  const [packs, setPacks] = useState<Array<PrepaidPack>>(packsData);
  const [showList, setShowList] = useState<boolean>(false);
  const [isOpen, setIsOpen] = useState<boolean>(false);
  const [packData, setPackData] = useState<PrepaidPack>(null);

  /**
   * Return the number of hours, user-friendly formatted
   */
  const formatDuration = (minutes: number): string => {
    return t('app.admin.configure_packs_button.pack_DURATION', { DURATION: minutes / 60 });
  };

  /**
   * Open/closes the popover listing the existing packs
   */
  const toggleShowList = (): void => {
    setShowList(!showList);
  };

  /**
   * Callback triggered when the PrepaidPack was successfully created/deleted/updated.
   * We refresh the list of packs for the current tooltip to display the new data.
   */
  const handleSuccess = (message: string) => {
    onSuccess(message);
    PrepaidPackAPI.index({ group_id: groupId, priceable_id: priceableId, priceable_type: priceableType })
      .then(data => setPacks(data))
      .catch(error => onError(error));
  };

  /**
   * Render the button used to trigger the "new pack" modal
   */
  const renderAddButton = (): ReactNode => {
    return <CreatePack onSuccess={handleSuccess}
                       onError={onError}
                       groupId={groupId}
                       priceableId={priceableId}
                       priceableType={priceableType} />;
  };

  /**
   * Open/closes the "edit pack" modal dialog
   */
  const toggleModal = (): void => {
    setIsOpen(!isOpen);
  };

  /**
   * When the user clicks on the edition button, query the full data of the current pack from the API, then open the edition modal
   */
  const handleRequestEdit = (pack: PrepaidPack): void => {
    PrepaidPackAPI.get(pack.id)
      .then(data => {
        setPackData(data);
        toggleModal();
      })
      .catch(error => onError(error));
  };

  /**
   * Callback triggered when the user has validated the changes of the PrepaidPack
   */
  const handleUpdate = (pack: PrepaidPack): void => {
    PrepaidPackAPI.update(pack)
      .then(() => {
        handleSuccess(t('app.admin.configure_packs_button.pack_successfully_updated'));
        toggleModal();
      })
      .catch(error => onError(error));
  };

  return (
    <div className="configure-packs-button">
      <button className="packs-button" onClick={toggleShowList}>
        <i className="fas fa-box" />
      </button>
      {showList && <FabPopover title={t('app.admin.configure_packs_button.packs')} headerButton={renderAddButton()} position="right">
        <ul>
          {packs?.map(p =>
            <li key={p.id} className={p.disabled ? 'disabled' : ''}>
              {formatDuration(p.minutes)} - {FormatLib.price(p.amount)}
              <EditDestroyButtons className='pack-actions'
                                  onError={onError}
                                  onDeleteSuccess={handleSuccess}
                                  onEdit={() => handleRequestEdit(p)}
                                  itemId={p.id}
                                  itemType={t('app.admin.configure_packs_button.pack')}
                                  destroy={PrepaidPackAPI.destroy}/>
              <FabModal isOpen={isOpen}
                        toggleModal={toggleModal}
                        title={t('app.admin.configure_packs_button.edit_pack')}
                        className="edit-pack-modal"
                        closeButton
                        confirmButton={t('app.admin.configure_packs_button.confirm_changes')}
                        onConfirmSendFormId="edit-pack">
                        {packData && <PackForm formId="edit-pack" onSubmit={handleUpdate} pack={packData} />}
              </FabModal>
            </li>)}
        </ul>
        {packs?.length === 0 && <span>{t('app.admin.configure_packs_button.no_packs')}</span>}
      </FabPopover>}
    </div>
  );
};
