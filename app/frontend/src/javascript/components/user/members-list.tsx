import React from 'react';
import { IApplication } from '../../models/application';
import { Loader } from '../base/loader';
import { react2angular } from 'react2angular';
import { Member } from '../../models/member';
import { MembersListItem } from './members-list-item';

declare const Application: IApplication;

interface MembersListProps {
  members: Member[],
  onError: (message: string) => void,
  onSuccess: (message: string) => void
}

/**
 * Members list
 */
export const MembersList: React.FC<MembersListProps> = ({ members, onError, onSuccess }) => {
  return (
    <div className="members-list">
      {members.map(member => (
        <MembersListItem key={member.id} member={member} onError={onError} onSuccess={onSuccess} />
      ))}
    </div>
  );
};

const MembersListWrapper: React.FC<MembersListProps> = (props) => {
  return (
    <Loader>
      <MembersList {...props} />
    </Loader>
  );
};

Application.Components.component('membersList', react2angular(MembersListWrapper, ['members', 'onError', 'onSuccess']));
