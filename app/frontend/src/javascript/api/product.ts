import apiClient from './clients/api-client';
import { AxiosResponse } from 'axios';
import {
  Product,
  ProductIndexFilter,
  ProductsIndex,
  StockMovementIndex, StockMovementIndexFilter
} from '../models/product';
import ApiLib from '../lib/api';
import ProductLib from '../lib/product';

export default class ProductAPI {
  static async index (filters?: ProductIndexFilter): Promise<ProductsIndex> {
    const res: AxiosResponse<ProductsIndex> = await apiClient.get(`/api/products${ApiLib.filtersToQuery(ProductLib.indexFiltersToIds(filters), false)}`);
    return res?.data;
  }

  static async get (id: number | string): Promise<Product> {
    const res: AxiosResponse<Product> = await apiClient.get(`/api/products/${id}`);
    return res?.data;
  }

  static async create (product: Product): Promise<Product> {
    const data = ApiLib.serializeAttachments(product, 'product', ['product_files_attributes', 'product_images_attributes']);
    const res: AxiosResponse<Product> = await apiClient.post('/api/products', data, {
      headers: {
        'Content-Type': 'multipart/form-data'
      }
    });
    return res?.data;
  }

  static async update (product: Product): Promise<Product> {
    const data = ApiLib.serializeAttachments(product, 'product', ['product_files_attributes', 'product_images_attributes']);
    const res: AxiosResponse<Product> = await apiClient.patch(`/api/products/${product.id}`, data, {
      headers: {
        'Content-Type': 'multipart/form-data'
      }
    });
    return res?.data;
  }

  static async clone (product: Product, data: Product): Promise<Product> {
    const res: AxiosResponse<Product> = await apiClient.put(`/api/products/${product.id}/clone`, {
      product: data
    });
    return res?.data;
  }

  static async destroy (productId: number): Promise<void> {
    const res: AxiosResponse<void> = await apiClient.delete(`/api/products/${productId}`);
    return res?.data;
  }

  static async stockMovements (productId: number, filters: StockMovementIndexFilter): Promise<StockMovementIndex> {
    const res: AxiosResponse<StockMovementIndex> = await apiClient.get(`/api/products/${productId}/stock_movements${ApiLib.filtersToQuery(filters)}`);
    return res?.data;
  }
}
