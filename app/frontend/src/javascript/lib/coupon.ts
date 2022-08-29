import { Coupon } from '../models/coupon';

export const computePriceWithCoupon = (price: number, coupon?: Coupon): number => {
  if (!coupon) {
    return price;
  }
  if (coupon.type === 'percent_off') {
    return price - (price * coupon.percent_off / 100.00);
  } else if (coupon.type === 'amount_off' && price > coupon.amount_off) {
    return price - coupon.amount_off;
  }
  return price;
};
