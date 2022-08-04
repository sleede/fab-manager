import apiClient from './clients/api-client';
import { AxiosResponse } from 'axios';
import { serialize } from 'object-to-formdata';
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
    const data = serialize({
      product: {
        ...product,
        product_files_attributes: null,
        product_images_attributes: null
      }
    });
    data.delete('product[product_files_attributes]');
    data.delete('product[product_images_attributes]');
    product.product_files_attributes?.forEach((file, i) => {
      if (file?.attachment_files && file?.attachment_files[0]) {
        data.set(`product[product_files_attributes][${i}][attachment]`, file.attachment_files[0]);
      }
    });
    product.product_images_attributes?.forEach((image, i) => {
      if (image?.attachment_files && image?.attachment_files[0]) {
        data.set(`product[product_images_attributes][${i}][attachment]`, image.attachment_files[0]);
        data.set(`product[product_images_attributes][${i}][is_main]`, (!!image.is_main).toString());
      }
    });
    const res: AxiosResponse<Product> = await apiClient.post('/api/products', data, {
      headers: {
        'Content-Type': 'multipart/form-data'
      }
    });
    return res?.data;
  }

  static async update (product: Product): Promise<Product> {
    const data = serialize({
      product: {
        ...product,
        product_files_attributes: null,
        product_images_attributes: null
      }
    });
    data.delete('product[product_files_attributes]');
    data.delete('product[product_images_attributes]');
    product.product_files_attributes?.forEach((file, i) => {
      if (file?.attachment_files && file?.attachment_files[0]) {
        data.set(`product[product_files_attributes][${i}][attachment]`, file.attachment_files[0]);
      }
      if (file?.id) {
        data.set(`product[product_files_attributes][${i}][id]`, file.id.toString());
      }
      if (file?._destroy) {
        data.set(`product[product_files_attributes][${i}][_destroy]`, file._destroy.toString());
      }
    });
    product.product_images_attributes?.forEach((image, i) => {
      if (image?.attachment_files && image?.attachment_files[0]) {
        data.set(`product[product_images_attributes][${i}][attachment]`, image.attachment_files[0]);
      }
      if (image?.id) {
        data.set(`product[product_images_attributes][${i}][id]`, image.id.toString());
      }
      if (image?._destroy) {
        data.set(`product[product_images_attributes][${i}][_destroy]`, image._destroy.toString());
      }
      data.set(`product[product_images_attributes][${i}][is_main]`, (!!image.is_main).toString());
    });
    const res: AxiosResponse<Product> = await apiClient.patch(`/api/products/${product.id}`, data, {
      headers: {
        'Content-Type': 'multipart/form-data'
      }
    });
    return res?.data;
  }

  static async destroy (productId: number): Promise<void> {
    const res: AxiosResponse<void> = await apiClient.delete(`/api/products/${productId}`);
    return res?.data;
  }
}
