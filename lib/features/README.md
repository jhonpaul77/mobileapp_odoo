# Features Folder Structure

Folder ini mengikuti **Clean Architecture** dengan struktur yang konsisten untuk setiap feature.

## 📁 Struktur Standard

Setiap feature harus memiliki struktur berikut:

```
features/
├── customer/
│   ├── data/
│   │   └── repositories/          # Repository implementations
│   ├── domain/
│   │   ├── entities/              # Business entities/models
│   │   └── usecases/              # Business logic use cases
│   └── presentation/
│       ├── pages/                 # UI pages/screens
│       ├── providers/             # State management (Provider)
│       └── widgets/               # Reusable UI widgets
│
├── product/
│   ├── data/
│   │   ├── datasources/           # Data sources (API, local DB)
│   │   ├── models/                # Data transfer objects
│   │   └── repositories/          # Repository implementations
│   ├── domain/
│   │   ├── entities/              # Business entities/models
│   │   └── usecases/              # Business logic use cases
│   └── presentation/
│       ├── pages/                 # UI pages/screens
│       ├── providers/             # State management (Provider)
│       └── widgets/               # Reusable UI widgets
│
└── sales_order/
    ├── data/
    │   └── repositories/          # Repository implementations
    ├── domain/
    │   ├── entities/              # Business entities/models
    │   └── usecases/              # Business logic use cases
    └── presentation/
        ├── pages/                 # UI pages/screens
        ├── providers/             # State management (Provider)
        └── widgets/               # Reusable UI widgets
```

## 📦 Layer Descriptions

### 1. **Data Layer** (`data/`)
Bertanggung jawab untuk:
- Mengakses data dari API, database, atau sumber lain
- Implementasi repositories
- Data models/DTOs
- Data sources (remote/local)

**Files:**
- `repositories/` - Implementasi dari repository interfaces
- `datasources/` - API clients, database access (optional)
- `models/` - Data transfer objects (optional)

### 2. **Domain Layer** (`domain/`)
Bertanggung jawab untuk:
- Business logic murni
- Entities/Models aplikasi
- Use cases (operasi bisnis)
- Repository interfaces (contracts)

**Files:**
- `entities/` - Model bisnis (Customer, Product, SalesOrder, dll)
- `usecases/` - Business operations (CreateCustomer, FetchProducts, dll)

### 3. **Presentation Layer** (`presentation/`)
Bertanggung jawab untuk:
- UI/UX
- State management
- User interactions
- Widgets/Components

**Files:**
- `pages/` - Halaman/screens utama
- `providers/` - State management dengan Provider pattern
- `widgets/` - Reusable UI components

## 🎯 Design Principles

### Clean Architecture
1. **Dependency Rule**: Outer layers depend on inner layers
   - Presentation → Domain → Data
   - Domain tidak boleh depend pada Presentation/Data
   
2. **Separation of Concerns**: Setiap layer punya tanggung jawab yang jelas

3. **Testability**: Setiap layer bisa ditest secara independen

### Feature-Based Organization
- Setiap feature adalah module yang independen
- Easy to maintain, scale, and test
- Clear boundaries between features

## 📝 Naming Conventions

### Files
- **Entities**: `customer.dart`, `product.dart`
- **Use Cases**: `create_customer_usecase.dart`, `fetch_products_usecase.dart`
- **Repositories**: `customer_repository.dart`, `product_repository.dart`
- **Pages**: `customer_list_page.dart`, `product_detail_page.dart`
- **Providers**: `customer_provider.dart`, `product_provider.dart`
- **Widgets**: `customer_card.dart`, `product_search_bar.dart`

### Classes
- **Entities**: `Customer`, `Product`, `SalesOrder`
- **Use Cases**: `CreateCustomerUseCase`, `FetchProductsUseCase`
- **Repositories**: `CustomerRepository`, `ProductRepository`
- **Pages**: `CustomerListPage`, `ProductDetailPage`
- **Providers**: `CustomerProvider`, `ProductProvider`
- **Widgets**: `CustomerCard`, `ProductSearchBar`

## 🔄 Data Flow Example

```
User Action (UI)
    ↓
Provider (State Management)
    ↓
UseCase (Business Logic)
    ↓
Repository (Data Access)
    ↓
API/Database
    ↓
Repository returns data
    ↓
UseCase processes data
    ↓
Provider updates state
    ↓
UI rebuilds with new data
```

## 📚 Best Practices

1. **Keep features independent** - Avoid cross-feature dependencies
2. **Use dependency injection** - Pass dependencies through constructors
3. **Follow single responsibility** - One class, one responsibility
4. **Write testable code** - Separate business logic from UI
5. **Use meaningful names** - Clear, descriptive names for classes and files

## 🚀 Adding a New Feature

1. Create feature folder: `lib/features/new_feature/`
2. Create standard structure:
   ```bash
   mkdir -p data/repositories
   mkdir -p domain/entities domain/usecases
   mkdir -p presentation/pages presentation/providers presentation/widgets
   ```
3. Implement layers bottom-up: Domain → Data → Presentation
4. Add to main app routing/navigation

## 📖 References

- [Clean Architecture by Uncle Bob](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
- [Flutter Clean Architecture](https://resocoder.com/flutter-clean-architecture-tdd/)
- [Provider State Management](https://pub.dev/packages/provider)
