import React from 'react';
import { Child } from '../../models/child';
import { useTranslation } from 'react-i18next';
import { FabButton } from '../base/fab-button';
import FormatLib from '../../lib/format';
import { DeleteChildModal } from './delete-child-modal';
import ChildAPI from '../../api/child';

interface ChildItemProps {
  child: Child;
  onEdit: (child: Child) => void;
  onDelete: (error: string) => void;
  onError: (error: string) => void;
}

/**
 * A child item.
 */
export const ChildItem: React.FC<ChildItemProps> = ({ child, onEdit, onDelete, onError }) => {
  const { t } = useTranslation('public');
  const [isOpenDeleteChildModal, setIsOpenDeleteChildModal] = React.useState<boolean>(false);

  /**
   * Toggle the delete child modal
   */
  const toggleDeleteChildModal = () => setIsOpenDeleteChildModal(!isOpenDeleteChildModal);

  /**
   * Delete a child
   */
  const deleteChild = () => {
    ChildAPI.destroy(child.id).then(() => {
      toggleDeleteChildModal();
      onDelete(t('app.public.child_item.deleted'));
    }).catch(() => {
      onError(t('app.public.child_item.unable_to_delete'));
    });
  };

  return (
    <div className="child-item">
      <div className="child-lastname">
        <span>{t('app.public.child_item.last_name')}</span>
        <div>{child.last_name}</div>
      </div>
      <div className="child-firstname">
        <span>{t('app.public.child_item.first_name')}</span>
        <div>{child.first_name}</div>
      </div>
      <div className="date">
        <span>{t('app.public.child_item.birthday')}</span>
        <div>{FormatLib.date(child.birthday)}</div>
      </div>
      <div className="actions">
        <FabButton icon={<i className="fa fa-edit" />} onClick={() => onEdit(child)} className="edit-button" />
        <FabButton icon={<i className="fa fa-trash" />} onClick={toggleDeleteChildModal} className="delete-button" />
        <DeleteChildModal isOpen={isOpenDeleteChildModal} toggleModal={toggleDeleteChildModal} child={child} onDelete={deleteChild} />
      </div>
    </div>
  );
};
