import apiClient from './clients/api-client';
import { AxiosResponse } from 'axios';
import { Product } from '../models/product';

export default class ProductAPI {
  static async index (): Promise<Array<Product>> {
    const res: AxiosResponse<Array<Product>> = await apiClient.get('/api/products');
    return res?.data;
  }

  static async get (id: number): Promise<Product> {
    const res: AxiosResponse<Product> = await apiClient.get(`/api/products/${id}`);
    return res?.data;
  }

  static async create (product: Product): Promise<Product> {
    const res: AxiosResponse<Product> = await apiClient.post('/api/products', { product });
    return res?.data;
  }

  static async update (product: Product): Promise<Product> {
    const res: AxiosResponse<Product> = await apiClient.patch(`/api/products/${product.id}`, { product });
    return res?.data;
  }

  static async destroy (productId: number): Promise<void> {
    const res: AxiosResponse<void> = await apiClient.delete(`/api/products/${productId}`);
    return res?.data;
  }
}
