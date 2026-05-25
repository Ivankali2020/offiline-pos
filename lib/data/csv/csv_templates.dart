/// Sample CSV template definitions for each import type.
/// These are used to generate downloadable sample files for the user.
abstract class CsvTemplates {
  // ---------------------------------------------------------------------------
  // Categories
  // ---------------------------------------------------------------------------
  static const String categoriesHeader = 'name,description,is_sub_category';
  static const String categoriesSample = '''name,description,is_sub_category
Electronics,Electronic devices and accessories,0
Smartphones,Mobile phones and accessories,1
Laptops,Portable computers,1
Clothing,Apparel and fashion,0
Mens Wear,Clothing for men,1''';

  // ---------------------------------------------------------------------------
  // Brands
  // ---------------------------------------------------------------------------
  static const String brandsHeader = 'name,description';
  static const String brandsSample = '''name,description
Samsung,South Korean electronics manufacturer
Apple,American technology company
Nike,American athletic footwear and apparel
Sony,Japanese multinational conglomerate
Adidas,German multinational athletic apparel''';

  // ---------------------------------------------------------------------------
  // Expense Categories
  // ---------------------------------------------------------------------------
  static const String expenseCategoriesHeader = 'name,icon';
  static const String expenseCategoriesSample = '''name,icon
Rent,home
Utilities,zap
Salaries,users
Transport,truck
Marketing,megaphone''';

  // ---------------------------------------------------------------------------
  // Expenses
  // ---------------------------------------------------------------------------
  static const String expensesHeader =
      'category_name,amount,description,payment_method,date';
  static const String expensesSample =
      '''category_name,amount,description,payment_method,date
Rent,500000,Monthly office rent,Cash,2025-01-01
Utilities,35000,Electricity bill,Cash,2025-01-05
Transport,12000,Fuel for delivery,Cash,2025-01-10
Marketing,80000,Facebook ads,Bank Transfer,2025-01-15
Salaries,1200000,Staff salaries January,Bank Transfer,2025-01-31''';

  // ---------------------------------------------------------------------------
  // Products
  // ---------------------------------------------------------------------------
  static const String productsHeader =
      'name,sku,description,sell_price,buy_price,stock_quantity,stock_threshold,category_name,brand_name,is_active';
  static const String productsSample =
      '''name,sku,description,sell_price,buy_price,stock_quantity,stock_threshold,category_name,brand_name,is_active
Samsung Galaxy A55,SKU-001,6.6 inch smartphone 128GB,850000,720000,50,5,Smartphones,Samsung,1
Apple iPhone 15,SKU-002,6.1 inch smartphone 256GB,2200000,1900000,20,3,Smartphones,Apple,1
Sony WH-1000XM5,SKU-003,Wireless noise cancelling headphones,650000,520000,30,5,Electronics,Sony,1
Nike Air Max 270,SKU-004,Mens running shoes size 42,120000,80000,100,10,Mens Wear,Nike,1
Adidas Ultraboost 23,SKU-005,Mens running shoes size 41,145000,100000,80,10,Mens Wear,Adidas,1''';

  /// Returns the full sample CSV string for the given import type name.
  static String sampleFor(String typeName) {
    switch (typeName) {
      case 'categories':
        return categoriesSample;
      case 'brands':
        return brandsSample;
      case 'expense_categories':
        return expenseCategoriesSample;
      case 'expenses':
        return expensesSample;
      case 'products':
        return productsSample;
      default:
        return '';
    }
  }

  /// Returns the filename for the sample CSV of the given type.
  static String filenameFor(String typeName) {
    return 'sample_$typeName.csv';
  }
}
