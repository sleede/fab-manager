import React, { useEffect, useState } from 'react';
import { IApplication } from '../../models/application';
import { Loader } from '../base/loader';
import { react2angular } from 'react2angular';
import { Slot } from '../../models/slot';
import { ReservableType } from '../../models/reservation';
import { User } from '../../models/user';
import { MemberSelect } from '../user/member-select';
import CartAPI from '../../api/cart';
import useCart from '../../hooks/use-cart';
import { ReservationsSummary } from './reservations-summary';
import UserLib from '../../lib/user';

declare const Application: IApplication;

interface OngoingReservationPanelProps {
  selectedSlot: Slot,
  reservableId: number,
  reservableType: ReservableType,
  onError: (message: string) => void,
  operator: User,
  onSlotAdded: (slot: Slot) => void,
  onSlotRemoved: (slot: Slot) => void,
}

/**
 * Panel to manage the ongoing reservation (select the member, show the price, etc)
 */
export const OngoingReservationPanel: React.FC<OngoingReservationPanelProps> = ({ selectedSlot, reservableId, reservableType, onError, operator, onSlotAdded, onSlotRemoved }) => {
  const { cart, setCart } = useCart(operator);

  const [noMemberError, setNoMemberError] = useState<boolean>(false);

  useEffect(() => {
    if (selectedSlot && !cart.user) {
      setNoMemberError(true);
      onError('please select a member first');
    }
  }, [selectedSlot]);

  /**
   * The admin/manager can change the cart's customer
   */
  const handleChangeMember = (user: User): void => {
    CartAPI.setCustomer(cart, user.id).then(setCart).catch(onError);
  };

  return (
    <div className="ongoing-reservation-panel">
      {new UserLib(operator).hasPrivilegedRole() &&
        <MemberSelect onSelected={handleChangeMember}
                      defaultUser={cart?.user as User}
                      hasError={noMemberError} />
      }
      <ReservationsSummary reservableId={reservableId}
                           reservableType={reservableType}
                           onError={onError}
                           cart={cart}
                           setCart={setCart}
                           customer={cart?.user as User}
                           onSlotAdded={onSlotAdded}
                           onSlotRemoved={onSlotRemoved}
                           slot={selectedSlot} />
    </div>
  );
};

const OngoingReservationPanelWrapper: React.FC<OngoingReservationPanelProps> = (props) => (
  <Loader>
    <OngoingReservationPanel {...props} />
  </Loader>
);

Application.Components.component('ongoingReservationPanel', react2angular(OngoingReservationPanelWrapper, ['selectedSlot', 'reservableId', 'reservableType', 'onError', 'operator', 'onSlotRemoved', 'onSlotAdded']));
