import React, { useState, useEffect } from 'react';
import { IApplication } from '../../models/application';
import { Loader } from '../base/loader';
import { react2angular } from 'react2angular';
import { Member } from '../../models/member';
import { MembersListItem } from './members-list-item';
import { SupportingDocumentType } from '../../models/supporting-document-type';
import SupportingDocumentTypeAPI from '../../api/supporting-document-type';
import { Child } from '../../models/child';
import { ChildModal } from '../family-account/child-modal';
import { User } from '../../models/user';

declare const Application: IApplication;

interface MembersListProps {
  members: Member[],
  operator: User,
  onError: (message: string) => void,
  onSuccess: (message: string) => void
  onDeleteMember: (memberId: number) => void;
  onDeletedChild: (memberId: number, childId: number) => void;
  onUpdatedChild: (memberId: number, child: Child) => void;
}

/**
 * Members list
 */
export const MembersList: React.FC<MembersListProps> = ({ members, onError, onSuccess, operator, onDeleteMember, onDeletedChild, onUpdatedChild }) => {
  const [supportingDocumentsTypes, setSupportingDocumentsTypes] = useState<Array<SupportingDocumentType>>([]);
  const [child, setChild] = useState<Child>();
  const [isOpenChildModal, setIsOpenChildModal] = useState<boolean>(false);

  useEffect(() => {
    SupportingDocumentTypeAPI.index({ document_type: 'Child' }).then(tData => {
      setSupportingDocumentsTypes(tData);
    });
  }, []);

  /**
   * Open the edit child modal
   */
  const editChild = (child: Child) => {
    setIsOpenChildModal(true);
    setChild({
      ...child,
      supporting_document_files_attributes: supportingDocumentsTypes.map(t => {
        const file = child.supporting_document_files_attributes.find(f => f.supporting_document_type_id === t.id);
        return file || { supporting_document_type_id: t.id };
      })
    } as Child);
  };

  /**
   * Delete a child
   */
  const handleDeleteChildSuccess = (c: Child, msg: string) => {
    onDeletedChild(c.user_id, c.id);
    onSuccess(msg);
  };

  /**
   * Handle save child success from the API
   */
  const handleSaveChildSuccess = (c: Child, msg: string) => {
    onUpdatedChild(c.user_id, c);
    if (msg) {
      onSuccess(msg);
    }
  };

  return (
    <div className="members-list">
      {members.map(member => (
        <MembersListItem key={member.id} member={member} onError={onError} onSuccess={onSuccess} onDeleteMember={onDeleteMember} onEditChild={editChild} onDeleteChild={handleDeleteChildSuccess} />
      ))}
      <ChildModal child={child} isOpen={isOpenChildModal} toggleModal={() => setIsOpenChildModal(false)} onSuccess={handleSaveChildSuccess} onError={onError} supportingDocumentsTypes={supportingDocumentsTypes} operator={operator} />
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

Application.Components.component('membersList', react2angular(MembersListWrapper, ['members', 'onError', 'onSuccess', 'operator', 'onDeleteMember', 'onDeletedChild', 'onUpdatedChild']));
