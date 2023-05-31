import React, { useState, useEffect } from 'react';
import { react2angular } from 'react2angular';
import { Child } from '../../models/child';
import ChildAPI from '../../api/child';
import { User } from '../../models/user';
import { useTranslation } from 'react-i18next';
import { Loader } from '../base/loader';
import { IApplication } from '../../models/application';
import { ChildModal } from './child-modal';
import { ChildItem } from './child-item';
import { FabButton } from '../base/fab-button';
import { SupportingDocumentType } from '../../models/supporting-document-type';
import SupportingDocumentTypeAPI from '../../api/supporting-document-type';

declare const Application: IApplication;

interface ChildrenDashboardProps {
  user: User;
  operator: User;
  adminPanel?: boolean;
  onSuccess: (error: string) => void;
  onError: (error: string) => void;
}

/**
 * A list of children belonging to the current user.
 */
export const ChildrenDashboard: React.FC<ChildrenDashboardProps> = ({ user, operator, adminPanel, onError, onSuccess }) => {
  const { t } = useTranslation('public');

  const [children, setChildren] = useState<Array<Child>>([]);
  const [isOpenChildModal, setIsOpenChildModal] = useState<boolean>(false);
  const [child, setChild] = useState<Child>();
  const [supportingDocumentsTypes, setSupportingDocumentsTypes] = useState<Array<SupportingDocumentType>>([]);

  useEffect(() => {
    ChildAPI.index({ user_id: user.id }).then(setChildren);
    SupportingDocumentTypeAPI.index({ document_type: 'Child' }).then(tData => {
      setSupportingDocumentsTypes(tData);
    });
  }, [user]);

  /**
   * Open the add child modal
   */
  const addChild = () => {
    setIsOpenChildModal(true);
    setChild({
      user_id: user.id,
      supporting_document_files_attributes: supportingDocumentsTypes.map(t => {
        return { supporting_document_type_id: t.id };
      })
    } as Child);
  };

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
  const handleDeleteChildSuccess = (msg: string) => {
    ChildAPI.index({ user_id: user.id }).then(setChildren);
    onSuccess(msg);
  };

  /**
   * Handle save child success from the API
   */
  const handleSaveChildSuccess = (msg: string) => {
    ChildAPI.index({ user_id: user.id }).then(setChildren);
    if (msg) {
      onSuccess(msg);
    }
  };

  /**
   * Check if the current operator has administrative rights or is a normal member
   */
  const isPrivileged = (): boolean => {
    return (operator?.role === 'admin' || operator?.role === 'manager');
  };

  return (
    <section className='children-dashboard'>
      <header>
        {adminPanel
          ? <h2>{t('app.public.children_dashboard.heading')}</h2>
          : <h2>{t('app.public.children_dashboard.member_heading')}</h2>
        }
        {!isPrivileged() && (
          <div className="grpBtn">
            <FabButton className="main-action-btn" onClick={addChild}>
              {t('app.public.children_dashboard.add_child')}
            </FabButton>
          </div>
        )}
      </header>

      <div className="children-list">
        {children.map(child => (
          <ChildItem key={child.id} child={child} size='lg' onEdit={editChild} onDelete={handleDeleteChildSuccess} onError={onError} />
        ))}
      </div>
      <ChildModal child={child} isOpen={isOpenChildModal} toggleModal={() => setIsOpenChildModal(false)} onSuccess={handleSaveChildSuccess} onError={onError} supportingDocumentsTypes={supportingDocumentsTypes} operator={operator} />
    </section>
  );
};

const ChildrenDashboardWrapper: React.FC<ChildrenDashboardProps> = (props) => {
  return (
    <Loader>
      <ChildrenDashboard {...props} />
    </Loader>
  );
};

Application.Components.component('childrenDashboard', react2angular(ChildrenDashboardWrapper, ['user', 'operator', 'adminPanel', 'onSuccess', 'onError']));
