import groups from '../__fixtures__/groups';
import plans from '../__fixtures__/plans';
import planCategories from '../__fixtures__/plan_categories';
import { partners, managers, users } from '../__fixtures__/users';
import { settings } from '../__fixtures__/settings';
import products from '../__fixtures__/products';
import productCategories from '../__fixtures__/product_categories';
import productStockMovements from '../__fixtures__/product_stock_movements';
import machines from '../__fixtures__/machines';
import providers from '../__fixtures__/auth_providers';
import profileCustomFields from '../__fixtures__/profile_custom_fields';
import spaces from '../__fixtures__/spaces';
import statuses from '../__fixtures__/statuses';
import notificationTypes from '../__fixtures__/notification_types';
import notifications from '../__fixtures__/notifications';

const FixturesLib = {
  init: () => {
    return {
      groups: JSON.parse(JSON.stringify(groups)),
      plans: JSON.parse(JSON.stringify(plans)),
      planCategories: JSON.parse(JSON.stringify(planCategories)),
      partners: JSON.parse(JSON.stringify(partners)),
      managers: JSON.parse(JSON.stringify(managers)),
      users: JSON.parse(JSON.stringify(users)),
      settings: JSON.parse(JSON.stringify(settings)),
      products: JSON.parse(JSON.stringify(products)),
      productCategories: JSON.parse(JSON.stringify(productCategories)),
      productStockMovements: JSON.parse(JSON.stringify(productStockMovements)),
      machines: JSON.parse(JSON.stringify(machines)),
      providers: JSON.parse(JSON.stringify(providers)),
      profileCustomFields: JSON.parse(JSON.stringify(profileCustomFields)),
      spaces: JSON.parse(JSON.stringify(spaces)),
      statuses: JSON.parse(JSON.stringify(statuses)),
      notificationTypes: JSON.parse(JSON.stringify(notificationTypes)),
      notifications: JSON.parse(JSON.stringify(notifications))
    };
  }
};

export default FixturesLib;
