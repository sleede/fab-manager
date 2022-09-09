import { TDateISO } from '../typings/date-iso';
import { ApiFilter } from './api';

export interface ProductIndexFilter extends ApiFilter {
  is_active?: boolean,
  page?: number
}

export enum StockType {
  internal = 'internal',
  external = 'external'
}

export interface Stock {
  internal: number,
  external: number,
}

export interface ProductsIndex {
  total_pages?: number,
  products: Array<Product>
}

export interface Product {
  id?: number,
  name: string,
  slug: string,
  sku?: string,
  description?: string,
  is_active: boolean,
  product_category_id?: number,
  amount?: number,
  quantity_min?: number,
  stock: Stock,
  low_stock_alert: boolean,
  low_stock_threshold?: number,
  machine_ids: number[],
  product_files_attributes: Array<{
    id?: number,
    attachment?: File,
    attachment_files?: FileList,
    attachment_name?: string,
    attachment_url?: string,
    _destroy?: boolean
  }>,
  product_images_attributes: Array<{
    id?: number,
    attachment?: File,
    attachment_files?: FileList,
    attachment_name?: string,
    attachment_url?: string,
    _destroy?: boolean,
    is_main?: boolean
  }>,
  product_stock_movements_attributes: Array<{
    id?: number,
    quantity?: number,
    reason?: string,
    stock_type?: string,
    remaining_stock?: number,
    date?: TDateISO,
    _destroy?: boolean
  }>,
}
