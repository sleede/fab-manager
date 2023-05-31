import { useState, useEffect } from 'react';
import * as React from 'react';
import { useTranslation } from 'react-i18next';
import { react2angular } from 'react2angular';
import _ from 'lodash';
import { HtmlTranslate } from '../base/html-translate';
import { Loader } from '../base/loader';
import { IApplication } from '../../models/application';
import { SupportingDocumentType } from '../../models/supporting-document-type';
import { Group } from '../../models/group';
import { SupportingDocumentsTypeModal } from './supporting-documents-type-modal';
import { DeleteSupportingDocumentsTypeModal } from './delete-supporting-documents-type-modal';
import GroupAPI from '../../api/group';
import SupportingDocumentTypeAPI from '../../api/supporting-document-type';
import { FabPanel } from '../base/fab-panel';
import { FabAlert } from '../base/fab-alert';
import { FabButton } from '../base/fab-button';
import { PencilSimple, Trash } from 'phosphor-react';

declare const Application: IApplication;

interface SupportingDocumentsTypesListProps {
  onSuccess: (message: string) => void,
  onError: (message: string) => void,
  documentType: 'User' | 'Child',
}

/**
 * This component shows a list of all types of supporting documents (e.g. student ID, Kbis extract, etc.)
 */
const SupportingDocumentsTypesList: React.FC<SupportingDocumentsTypesListProps> = ({ onSuccess, onError, documentType }) => {
  const { t } = useTranslation('admin');

  // list of displayed supporting documents type
  const [supportingDocumentsTypes, setSupportingDocumentsTypes] = useState<Array<SupportingDocumentType>>([]);
  // currently added/edited type
  const [supportingDocumentsType, setSupportingDocumentsType] = useState<SupportingDocumentType>(null);
  // list ordering
  const [supportingDocumentsTypeOrder, setSupportingDocumentsTypeOrder] = useState<string>(null);
  // creation/edition modal
  const [modalIsOpen, setModalIsOpen] = useState<boolean>(false);
  // all groups
  const [groups, setGroups] = useState<Array<Group>>([]);
  // deletion modal
  const [destroyModalIsOpen, setDestroyModalIsOpen] = useState<boolean>(false);
  // currently deleted type
  const [supportingDocumentsTypeId, setSupportingDocumentsTypeId] = useState<number>(null);

  // get groups
  useEffect(() => {
    GroupAPI.index({ disabled: false }).then(data => {
      setGroups(data);
      SupportingDocumentTypeAPI.index({ document_type: documentType }).then(pData => {
        setSupportingDocumentsTypes(pData);
      });
    });
  }, []);

  /**
   * Check if the current collection of supporting documents types is empty or not.
   */
  const hasTypes = (): boolean => {
    return supportingDocumentsTypes.length > 0;
  };

  /**
   * Init the process of creating a new supporting documents type
   */
  const addType = (): void => {
    setSupportingDocumentsType(null);
    setModalIsOpen(true);
  };

  /**
   * Init the process of editing the given type
   */
  const editType = (type: SupportingDocumentType): () => void => {
    return (): void => {
      setSupportingDocumentsType(type);
      setModalIsOpen(true);
    };
  };

  /**
   * Toggle the modal dialog to create/edit a type
   */
  const toggleCreateAndEditModal = (): void => {
    setModalIsOpen(!modalIsOpen);
  };

  /**
   * Callback triggred when the current type was successfully saved
   */
  const onSaveTypeSuccess = (message: string): void => {
    setModalIsOpen(false);
    SupportingDocumentTypeAPI.index({ document_type: documentType }).then(pData => {
      setSupportingDocumentsTypes(orderTypes(pData, supportingDocumentsTypeOrder));
      onSuccess(message);
    }).catch((error) => {
      onError('Unable to load proof of identity types' + error);
    });
  };

  /**
   * Init the process of deleting a supporting documents type (ask for confirmation)
   */
  const destroyType = (id: number): () => void => {
    return (): void => {
      setSupportingDocumentsTypeId(id);
      setDestroyModalIsOpen(true);
    };
  };

  /**
   * Open/closes the confirmation before deletion modal
   */
  const toggleDestroyModal = (): void => {
    setDestroyModalIsOpen(!destroyModalIsOpen);
  };

  /**
   * Callback triggred when the current type was successfully deleted
   */
  const onDestroySuccess = (message: string): void => {
    setDestroyModalIsOpen(false);
    SupportingDocumentTypeAPI.index({ document_type: documentType }).then(pData => {
      setSupportingDocumentsTypes(pData);
      setSupportingDocumentsTypes(orderTypes(pData, supportingDocumentsTypeOrder));
      onSuccess(message);
    }).catch((error) => {
      onError('Unable to load proof of identity types' + error);
    });
  };

  /**
   * Change the list ordering, according to the provided key
   */
  const setTypeOrder = (orderBy: string): () => void => {
    return () => {
      let order = orderBy;
      if (supportingDocumentsTypeOrder === orderBy) {
        order = `-${orderBy}`;
      }
      setSupportingDocumentsTypeOrder(order);
      setSupportingDocumentsTypes(orderTypes(supportingDocumentsTypes, order));
    };
  };

  /**
   * Sort the provided types according to the provided ordering key and return the resulting list
   */
  const orderTypes = (types: Array<SupportingDocumentType>, orderBy?: string): Array<SupportingDocumentType> => {
    if (!orderBy) {
      return types;
    }
    const order = orderBy[0] === '-' ? 'desc' : 'asc';
    if (orderBy.search('group_name') !== -1) {
      return _.orderBy(types, (type: SupportingDocumentType) => getGroupsNames(type.group_ids), order);
    } else {
      return _.orderBy(types, 'name', order);
    }
  };

  /**
   * Return the icon classes to use, according to the provided ordering key
   */
  const orderClassName = (orderBy: string): string => {
    if (supportingDocumentsTypeOrder) {
      const order = supportingDocumentsTypeOrder[0] === '-' ? supportingDocumentsTypeOrder.substr(1) : supportingDocumentsTypeOrder;
      if (order === orderBy) {
        return `fa fa-arrows-v ${supportingDocumentsTypeOrder[0] === '-' ? 'fa-sort-alpha-desc' : 'fa-sort-alpha-asc'}`;
      }
    }
    return 'fa fa-arrows-v';
  };

  /**
   * Return a comma separated list of the names of the provided groups
   */
  const getGroupsNames = (groupIds: Array<number>): string => {
    if (groupIds.length === groups.length && groupIds.length > 0) {
      return t('app.admin.settings.account.supporting_documents_types_list.all_groups');
    }
    const _groups = _.filter(groups, (g: Group) => { return groupIds.includes(g.id); });
    return _groups.map((g: Group) => g.name).join(', ');
  };

  /**
   * Redirect the user to the new group page
   */
  const addGroup = (): void => {
    window.location.href = '/#!/admin/members?tabs=1';
  };

  if (documentType === 'User') {
    return (
      <FabPanel className="supporting-documents-types-list" header={<div>
        <span>{t('app.admin.settings.account.supporting_documents_types_list.add_supporting_documents_types')}</span>
      </div>}>
        <div className="types-list">
          <div className="groups">
            <p>{t('app.admin.settings.account.supporting_documents_types_list.supporting_documents_type_info')}</p>
            <FabAlert level="warning">
              <HtmlTranslate trKey="app.admin.settings.account.supporting_documents_types_list.no_groups_info" />
              <FabButton onClick={addGroup}>{t('app.admin.settings.account.supporting_documents_types_list.create_groups')}</FabButton>
            </FabAlert>
          </div>

          <div className="title">
            <h3>{t('app.admin.settings.account.supporting_documents_types_list.supporting_documents_type_title')}</h3>
            <FabButton onClick={addType}>{t('app.admin.settings.account.supporting_documents_types_list.add_type')}</FabButton>
          </div>

          <SupportingDocumentsTypeModal isOpen={modalIsOpen}
                                        groups={groups}
                                        proofOfIdentityType={supportingDocumentsType}
                                        documentType={documentType}
                                        toggleModal={toggleCreateAndEditModal}
                                        onSuccess={onSaveTypeSuccess}
                                        onError={onError} />
          <DeleteSupportingDocumentsTypeModal isOpen={destroyModalIsOpen}
                                              proofOfIdentityTypeId={supportingDocumentsTypeId}
                                              toggleModal={toggleDestroyModal}
                                              onSuccess={onDestroySuccess}
                                              onError={onError}/>

          <table>
            <thead>
              <tr>
                <th className="group-name">
                  <a onClick={setTypeOrder('group_name')}>
                    {t('app.admin.settings.account.supporting_documents_types_list.group_name')}
                    <i className={orderClassName('group_name')} />
                  </a>
                </th>
                <th className="name">
                  <a onClick={setTypeOrder('name')}>
                    {t('app.admin.settings.account.supporting_documents_types_list.name')}
                    <i className={orderClassName('name')} />
                  </a>
                </th>
                <th className="actions"></th>
              </tr>
            </thead>
            <tbody>
              {supportingDocumentsTypes.map(poit => {
                return (
                  <tr key={poit.id}>
                    <td>{getGroupsNames(poit.group_ids)}</td>
                    <td>{poit.name}</td>
                    <td>
                      <div className="edit-destroy-buttons">
                        <FabButton className="edit-btn" onClick={editType(poit)}>
                          <PencilSimple size={20} weight="fill" />
                        </FabButton>
                        <FabButton className="delete-btn" onClick={destroyType(poit.id)}>
                          <Trash size={20} weight="fill" />
                        </FabButton>
                      </div>
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
          {!hasTypes() && (
            <p className="no-types-info">
              <HtmlTranslate trKey="app.admin.settings.account.supporting_documents_types_list.no_types" />
            </p>
          )}
        </div>
      </FabPanel>
    );
  } else if (documentType === 'Child') {
    return (
      <div className="supporting-documents-types-list">
        <div className="types-list">
          <div className="title">
            <h3>{t('app.admin.settings.account.supporting_documents_types_list.supporting_documents_type_title')}</h3>
            <FabButton onClick={addType}>{t('app.admin.settings.account.supporting_documents_types_list.add_type')}</FabButton>
          </div>

          <SupportingDocumentsTypeModal isOpen={modalIsOpen}
                                        groups={groups}
                                        proofOfIdentityType={supportingDocumentsType}
                                        documentType={documentType}
                                        toggleModal={toggleCreateAndEditModal}
                                        onSuccess={onSaveTypeSuccess}
                                        onError={onError} />
          <DeleteSupportingDocumentsTypeModal isOpen={destroyModalIsOpen}
                                              proofOfIdentityTypeId={supportingDocumentsTypeId}
                                              toggleModal={toggleDestroyModal}
                                              onSuccess={onDestroySuccess}
                                              onError={onError}/>

          <div className="document-list">
          {supportingDocumentsTypes.map(poit => {
            return (
              <div key={poit.id} className="document-list-item">
                <div className='file'>
                  <p>{poit.name}</p>
                  <div className="edit-destroy-buttons">
                    <FabButton className="edit-btn" onClick={editType(poit)}>
                      <PencilSimple size={20} weight="fill" />
                    </FabButton>
                    <FabButton className="delete-btn" onClick={destroyType(poit.id)}>
                      <Trash size={20} weight="fill" />
                    </FabButton>
                  </div>
                </div>
              </div>
            );
          })}
          </div>

          {!hasTypes() && (
            <p className="no-types-info">
              <HtmlTranslate trKey="app.admin.settings.account.supporting_documents_types_list.no_types" />
            </p>
          )}
        </div>
      </div>
    );
  } else {
    return null;
  }
};

const SupportingDocumentsTypesListWrapper: React.FC<SupportingDocumentsTypesListProps> = (props) => {
  return (
    <Loader>
      <SupportingDocumentsTypesList {...props} />
    </Loader>
  );
};

Application.Components.component('supportingDocumentsTypesList', react2angular(SupportingDocumentsTypesListWrapper, ['onSuccess', 'onError', 'documentType']));
