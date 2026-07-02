import 'package:flutter/material.dart';
import '../data/dummy_data.dart';
import 'package:pintarx/pages/sales/penjualan_page.dart';

class MenuUtama extends StatelessWidget {
  const MenuUtama({super.key});

  Widget _buildMenuCard(BuildContext context, Map<String, dynamic> menu) {
    return GestureDetector(
      onTap: () {
        // Navigate to specific page based on route
        if (menu["route"] == "sales") {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const PenjualanPage(),
            ),
          );
        } else if (menu["route"] == "inventory") {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Inventory - Coming Soon'),
              duration: Duration(milliseconds: 800),
            ),
          );
        } else if (menu["route"] == "production") {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Production - Coming Soon'),
              duration: Duration(milliseconds: 800),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Navigate to ${menu["title"]}'),
              duration: const Duration(milliseconds: 800),
            ),
          );
        }
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              Color(menu["color"] as int).withOpacity(0.9),
              Color(menu["color"] as int).withOpacity(0.7),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Color(menu["color"] as int).withOpacity(0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                menu["icon"] as IconData,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              menu["title"],
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: DummyData.mainMenus.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 14,
        crossAxisSpacing: 12,
        childAspectRatio: 1.0,
      ),
      itemBuilder: (context, index) => _buildMenuCard(
        context,
        DummyData.mainMenus[index],
      ),
    );
  }
}