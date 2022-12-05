import { ProductStockMovement } from '../../../app/frontend/src/javascript/models/product';

const movements: Array<ProductStockMovement> = [
  {
    id: 1,
    product_id: 1,
    quantity: 10,
    reason: 'inward_stock',
    stock_type: 'internal',
    remaining_stock: 10,
    date: '2022-12-05T15:24:00Z'
  },
  {
    id: 2,
    product_id: 1,
    quantity: 85,
    reason: 'inward_stock',
    stock_type: 'external',
    remaining_stock: 85,
    date: '2022-12-05T15:24:00Z'
  },
  {
    id: 3,
    product_id: 2,
    quantity: 2,
    reason: 'inward_stock',
    stock_type: 'internal',
    remaining_stock: 2,
    date: '2022-12-05T15:24:00Z'
  },
  {
    id: 4,
    product_id: 2,
    quantity: 12,
    reason: 'inward_stock',
    stock_type: 'external',
    remaining_stock: 15,
    date: '2022-12-05T15:24:00Z'
  },
  {
    id: 5,
    product_id: 2,
    quantity: 3,
    reason: 'sold',
    stock_type: 'external',
    remaining_stock: 12,
    date: '2022-12-05T15:24:00Z'
  }
];

export default movements;
