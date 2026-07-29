class ApiConfig {
  // ========================================
  // 🔧 ODOO API CONFIGURATION
  // ========================================
  static const String baseUrl = 'https://demoerp.riztastore.id';

  // Odoo Connect Endpoint
  static const String odooConnect = '/odoo_connect';

  // Legacy endpoints (kept for reference, will be updated as Odoo endpoints are discovered)
  static const String apiVersion = '/api/v1';
  static const String signIn =
      odooConnect; // Using Odoo connect for authentication
  static const String refreshToken =
      '$apiVersion/auth/refresh'; // TBD: Update when Odoo endpoint known
  static const String signOut =
      '$apiVersion/auth/signout'; // TBD: Update when Odoo endpoint known

  // ✅ Location Endpoints
  static const String locationFetch =
      '$apiVersion/location/fetch'; // GET - List dengan pagination
  static const String locationGet =
      '$apiVersion/location/get'; // GET - Get by ID (path param)
  static const String locationLookup =
      '$apiVersion/location/lookup'; // GET - Lookup/Search
  static const String locationCreate = '$apiVersion/location'; // POST - Create
  static const String locationUpdate = '$apiVersion/location'; // PUT - Update

// 🏷️ Product Category Endpoints
  static const String productCategoryFetch =
      '$apiVersion/product_category'; // GET - List dengan pagination
  static const String productCategoryGet =
      '$apiVersion/product_category'; // GET - Get by ID
  static const String productCategoryCreate =
      '$apiVersion/product_category'; // POST - Create
  static const String productCategoryUpdate =
      '$apiVersion/product_category'; // PUT - Update

// 📦 Product Group Endpoints
  static const String productGroupFetch = '$apiVersion/product_group';
  static const String productGroupGet = '$apiVersion/product_group';
  static const String productGroupCreate = '$apiVersion/product_group';
  static const String productGroupUpdate = '$apiVersion/product_group';

  // ✅ Organization Endpoints - TAMBAHAN
  static const String organizationFetch =
      '$apiVersion/organization'; // GET - List dengan pagination
  static const String organizationGet =
      '$apiVersion/organization'; // GET - Get by ID
  static const String organizationCreate =
      '$apiVersion/organization'; // POST - Create
  static const String organizationUpdate =
      '$apiVersion/organization'; // PUT - Update (DELETE juga)

  // ✅ CUSTOMER ENDPOINTS - TAMBAHAN
  static const String customerFetch =
      '$apiVersion/contact/customer'; // GET - List dengan pagination
  static const String customerGet =
      '$apiVersion/contact/customer/get'; // GET - Get by ID
  //static const String customerGet = '/contact/customer/get';
  static const String customerCreate =
      '$apiVersion/contact/customer'; // POST - Create
  static const String customerUpdate =
      '$apiVersion/contact/customer'; // PUT - Update

  // ✅ CUSTOMER ENDPOINTS - ODOO
  static const String getCustomer = '/get_customer'; // GET - Get all customers
  static const String createCustomer =
      '/create_customer'; // POST - Create customer
  static const String editCustomer = '/edit_customer'; // POST - Edit customer

  // ✅ PRODUCT ENDPOINTS - ODOO
  static const String getProductSale =
      '/get_product_sale'; // GET - Get all products for sale

  // ✅ SALES ENDPOINTS - TAMBAHAN
  static const String sales = '$apiVersion/sales'; // POST - Create
  //static const String sales = "/sales";

  // ✅ SALES ENDPOINTS - ODOO
  static const String getSalesOrder = '/get_sale_order'; // GET - Get all sales orders
  static const String editSalesOrder = '/edit_sale_order'; // POST - Edit sales order

  // ========================================
  // 📋 HEADERS CONFIGURATION
  // ========================================
  static Map<String, String> get headers => {
        'accept': 'application/json',
        'Content-Type': 'application/json',
      };

  // Odoo-specific headers for authentication
  static Map<String, String> odooAuthHeaders({
    required String db,
    required String login,
    required String password,
  }) =>
      {
        'db': db,
        'login': login,
        'password': password,
      };

  // Odoo-specific headers for API requests (with api-key)
  static Map<String, String> odooApiHeaders({
    required String db,
    required String apiKey,
  }) =>
      {
        'db': db,
        'api-key': apiKey,
      };

  static Map<String, String> headersWithAuth(String token) => {
        ...headers,
        'Authorization': 'bearer $token',
      };
}
