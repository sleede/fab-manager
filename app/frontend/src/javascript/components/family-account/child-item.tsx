import React from 'react';
import { Child } from '../../models/child';
import { useTranslation } from 'react-i18next';
import { FabButton } from '../base/fab-button';
import FormatLib from '../../lib/format';
import { DeleteChildModal } from './delete-child-modal';
import ChildAPI from '../../api/child';
import { PencilSimple, Trash, UserSquare } from 'phosphor-react';

interface ChildItemProps {
  child: Child;
  size: 'sm' | 'lg';
  onEdit: (child: Child) => void;
  onDelete: (error: string) => void;
  onError: (error: string) => void;
}

/**
 * A child item.
 */
export const ChildItem: React.FC<ChildItemProps> = ({ child, size, onEdit, onDelete, onError }) => {
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
    <div className={`child-item ${size} ${child.validated_at ? 'is-validated' : ''}`}>
      <div className='status'>
        <UserSquare size={24} weight="light" />
      </div>
      <div>
        <span>{t('app.public.child_item.last_name')}</span>
        <p>{child.last_name}</p>
      </div>
      <div>
        <span>{t('app.public.child_item.first_name')}</span>
        <p>{child.first_name}</p>
      </div>
      <div>
        <span>{t('app.public.child_item.birthday')}</span>
        <p>{FormatLib.date(child.birthday)}</p>
      </div>
      <div className="actions edit-destroy-buttons">
        <FabButton onClick={() => onEdit(child)} className="edit-btn">
          <PencilSimple size={20} weight="fill" />
        </FabButton>
        <FabButton onClick={toggleDeleteChildModal} className="delete-btn">
          <Trash size={20} weight="fill" />
        </FabButton>
        <DeleteChildModal isOpen={isOpenDeleteChildModal} toggleModal={toggleDeleteChildModal} child={child} onDelete={deleteChild} />
      </div>
    </div>
  );
};
