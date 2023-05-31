import React, { useEffect, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { Member } from '../../models/member';
import { Child } from '../../models/child';
import ChildAPI from '../../api/child';
import { FabButton } from '../base/fab-button';
import { CaretDown, User, Users } from 'phosphor-react';
import { ChildItem } from '../family-account/child-item';
import { EditDestroyButtons } from '../base/edit-destroy-buttons';

interface MembersListItemProps {
  member: Member,
  onError: (message: string) => void,
  onSuccess: (message: string) => void
}

/**
 * Members list
 */
export const MembersListItem: React.FC<MembersListItemProps> = ({ member, onError, onSuccess }) => {
  const { t } = useTranslation('admin');

  const [children, setChildren] = useState<Array<Child>>([]);
  const [childrenList, setChildrenList] = useState(false);

  useEffect(() => {
    ChildAPI.index({ user_id: member.id }).then(setChildren);
  }, [member]);

  /**
   * Redirect to the given user edition page
   */
  const toMemberEdit = (memberId: number): void => {
    window.location.href = `/#!/admin/members/${memberId}/edit`;
  };

  return (
    <div key={member.id} className={`members-list-item ${member.validated_at ? 'is-validated' : ''} ${member.need_completion ? 'is-incomplet' : ''}`}>
      <div className="left-col">
        <div className='status'>
          {(children.length > 0)
            ? <Users size={24} weight="bold" />
            : <User size={24} weight="bold" />
          }
        </div>
        {(children.length > 0) &&
          <FabButton onClick={() => setChildrenList(!childrenList)} className={`toggle ${childrenList ? 'open' : ''}`}>
            <CaretDown size={24} weight="bold" />
          </FabButton>
        }
      </div>

      <div className="member">
        <div className="member-infos">
          <div>
            <span>{t('app.admin.members_list_item.surname')}</span>
            <p>{member.profile.last_name}</p>
          </div>
          <div>
            <span>{t('app.admin.members_list_item.first_name')}</span>
            <p>{member.profile.first_name}</p>
          </div>
          <div>
            <span>{t('app.admin.members_list_item.phone')}</span>
            <p>{member.profile.phone || '---'}</p>
          </div>
          <div>
            <span>{t('app.admin.members_list_item.email')}</span>
            <p>{member.email}</p>
          </div>
          <div>
            <span>{t('app.admin.members_list_item.group')}</span>
            <p>{member.group.name}</p>
          </div>
          <div>
            <span>{t('app.admin.members_list_item.subscription')}</span>
            <p>{member.subscribed_plan?.name || '---'}</p>
          </div>
        </div>

        <div className="member-actions">
          {/* TODO: <EditDestroyButtons> */}
          <EditDestroyButtons onError={onError}
                              onEdit={() => toMemberEdit(member.id)}
                              onDeleteSuccess={() => onSuccess}
                              itemId={member.id}
                              itemType={t('app.admin.members_list_item.item_type')}
                              destroy={() => new Promise(() => console.log(`Delete member ${member.id}`))} />
        </div>
      </div>

      { (children.length > 0) &&
        <div className={`member-children ${childrenList ? 'open' : ''}`}>
          <hr />
          {children.map(child => (
            <ChildItem key={child.id} child={child} size='sm' onEdit={() => console.log('edit child')} onDelete={() => console.log('delete child')} onError={onError} />
          ))}
        </div>
      }
    </div>
  );
};
