import { computePriceWithCoupon } from './coupon';
import { Order } from '../models/order';

export default class OrderLib {
  /**
   * Get the order item total
   */
  static itemAmount = (item): number => {
    return item.quantity * Math.trunc(item.amount * 100) / 100;
  };

  /**
   * return true if order has offered item
   */
  static hasOfferedItem = (order: Order): boolean => {
    return order.order_items_attributes
      .filter(i => i.is_offered).length > 0;
  };

  /**
   * Get the offered item total
   */
  static offeredAmount = (order: Order): number => {
    return order.order_items_attributes
      .filter(i => i.is_offered)
      .map(i => Math.trunc(i.amount * 100) * i.quantity)
      .reduce((acc, curr) => acc + curr, 0) / 100;
  };

  /**
   * Get the total amount before offered amount
   */
  static totalBeforeOfferedAmount = (order: Order): number => {
    return (Math.trunc(order.total * 100) + Math.trunc(this.offeredAmount(order) * 100)) / 100;
  };

  /**
   * Get the coupon amount
   */
  static couponAmount = (order: Order): number => {
    return (Math.trunc(order.total * 100) - Math.trunc(computePriceWithCoupon(order.total, order.coupon) * 100)) / 100.00;
  };

  /**
   * Get the paid total amount
   */
  static paidTotal = (order: Order): number => {
    return computePriceWithCoupon(order.total, order.coupon);
  };

  /**
   * Returns a className according to the status
   */
  static statusColor = (order: Order) => {
    switch (order.state) {
      case 'cart':
        return 'cart';
      case 'payment_failed':
        return 'error';
      case 'canceled':
        return 'canceled';
      case 'in_progress':
        return 'pending';
      default:
        return 'normal';
    }
  };

  /**
   * Returns a status text according to the status
   */
  static statusText = (order: Order) => {
    return order.state;
  };
}
