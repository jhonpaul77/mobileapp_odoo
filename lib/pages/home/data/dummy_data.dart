import 'package:flutter/material.dart';

class DummyData {
  // Dashboard Statistics
  static final Map<String, dynamic> dashboardStats = {
    "totalSales": 125500000.00,
    "totalExpenses": 45200000.00,
    "inventoryValue": 78900000.00,
    "pendingOrders": 12,
    "lowStockItems": 5,
    "profit": 80300000.00,
  };

  // Sales Data
  static final List<Map<String, dynamic>> salesData = [
    {
      "id": 1,
      "date": "2024-10-15",
      "customer": "PT Maju Jaya",
      "amount": 2500000.0,
      "status": "completed"
    },
    {
      "id": 2,
      "date": "2024-10-14",
      "customer": "CV Sumber Makmur",
      "amount": 1800000.0,
      "status": "pending"
    },
    {
      "id": 3,
      "date": "2024-10-13",
      "customer": "UD Berkah Jaya",
      "amount": 3200000.0,
      "status": "completed"
    },
  ];

  // Inventory Items
  static final List<Map<String, dynamic>> inventoryItems = [
    {
      "id": 1,
      "name": "Bahan Baku Premium A",
      "sku": "BBA001",
      "qty": 45,
      "minQty": 50,
      "price": 15000.0,
      "unit": "Kg",
      "status": "low_stock"
    },
    {
      "id": 2,
      "name": "Material Kualitas B",
      "sku": "BBA002",
      "qty": 120,
      "minQty": 50,
      "price": 22000.0,
      "unit": "Kg",
      "status": "normal"
    },
    {
      "id": 3,
      "name": "Produk Jadi Premium",
      "sku": "PJ001",
      "qty": 15,
      "minQty": 30,
      "price": 85000.0,
      "unit": "Pcs",
      "status": "low_stock"
    },
    {
      "id": 4,
      "name": "Kemasan Box Deluxe",
      "sku": "KEM001",
      "qty": 25,
      "minQty": 100,
      "price": 5000.0,
      "unit": "Pcs",
      "status": "low_stock"
    },
  ];

  // Expenses
  static final List<Map<String, dynamic>> expenses = [
    {
      "id": 1,
      "category": "Bahan Baku",
      "description": "Pembelian Material Premium Quality",
      "amount": 15000000.0,
      "date": "2024-10-15",
      "status": "verified"
    },
    {
      "id": 2,
      "category": "Operasional",
      "description": "Biaya Listrik & Air Bulan Oktober",
      "amount": 5000000.0,
      "date": "2024-10-14",
      "status": "pending"
    },
    {
      "id": 3,
      "category": "Gaji Karyawan",
      "description": "Gaji 15 Karyawan Periode Oktober",
      "amount": 25000000.0,
      "date": "2024-10-01",
      "status": "verified"
    },
  ];

  // Production Orders
  static final List<Map<String, dynamic>> productionOrders = [
    {
      "id": 1,
      "product": "Produk Premium A",
      "qty": 500,
      "progress": 75,
      "status": "in_progress",
      "dueDate": "2024-10-20"
    },
    {
      "id": 2,
      "product": "Produk Standard B",
      "qty": 1000,
      "progress": 45,
      "status": "in_progress",
      "dueDate": "2024-10-25"
    },
    {
      "id": 3,
      "product": "Produk Deluxe C",
      "qty": 250,
      "progress": 100,
      "status": "completed",
      "dueDate": "2024-10-15"
    },
  ];

  // Purchase Orders
  static final List<Map<String, dynamic>> purchaseOrders = [
    {
      "id": 1,
      "supplier": "PT Supplier Utama",
      "items": "Material A, Material B",
      "amount": 12000000.0,
      "status": "pending",
      "date": "2024-10-15"
    },
    {
      "id": 2,
      "supplier": "CV Bahan Jaya",
      "items": "Bahan Baku Premium",
      "amount": 8500000.0,
      "status": "delivered",
      "date": "2024-10-13"
    },
  ];

  // Main Menus
  static final List<Map<String, dynamic>> mainMenus = [
    {
      "title": "Penjualan",
      "icon": Icons.shopping_cart_rounded,
      "color": 0xFF3B82F6,
      "route": "sales"
    },
    {
      "title": "Inventory",
      "icon": Icons.inventory_2_rounded,
      "color": 0xFF8B5CF6,
      "route": "inventory"
    },
    {
      "title": "Produksi",
      "icon": Icons.factory_rounded,
      "color": 0xFF06B6D4,
      "route": "production"
    },
    {
      "title": "Pembelian",
      "icon": Icons.local_shipping_rounded,
      "color": 0xFF14B8A6,
      "route": "purchasing"
    },
    {
      "title": "Pengeluaran",
      "icon": Icons.receipt_long_rounded,
      "color": 0xFFF59E0B,
      "route": "expenses"
    },
    {
      "title": "Laporan",
      "icon": Icons.assessment_rounded,
      "color": 0xFFEC4899,
      "route": "reports"
    },
  ];
}
