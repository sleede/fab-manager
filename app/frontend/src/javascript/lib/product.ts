import { ProductCategory } from '../models/product-category';
import {
  ProductIndexFilter,
  ProductIndexFilterIds, ProductIndexFilterUrl,
  stockMovementInReasons,
  stockMovementOutReasons,
  StockMovementReason
} from '../models/product';

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
   * Return the given quantity, prefixed by its addition operator (- or +), if needed
   */
  static absoluteStockMovement = (quantity: number, reason: StockMovementReason): string => {
    if (ProductLib.stockMovementType(reason) === 'in') {
      return `+${quantity}`;
    } else {
      if (quantity < 0) return quantity.toString();
      return `-${quantity}`;
    }
  };

  /**
   * Add or remove the given category from the given list;
   * This may cause parent/children categories to be selected or unselected accordingly.
   */
  static categoriesSelectionTree = (allCategories: Array<ProductCategory>, currentSelection: Array<ProductCategory>, category: ProductCategory, operation: 'add'|'remove'): Array<ProductCategory> => {
    let list = [...currentSelection];
    const children = allCategories
      .filter(el => el.parent_id === category.id);
    const siblings = allCategories
      .filter(el => el.parent_id === category.parent_id && el.parent_id !== null);

    if (operation === 'add') {
      list.push(category);
      if (children.length) {
        // if a parent category is selected, we automatically select all its children
        list = [...Array.from(new Set([...list, ...children]))];
      }
      if (siblings.length && siblings.every(el => list.includes(el))) {
        // if a child category is selected, with every sibling of it, we automatically select its parent
        list.push(allCategories.find(p => p.id === siblings[0].parent_id));
      }
    } else {
      list.splice(list.indexOf(category), 1);
      const parent = allCategories.find(p => p.id === category.parent_id);
      if (category.parent_id && list.includes(parent)) {
        // if a child category is unselected, we unselect its parent
        list.splice(list.indexOf(parent), 1);
      }
      if (children.length) {
        // if a parent category is unselected, we unselect all its children
        children.forEach(child => {
          list.splice(list.indexOf(child), 1);
        });
      }
    }
    return list;
  };

  /**
   * Extract the IDS from the filters to pass them to the API
   */
  static indexFiltersToIds = (filters: ProductIndexFilter): ProductIndexFilterIds => {
    return {
      ...filters,
      categories: filters.categories?.map(c => c.id),
      machines: filters.machines?.map(m => m.id)
    };
  };

  /**
   * Prepare the filtering data from the filters to pass them to the router URL
   */
  static indexFiltersToRouterParams = (filters: ProductIndexFilter): ProductIndexFilterUrl => {
    let categoryTypeUrl = null;
    let category = null;
    if (filters.categories.length > 0) {
      categoryTypeUrl = filters.categories[0].parent_id === null ? 'c' : 'sc';
      category = filters.categories.map(c => c.slug)[0];
    }
    return {
      ...filters,
      machines: filters.machines?.map(m => m.slug),
      category,
      categoryTypeUrl
    };
  };

  /**
   * Parse the provided URL and return a ready-to-use filter object
   * FIXME
   */
  static readFiltersFromUrl = (url: string): ProductIndexFilterIds => {
    const res: ProductIndexFilterIds = {};
    for (const [key, value] of new URLSearchParams(url.split('?')[1])) {
      let parsedValue: string|number|boolean = value;
      if (['true', 'false'].includes(value)) {
        parsedValue = (value === 'true');
      } else if (parseInt(value, 10).toString() === value) {
        parsedValue = parseInt(value, 10);
      }
      if (res[key] === undefined) {
        res[key] = parsedValue;
      } else if (Array.isArray(res[key])) {
        res[key] = [...res[key] as Array<unknown>, parsedValue];
      } else {
        res[key] = [res[key], parsedValue];
      }
    }
    return res;
  };
}
