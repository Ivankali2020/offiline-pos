const String createSellerTable = '''
CREATE TABLE sellers (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  phone TEXT,
  email TEXT,
  address TEXT,
  created_at TEXT,
  updated_at TEXT
);
''';

const String createRegionTable = '''
CREATE TABLE regions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  created_at TEXT,
  updated_at TEXT
);
''';

const String createTownshipTable = '''
CREATE TABLE townships (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  region_id INTEGER NOT NULL,
  name TEXT NOT NULL,
  created_at TEXT,
  updated_at TEXT,
  FOREIGN KEY (region_id) REFERENCES regions(id)
);
''';

const String createCategoryTable = '''
CREATE TABLE categories (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  seller_id INTEGER NOT NULL,
  parent_id INTEGER,
  name TEXT NOT NULL,
  description TEXT,
  is_sub_category INTEGER NOT NULL DEFAULT 0,
  created_at TEXT,
  updated_at TEXT,
  FOREIGN KEY (seller_id) REFERENCES sellers(id),
  FOREIGN KEY (parent_id) REFERENCES categories(id)
);
''';

const String createBrandTable = '''
CREATE TABLE brands (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  seller_id INTEGER NOT NULL,
  name TEXT NOT NULL,
  description TEXT,
  created_at TEXT,
  updated_at TEXT,
  FOREIGN KEY (seller_id) REFERENCES sellers(id)
);
''';

const String createSupplierTable = '''
CREATE TABLE suppliers (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  phone TEXT,
  email TEXT,
  address TEXT,
  created_at TEXT,
  updated_at TEXT
);
''';

const String createPaymentTable = '''
CREATE TABLE payments (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  note TEXT,
  is_published INTEGER NOT NULL DEFAULT 0,
  created_at TEXT,
  updated_at TEXT
);
''';

const String createPaymentAccountTable = '''
CREATE TABLE payment_accounts (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  payment_id INTEGER NOT NULL,
  number TEXT NOT NULL,
  name TEXT NOT NULL,
  created_at TEXT,
  updated_at TEXT,
  FOREIGN KEY (payment_id) REFERENCES payments(id)
);
''';

const String createProductTable = '''
CREATE TABLE products (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  seller_id INTEGER NOT NULL,
  category_id INTEGER,
  brand_id INTEGER,
  supplier_id INTEGER,
  sku TEXT,
  name TEXT NOT NULL,
  description TEXT,
  stock_quantity INTEGER NOT NULL DEFAULT 0,
  stock_threshold INTEGER NOT NULL DEFAULT 0,
  sell_price REAL NOT NULL DEFAULT 0,
  buy_price REAL NOT NULL DEFAULT 0,
  has_variant INTEGER NOT NULL DEFAULT 0,
  is_active INTEGER NOT NULL DEFAULT 1,
  created_at TEXT,
  updated_at TEXT,
  FOREIGN KEY (seller_id) REFERENCES sellers(id),
  FOREIGN KEY (category_id) REFERENCES categories(id),
  FOREIGN KEY (brand_id) REFERENCES brands(id),
  FOREIGN KEY (supplier_id) REFERENCES suppliers(id)
);
''';

const String createVariantTable = '''
CREATE TABLE variants (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  product_id INTEGER NOT NULL,
  name TEXT,
  attributes TEXT,
  sku TEXT,
  stock_quantity INTEGER NOT NULL DEFAULT 0,
  sell_price REAL NOT NULL DEFAULT 0,
  buy_price REAL NOT NULL DEFAULT 0,
  created_at TEXT,
  updated_at TEXT,
  FOREIGN KEY (product_id) REFERENCES products(id)
);
''';

const String createOrderTable = '''
CREATE TABLE orders (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  invoice_number TEXT NOT NULL UNIQUE,
  seller_id INTEGER NOT NULL,
  customer_name TEXT,
  customer_phone TEXT,
  status TEXT NOT NULL DEFAULT 'new',
  sub_total REAL NOT NULL DEFAULT 0,
  delivery_fees REAL NOT NULL DEFAULT 0,
  total_price REAL NOT NULL DEFAULT 0,
  payment_id INTEGER,
  payment_account_id INTEGER,
  tax REAL NOT NULL DEFAULT 0,
  tax_price REAL NOT NULL DEFAULT 0,
  given_amount REAL NOT NULL DEFAULT 0,
  change_amount REAL NOT NULL DEFAULT 0,
  note TEXT,
  image_path TEXT,
  created_at TEXT,
  updated_at TEXT,
  FOREIGN KEY (seller_id) REFERENCES sellers(id),
  FOREIGN KEY (payment_id) REFERENCES payments(id),
  FOREIGN KEY (payment_account_id) REFERENCES payment_accounts(id)
);
''';

const String createOrderProductTable = '''
CREATE TABLE order_products (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  order_id INTEGER NOT NULL,
  product_id INTEGER NOT NULL,
  variant_id INTEGER,
  attributes TEXT,
  price REAL NOT NULL DEFAULT 0,
  discount_price REAL NOT NULL DEFAULT 0,
  discount REAL NOT NULL DEFAULT 0,
  quantity INTEGER NOT NULL DEFAULT 1,
  profit REAL NOT NULL DEFAULT 0,
  original_buy_price REAL NOT NULL DEFAULT 0,
  original_price REAL NOT NULL DEFAULT 0,
  total_refunded_amount REAL NOT NULL DEFAULT 0,
  created_at TEXT,
  updated_at TEXT,
  FOREIGN KEY (order_id) REFERENCES orders(id),
  FOREIGN KEY (product_id) REFERENCES products(id),
  FOREIGN KEY (variant_id) REFERENCES variants(id)
);
''';

const String createOrderReturnTable = '''
CREATE TABLE order_returns (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  invoice_number TEXT NOT NULL UNIQUE,
  order_id INTEGER NOT NULL,
  seller_id INTEGER NOT NULL,
  status TEXT NOT NULL DEFAULT 'pending',
  reason TEXT NOT NULL,
  admin_notes TEXT,
  total_refund_amount REAL NOT NULL DEFAULT 0,
  restocking_decision TEXT,
  should_restock INTEGER NOT NULL DEFAULT 0,
  payment_slip TEXT,
  requested_at TEXT NOT NULL,
  approved_at TEXT,
  completed_at TEXT,
  created_at TEXT,
  updated_at TEXT,
  FOREIGN KEY (order_id) REFERENCES orders(id),
  FOREIGN KEY (seller_id) REFERENCES sellers(id)
);
''';

const String createOrderReturnProductsTable = '''
CREATE TABLE order_return_products (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  order_return_id INTEGER NOT NULL,
  order_product_id INTEGER NOT NULL,
  quantity_requested INTEGER NOT NULL DEFAULT 0,
  quantity_approved INTEGER NOT NULL DEFAULT 0,
  individual_reason TEXT,
  condition_notes TEXT,
  unit_refund_amount REAL NOT NULL DEFAULT 0,
  total_refund_amount REAL NOT NULL DEFAULT 0,
  is_restocked INTEGER NOT NULL DEFAULT 0,
  admin_notes TEXT,
  created_at TEXT,
  updated_at TEXT,
  FOREIGN KEY (order_return_id) REFERENCES order_returns(id),
  FOREIGN KEY (order_product_id) REFERENCES order_products(id)
);
''';

const String createPurchaseTable = '''
CREATE TABLE purchases (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  invoice_number TEXT NOT NULL UNIQUE,
  seller_id INTEGER NOT NULL,
  supplier_id INTEGER,
  total_amount REAL NOT NULL DEFAULT 0,
  paid_amount REAL NOT NULL DEFAULT 0,
  due_amount REAL NOT NULL DEFAULT 0,
  status TEXT NOT NULL DEFAULT 'pending',
  note TEXT,
  created_at TEXT,
  updated_at TEXT,
  FOREIGN KEY (seller_id) REFERENCES sellers(id),
  FOREIGN KEY (supplier_id) REFERENCES suppliers(id)
);
''';

const String createPurchaseProductTable = '''
CREATE TABLE purchase_products (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  purchase_id INTEGER NOT NULL,
  product_id INTEGER NOT NULL,
  variant_id INTEGER,
  quantity INTEGER NOT NULL DEFAULT 0,
  cost_price REAL NOT NULL DEFAULT 0,
  sell_price REAL NOT NULL DEFAULT 0,
  total_cost REAL NOT NULL DEFAULT 0,
  created_at TEXT,
  updated_at TEXT,
  FOREIGN KEY (purchase_id) REFERENCES purchases(id),
  FOREIGN KEY (product_id) REFERENCES products(id),
  FOREIGN KEY (variant_id) REFERENCES variants(id)
);
''';

const String createExpenseCategoryTable = '''
CREATE TABLE expanse_categories (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  icon TEXT,
  created_at TEXT,
  updated_at TEXT
);
''';

const String createExpenseTable = '''
CREATE TABLE expanses (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  expanse_category_id INTEGER NOT NULL,
  amount REAL NOT NULL DEFAULT 0,
  description TEXT,
  payment_method TEXT NOT NULL,
  transaction_type TEXT NOT NULL DEFAULT 'drawing',
  created_at TEXT,
  updated_at TEXT,
  FOREIGN KEY (expanse_category_id) REFERENCES expanse_categories(id)
);
''';

const String createPrinterTable = '''
CREATE TABLE printers (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  type TEXT,
  address TEXT,
  is_default INTEGER NOT NULL DEFAULT 0,
  created_at TEXT,
  updated_at TEXT
);
''';

const String createSettingsTable = '''
CREATE TABLE settings (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  seller_id INTEGER,
  store_name TEXT,
  receipt_phone TEXT,
  receipt_address TEXT,
  currency_code TEXT NOT NULL DEFAULT 'MMK',
  currency_symbol TEXT NOT NULL DEFAULT 'Ks',
  receipt_header TEXT,
  receipt_footer TEXT,
  default_payment_id INTEGER,
  tax_rate REAL NOT NULL DEFAULT 0,
  created_at TEXT,
  updated_at TEXT,
  FOREIGN KEY (seller_id) REFERENCES sellers(id),
  FOREIGN KEY (default_payment_id) REFERENCES payments(id)
);
''';

const String createExportTable = '''
CREATE TABLE IF NOT EXISTS exports (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  completed_at TEXT,
  file_disk TEXT NOT NULL,
  file_name TEXT,
  exporter TEXT NOT NULL,
  processed_rows INTEGER NOT NULL DEFAULT 0,
  total_rows INTEGER NOT NULL,
  successful_rows INTEGER NOT NULL DEFAULT 0,
  created_at TEXT,
  updated_at TEXT
);
''';

const String createImportTable = '''
CREATE TABLE IF NOT EXISTS imports (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  import_type TEXT NOT NULL,
  target_table TEXT,
  file_name TEXT NOT NULL,
  file_path TEXT NOT NULL,
  importer TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'completed',
  processed_rows INTEGER NOT NULL DEFAULT 0,
  total_rows INTEGER NOT NULL DEFAULT 0,
  successful_rows INTEGER NOT NULL DEFAULT 0,
  failed_rows INTEGER NOT NULL DEFAULT 0,
  error_message TEXT,
  seller_id INTEGER,
  completed_at TEXT,
  created_at TEXT,
  updated_at TEXT,
  FOREIGN KEY (seller_id) REFERENCES sellers(id)
);
''';

const String createAttributeTable = '''
CREATE TABLE attributes (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  seller_id INTEGER NOT NULL,
  name TEXT NOT NULL,
  type TEXT NOT NULL,
  created_at TEXT,
  updated_at TEXT,
  FOREIGN KEY (seller_id) REFERENCES sellers(id)
);
''';

const String createAttributeValueTable = '''
CREATE TABLE attribute_values (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  attribute_id INTEGER NOT NULL,
  value TEXT NOT NULL,
  color_code TEXT,
  created_at TEXT,
  updated_at TEXT,
  FOREIGN KEY (attribute_id) REFERENCES attributes(id)
);
''';

const String createProductAttributeValueTable = '''
CREATE TABLE product_attribute_values (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  product_id INTEGER NOT NULL,
  attribute_id INTEGER NOT NULL,
  attribute_value_id INTEGER NOT NULL,
  created_at TEXT,
  updated_at TEXT,
  FOREIGN KEY (product_id) REFERENCES products(id),
  FOREIGN KEY (attribute_id) REFERENCES attributes(id),
  FOREIGN KEY (attribute_value_id) REFERENCES attribute_values(id)
);
''';
