import { Wallet } from '../models/wallet';

export default class WalletLib {
  private wallet: Wallet;

  constructor (wallet: Wallet) {
    this.wallet = wallet;
  }

  /**
   * Return the price remaining to pay, after we have used the maximum possible amount in the wallet
   */
  computeRemainingPrice = (price: number): number => {
    if (this.wallet.amount > price) {
      return 0;
    } else {
      return price - this.wallet.amount;
    }
  }
}
