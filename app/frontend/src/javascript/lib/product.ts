import { ProductCategory } from '../models/product-category';
import { stockMovementInReasons, stockMovementOutReasons, StockMovementReason } from '../models/product';

export default class ProductLib {
  /**
   * Map product categories by position
   * @param categories unsorted categories, as returned by the API
   */
  static sortCategories = (categories: Array<ProductCategory>): Array<ProductCategory> => {
    const sortedCategories = categories
      .filter(c => !c.parent_id)
      .sort((a, b) => a.position - b.position);
    const childrenCategories = categories
      .filter(c => typeof c.parent_id === 'number')
      .sort((a, b) => b.position - a.position);
    childrenCategories.forEach(c => {
      const parentIndex = sortedCategories.findIndex(i => i.id === c.parent_id);
      sortedCategories.splice(parentIndex + 1, 0, c);
    });
    return sortedCategories;
  };

  /**
   * Return the translation key associated with the given reason
   */
  static stockMovementReasonTrKey = (reason: StockMovementReason): string => {
    return `app.admin.store.stock_movement_reason.${reason}`;
  };

  /**
   * Check if the given stock movement is of type 'in' or 'out'
   */
  static stockMovementType = (reason: StockMovementReason): 'in' | 'out' => {
    if ((stockMovementInReasons as readonly StockMovementReason[]).includes(reason)) return 'in';
    if ((stockMovementOutReasons as readonly StockMovementReason[]).includes(reason)) return 'out';

    throw new Error(`Unexpected stock movement reason: ${reason}`);
  };

  /**
   * Return the given quantity, prefixed by its addition operator (- or +)
   */
  static absoluteStockMovement = (quantity: number, reason: StockMovementReason): string => {
    if (ProductLib.stockMovementType(reason) === 'in') {
      return `+${quantity}`;
    } else {
      return `-${quantity}`;
    }
  };
}
