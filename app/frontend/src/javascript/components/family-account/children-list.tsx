import React, { useState, useEffect } from 'react';
import { react2angular } from 'react2angular';
import { Child } from '../../models/child';
// import { ChildListItem } from './child-list-item';
import ChildAPI from '../../api/child';
import { User } from '../../models/user';
import { useTranslation } from 'react-i18next';
import { Loader } from '../base/loader';
import { IApplication } from '../../models/application';
import { ChildModal } from './child-modal';
import { ChildItem } from './child-item';
import { FabButton } from '../base/fab-button';

declare const Application: IApplication;

interface ChildrenListProps {
  currentUser: User;
}

/**
 * A list of children belonging to the current user.
 */
export const ChildrenList: React.FC<ChildrenListProps> = ({ currentUser }) => {
  const { t } = useTranslation('public');

  const [children, setChildren] = useState<Array<Child>>([]);
  const [isOpenChildModal, setIsOpenChildModal] = useState<boolean>(false);
  const [child, setChild] = useState<Child>();

  useEffect(() => {
    ChildAPI.index({ user_id: currentUser.id }).then(setChildren);
  }, [currentUser]);

  /**
   * Open the add child modal
   */
  const addChild = () => {
    setIsOpenChildModal(true);
    setChild({ user_id: currentUser.id } as Child);
  };

  /**
   * Open the edit child modal
   */
  const editChild = (child: Child) => {
    setIsOpenChildModal(true);
    setChild(child);
  };

  /**
   * Delete a child
   */
  const deleteChild = (child: Child) => {
    ChildAPI.destroy(child.id).then(() => {
      setChildren(children.filter(c => c.id !== child.id));
    });
  };

  return (
    <section>
      <header>
        <h2>{t('app.public.children_list.heading')}</h2>
        <FabButton onClick={addChild}>
          {t('app.public.children_list.add_child')}
        </FabButton>
      </header>

      <div>
        {children.map(child => (
          <ChildItem key={child.id} child={child} onEdit={editChild} onDelete={deleteChild} />
        ))}
      </div>
      <ChildModal child={child} isOpen={isOpenChildModal} toggleModal={() => setIsOpenChildModal(false)} />
    </section>
  );
};

const ChildrenListWrapper: React.FC<ChildrenListProps> = (props) => {
  return (
    <Loader>
      <ChildrenList {...props} />
    </Loader>
  );
};

Application.Components.component('childrenList', react2angular(ChildrenListWrapper, ['currentUser']));
