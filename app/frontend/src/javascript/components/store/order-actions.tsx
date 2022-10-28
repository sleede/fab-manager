import React, { useState } from 'react';
import { useTranslation } from 'react-i18next';
import Select from 'react-select';
import { FabModal } from '../base/fab-modal';
import OrderAPI from '../../api/order';
import { Order } from '../../models/order';
import FabTextEditor from '../base/text-editor/fab-text-editor';
import { HtmlTranslate } from '../base/html-translate';
import { SelectOption } from '../../models/select';

interface OrderActionsProps {
  order: Order,
  onSuccess: (order: Order, message: string) => void,
  onError: (message: string) => void,
}

/**
 * Actions for an order
 */
export const OrderActions: React.FC<OrderActionsProps> = ({ order, onSuccess, onError }) => {
  const { t } = useTranslation('shared');
  const [currentAction, setCurrentAction] = useState<SelectOption<string>>();
  const [modalIsOpen, setModalIsOpen] = useState<boolean>(false);
  const [readyNote, setReadyNote] = useState<string>('');

  // Styles the React-select component
  const customStyles = {
    control: base => ({
      ...base,
      width: '20ch',
      backgroundColor: 'transparent'
    }),
    indicatorSeparator: () => ({
      display: 'none'
    })
  };

  /**
   * Close the action confirmation modal
   */
  const closeModal = (): void => {
    setModalIsOpen(false);
    setCurrentAction(null);
  };

  /**
   * Creates sorting options to the react-select format
   */
  const buildOptions = (): Array<SelectOption<string>> => {
    let actions = [];
    switch (order.state) {
      case 'paid':
        actions = actions.concat(['in_progress', 'ready', 'delivered', 'canceled', 'refunded']);
        break;
      case 'payment_failed':
        actions = actions.concat(['canceled']);
        break;
      case 'in_progress':
        actions = actions.concat(['ready', 'delivered', 'canceled', 'refunded']);
        break;
      case 'ready':
        actions = actions.concat(['delivered', 'canceled', 'refunded']);
        break;
      case 'canceled':
        actions = actions.concat(['refunded']);
        break;
      default:
        actions = [];
    }
    return actions.map(action => {
      return { value: action, label: t(`app.shared.store.order_actions.state.${action}`) };
    });
  };

  /**
   * Callback after selecting an action
   */
  const handleAction = (action: SelectOption<string>) => {
    setCurrentAction(action);
    setModalIsOpen(true);
  };

  /**
   * Callback after confirm an action
   */
  const handleActionConfirmation = () => {
    OrderAPI.updateState(order, currentAction.value, readyNote).then(data => {
      onSuccess(data, t(`app.shared.store.order_actions.order_${currentAction.value}_success`));
      setCurrentAction(null);
      setModalIsOpen(false);
    }).catch((e) => {
      onError(e);
      setCurrentAction(null);
      setModalIsOpen(false);
    });
  };

  return (
    <>
      {buildOptions().length > 0 &&
        <Select
          options={buildOptions()}
          onChange={option => handleAction(option)}
          value={currentAction}
          styles={customStyles}
        />
      }
      <FabModal title={t('app.shared.store.order_actions.confirmation_required')}
        isOpen={modalIsOpen}
        toggleModal={closeModal}
        closeButton={true}
        confirmButton={t('app.shared.store.order_actions.confirm')}
        onConfirm={handleActionConfirmation}
        className="order-actions-confirmation-modal">
        <HtmlTranslate trKey={`app.shared.store.order_actions.confirm_order_${currentAction?.value}_html`} />
        {currentAction?.value === 'ready' &&
          <FabTextEditor
            content={readyNote}
            placeholder={t('app.shared.store.order_actions.order_ready_note')}
            onChange={setReadyNote} />
        }
      </FabModal>
    </>
  );
};
