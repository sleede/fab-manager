import React, { useState, useEffect } from 'react';
import { useTranslation } from 'react-i18next';
import { react2angular } from 'react2angular';
import _ from 'lodash';
import { HtmlTranslate } from '../base/html-translate';
import { Loader } from '../base/loader';
import { IApplication } from '../../models/application';
import { ProofOfIdentityType } from '../../models/proof-of-identity-type';
import { Group } from '../../models/group';
import { ProofOfIdentityTypeModal } from './proof-of-identity-type-modal';
import { DeleteProofOfIdentityTypeModal } from './delete-proof-of-identity-type-modal';
import GroupAPI from '../../api/group';
import ProofOfIdentityTypeAPI from '../../api/proof-of-identity-type';

declare const Application: IApplication;

interface ProofOfIdentityTypesListProps {
  onSuccess: (message: string) => void,
  onError: (message: string) => void,
}

/**
 * This component shows a list of all payment schedules with their associated deadlines (aka. PaymentScheduleItem) and invoices
 */
const ProofOfIdentityTypesList: React.FC<ProofOfIdentityTypesListProps> = ({ onSuccess, onError }) => {
  const { t } = useTranslation('admin');

  // list of displayed proof of identity type
  const [proofOfIdentityTypes, setProofOfIdentityTypes] = useState<Array<ProofOfIdentityType>>([]);
  const [proofOfIdentityType, setProofOfIdentityType] = useState<ProofOfIdentityType>(null);
  const [proofOfIdentityTypeOrder, setProofOfIdentityTypeOrder] = useState<string>(null);
  const [modalIsOpen, setModalIsOpen] = useState<boolean>(false);
  const [groups, setGroups] = useState<Array<Group>>([]);
  const [destroyModalIsOpen, setDestroyModalIsOpen] = useState<boolean>(false);
  const [proofOfIdentityTypeId, setProofOfIdentityTypeId] = useState<number>(null);

  // get groups
  useEffect(() => {
    GroupAPI.index({ disabled: false, admins: false }).then(data => {
      setGroups(data);
      ProofOfIdentityTypeAPI.index().then(pData => {
        setProofOfIdentityTypes(pData);
      });
    });
  }, []);

  /**
   * Check if the current collection of proof of identity types is empty or not.
   */
  const hasProofOfIdentityTypes = (): boolean => {
    return proofOfIdentityTypes.length > 0;
  };

  const addProofOfIdentityType = (): void => {
    setProofOfIdentityType(null);
    setModalIsOpen(true);
  };

  const editProofOfIdentityType = (poit: ProofOfIdentityType): () => void => {
    return (): void => {
      setProofOfIdentityType(poit);
      setModalIsOpen(true);
    };
  };

  const toggleCreateAndEditModal = (): void => {
    setModalIsOpen(false);
  };

  const saveProofOfIdentityTypeOnSuccess = (message: string): void => {
    setModalIsOpen(false);
    ProofOfIdentityTypeAPI.index().then(pData => {
      setProofOfIdentityTypes(orderProofOfIdentityTypes(pData, proofOfIdentityTypeOrder));
      onSuccess(message);
    }).catch((error) => {
      onError('Unable to load proof of identity types' + error);
    });
  };

  const destroyProofOfIdentityType = (id: number): () => void => {
    return (): void => {
      setProofOfIdentityTypeId(id);
      setDestroyModalIsOpen(true);
    };
  };

  const toggleDestroyModal = (): void => {
    setDestroyModalIsOpen(false);
  };

  const destroyProofOfIdentityTypeOnSuccess = (message: string): void => {
    setDestroyModalIsOpen(false);
    ProofOfIdentityTypeAPI.index().then(pData => {
      setProofOfIdentityTypes(pData);
      setProofOfIdentityTypes(orderProofOfIdentityTypes(pData, proofOfIdentityTypeOrder));
      onSuccess(message);
    }).catch((error) => {
      onError('Unable to load proof of identity types' + error);
    });
  };

  const setOrderProofOfIdentityType = (orderBy: string): () => void => {
    return () => {
      let order = orderBy;
      if (proofOfIdentityTypeOrder === orderBy) {
        order = `-${orderBy}`;
      }
      setProofOfIdentityTypeOrder(order);
      setProofOfIdentityTypes(orderProofOfIdentityTypes(proofOfIdentityTypes, order));
    };
  };

  const orderProofOfIdentityTypes = (poits: Array<ProofOfIdentityType>, orderBy?: string): Array<ProofOfIdentityType> => {
    if (!orderBy) {
      return poits;
    }
    const order = orderBy[0] === '-' ? 'desc' : 'asc';
    if (orderBy.search('group_name') !== -1) {
      return _.orderBy(poits, (poit: ProofOfIdentityType) => getGroupName(poit.group_ids), order);
    } else {
      return _.orderBy(poits, 'name', order);
    }
  };

  const orderClassName = (orderBy: string): string => {
    if (proofOfIdentityTypeOrder) {
      const order = proofOfIdentityTypeOrder[0] === '-' ? proofOfIdentityTypeOrder.substr(1) : proofOfIdentityTypeOrder;
      if (order === orderBy) {
        return `fa fa-arrows-v ${proofOfIdentityTypeOrder[0] === '-' ? 'fa-sort-alpha-desc' : 'fa-sort-alpha-asc'}`;
      }
    }
    return 'fa fa-arrows-v';
  };

  const getGroupName = (groupIds: Array<number>): string => {
    if (groupIds.length === groups.length && groupIds.length > 0) {
      return t('app.admin.settings.account.all_groups');
    }
    const _groups = _.filter(groups, (g: Group) => { return groupIds.includes(g.id); });
    return _groups.map((g: Group) => g.name).join(', ');
  };

  return (
    <div className="panel panel-default m-t-md">
      <div className="panel-heading">
        <span className="font-sbold">{t('app.admin.settings.account.add_proof_of_identity_types')}</span>
      </div>
      <div className="panel-body">
        <div className="row">
          <p className="m-h">{t('app.admin.settings.account.proof_of_identity_type_info')}</p>
          <div className="alert alert-warning m-h-md row">
            <div className="col-md-8">
              <HtmlTranslate trKey="app.admin.settings.account.proof_of_identity_type_no_group_info" />
            </div>
            <a href="/#!/admin/members?tabs=1" className="btn btn-warning pull-right m-t m-r-md col-md-3" style={{ color: '#000', maxWidth: '200px' }}>{t('app.admin.settings.account.create_groups')}</a>
          </div>
        </div>

        <div className="row">
          <h3 className="m-l inline">{t('app.admin.settings.account.proof_of_identity_type_title')}</h3>
          <button name="button" className="btn btn-warning pull-right m-t m-r-md" onClick={addProofOfIdentityType}>{t('app.admin.settings.account.add_proof_of_identity_type_button')}</button>
        </div>

        <ProofOfIdentityTypeModal isOpen={modalIsOpen} groups={groups} proofOfIdentityType={proofOfIdentityType} toggleModal={toggleCreateAndEditModal} onSuccess={saveProofOfIdentityTypeOnSuccess} onError={onError} />
        <DeleteProofOfIdentityTypeModal isOpen={destroyModalIsOpen} proofOfIdentityTypeId={proofOfIdentityTypeId} toggleModal={toggleDestroyModal} onSuccess={destroyProofOfIdentityTypeOnSuccess} onError={onError}/>

        <table className="table proof-of-identity-type-list">
          <thead>
            <tr>
              <th style={{ width: '40%' }}><a onClick={setOrderProofOfIdentityType('group_name')}>{t('app.admin.settings.account.proof_of_identity_type.group_name')} <i className={orderClassName('group_name')}></i></a></th>
              <th style={{ width: '40%' }}><a onClick={setOrderProofOfIdentityType('name')}>{t('app.admin.settings.account.proof_of_identity_type.name')} <i className={orderClassName('name')}></i></a></th>
              <th style={{ width: '20%' }} className="buttons-col"></th>
            </tr>
          </thead>
          <tbody>
            {proofOfIdentityTypes.map(poit => {
              return (
                <tr key={poit.id}>
                  <td>{getGroupName(poit.group_ids)}</td>
                  <td>{poit.name}</td>
                  <td>
                    <div className="buttons">
                      <button className="btn btn-default edit-proof-of-identity-type m-r-xs" onClick={editProofOfIdentityType(poit)}>
                        <i className="fa fa-edit"></i>
                      </button>
                      <button className="btn btn-danger delete-proof-of-identity-type" onClick={destroyProofOfIdentityType(poit.id)}>
                        <i className="fa fa-trash"></i>
                      </button>
                    </div>
                  </td>
                </tr>
              );
            })}
          </tbody>
        </table>
        {!hasProofOfIdentityTypes() && (
          <p className="text-center">
            <HtmlTranslate trKey="app.admin.settings.account.no_proof_of_identity_types" />
          </p>
        )}
      </div>
    </div>
  );
};

const ProofOfIdentityTypesListWrapper: React.FC<ProofOfIdentityTypesListProps> = ({ onSuccess, onError }) => {
  return (
    <Loader>
      <ProofOfIdentityTypesList onSuccess={onSuccess} onError={onError} />
    </Loader>
  );
};

Application.Components.component('proofOfIdentityTypesList', react2angular(ProofOfIdentityTypesListWrapper, ['onSuccess', 'onError']));
