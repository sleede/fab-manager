import { Product } from '../../../app/frontend/src/javascript/models/product';
import movements from './product_stock_movements';

const products: Array<Product> = [
  {
    id: 1,
    name: 'MDF panel',
    slug: 'mdf-panel',
    sku: '3-8612',
    description: 'Medium Density Fiberboard (MDF) is a composite panel product typically consisting of cellulosic fibers combined with a synthetic resin',
    is_active: true,
    amount: 47.12,
    quantity_min: 1,
    stock: {
      internal: 10,
      external: 85
    },
    low_stock_alert: true,
    low_stock_threshold: 20,
    machine_ids: [],
    created_at: '2022-12-05T16:15:00Z',
    product_category_id: 1,
    product_files_attributes: [],
    product_images_attributes: [],
    product_stock_movements_attributes: movements.filter(m => m.product_id === 1)
  },
  {
    id: 2,
    name: 'Particleboard',
    slug: 'particleboard',
    sku: '3-7421',
    description: 'Particleboard is a composite panel product consisting of cellulosic particles of various sizes that are bonded together with a synthetic resin or binder under heat and pressure',
    is_active: false,
    stock: {
      internal: 2,
      external: 12
    },
    low_stock_alert: true,
    low_stock_threshold: 5,
    machine_ids: [],
    created_at: '2022-12-05T17:04:00Z',
    product_category_id: 1,
    product_files_attributes: [],
    product_images_attributes: [],
    product_stock_movements_attributes: movements.filter(m => m.product_id === 2)
  }
];

export default products;
