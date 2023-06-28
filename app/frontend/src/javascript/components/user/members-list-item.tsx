import React, { useState } from 'react';
import { useTranslation } from 'react-i18next';
import { Member } from '../../models/member';
import { Child } from '../../models/child';
import { FabButton } from '../base/fab-button';
import { CaretDown, User, Users, PencilSimple, Trash } from 'phosphor-react';
import { ChildItem } from '../family-account/child-item';

interface MembersListItemProps {
  member: Member,
  onError: (message: string) => void,
  onSuccess: (message: string) => void
  onEditChild: (child: Child) => void;
  onDeleteChild: (child: Child, error: string) => void;
  onDeleteMember: (memberId: number) => void;
}

/**
 * Members list
 */
export const MembersListItem: React.FC<MembersListItemProps> = ({ member, onError, onEditChild, onDeleteChild, onDeleteMember }) => {
  const { t } = useTranslation('admin');

  const [childrenList, setChildrenList] = useState(false);

  /**
   * Redirect to the given user edition page
   */
  const toMemberEdit = (memberId: number): void => {
    window.location.href = `/#!/admin/members/${memberId}/edit`;
  };

  /**
   * member and all his children are validated
   */
  const memberIsValidated = (): boolean => {
    return member.validated_at && member.children.every((child) => child.validated_at);
  };

  return (
    <div key={member.id} className={`members-list-item ${memberIsValidated() ? 'is-validated' : ''} ${member.need_completion ? 'is-incomplet' : ''}`}>
      <div className="left-col">
        <div className='status'>
          {(member.children.length > 0)
            ? <Users size={24} weight="bold" />
            : <User size={24} weight="bold" />
          }
        </div>
        {(member.children.length > 0) &&
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

        <div className="member-actions edit-destroy-buttons">
          <FabButton onClick={() => toMemberEdit(member.id)} className="edit-btn">
            <PencilSimple size={20} weight="fill" />
          </FabButton>
          <FabButton onClick={() => onDeleteMember(member.id)} className="delete-btn">
            <Trash size={20} weight="fill" />
          </FabButton>
        </div>
      </div>

      { (member.children.length > 0) &&
        <div className={`member-children ${childrenList ? 'open' : ''}`}>
          <hr />
          {member.children.map((child: Child) => (
            <ChildItem key={child.id} child={child} size='sm' onEdit={onEditChild} onDelete={onDeleteChild} onError={onError} />
          ))}
        </div>
      }
    </div>
  );
};
