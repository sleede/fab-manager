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
        <FabButton icon={<i className="fa fa-trash" />} onClick={() => onDelete(child)} className="delete-button" />
      </div>
    </div>
  );
};
