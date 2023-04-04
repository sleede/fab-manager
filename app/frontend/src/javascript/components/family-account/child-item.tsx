import React from 'react';
import { Child } from '../../models/child';
import { useTranslation } from 'react-i18next';
import { FabButton } from '../base/fab-button';
import FormatLib from '../../lib/format';

interface ChildItemProps {
  child: Child;
  onEdit: (child: Child) => void;
  onDelete: (child: Child) => void;
}

/**
 * A child item.
 */
export const ChildItem: React.FC<ChildItemProps> = ({ child, onEdit, onDelete }) => {
  const { t } = useTranslation('public');

  return (
    <div className="child-item">
      <div>
        <div>{t('app.public.child_item.last_name')}</div>
        <div>{child.last_name}</div>
      </div>
      <div>
        <div>{t('app.public.child_item.first_name')}</div>
        <div>{child.first_name}</div>
      </div>
      <div>
        <div>{t('app.public.child_item.birthday')}</div>
        <div>{FormatLib.date(child.birthday)}</div>
      </div>
      <div className="actions">
        <FabButton icon={<i className="fa fa-edit" />} onClick={() => onEdit(child)} className="edit-button" />
        <FabButton icon={<i className="fa fa-trash" />} onClick={() => onDelete(child)} className="delete-button" />
      </div>
    </div>
  );
};
