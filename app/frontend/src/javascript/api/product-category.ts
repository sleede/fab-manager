import apiClient from './clients/api-client';
import { AxiosResponse } from 'axios';
import { ProductCategory } from '../models/product-category';

export default class ProductCategoryAPI {
  static async index (): Promise<Array<ProductCategory>> {
    const res: AxiosResponse<Array<ProductCategory>> = await apiClient.get('/api/product_categories');
    return res?.data;
  }

  static async get (id: number): Promise<ProductCategory> {
    const res: AxiosResponse<ProductCategory> = await apiClient.get(`/api/product_categories/${id}`);
    return res?.data;
  }

  static async create (productCategory: ProductCategory): Promise<ProductCategory> {
    const res: AxiosResponse<ProductCategory> = await apiClient.post('/api/product_categories', { product_category: productCategory });
    return res?.data;
  }

  static async update (productCategory: ProductCategory): Promise<ProductCategory> {
    const res: AxiosResponse<ProductCategory> = await apiClient.patch(`/api/product_categories/${productCategory.id}`, { product_category: productCategory });
    return res?.data;
  }

  static async destroy (productCategoryId: number): Promise<void> {
    const res: AxiosResponse<void> = await apiClient.delete(`/api/product_categories/${productCategoryId}`);
    return res?.data;
  }
}
