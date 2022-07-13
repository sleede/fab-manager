export enum StockType {
  internal = 'internal',
  external = 'external'
}

export interface Stock {
  internal: number,
  external: number,
}

export interface Product {
  id: number,
  name: string,
  slug: string,
  sku: string,
  description: string,
  is_active: boolean,
  product_category_id: number,
  amount: number,
  quantity_min: number,
  stock: Stock,
  low_stock_alert: boolean,
  low_stock_threshold: number,
}
