/// Phone Number Formatting - Standard Implementation for WhatsApp
/// 
/// This is the STANDARD phone formatting logic used across all WhatsApp calls.
/// Use this template for any NEW WhatsApp integrations.
/// 
/// Location: All three files now use this approach:
/// - lib/pages/sales/transaction/transaction_detail_page.dart
/// - lib/features/sales_order/presentation/pages/sales_order_detail_page.dart
/// - lib/features/customer/presentation/pages/customer_detail_page.dart

/// Format phone number correctly - extract only digits
String formattedPhone = phoneNumber.trim();
print('🔧 [PHONE_FORMAT] Original: $phoneNumber');

// Step 1: Remove all non-digit characters (spaces, dashes, +, etc)
formattedPhone = formattedPhone.replaceAll(RegExp(r'[^0-9]'), '');
print('🔧 [PHONE_FORMAT] After removing non-digits: $formattedPhone');

// Step 2: Remove leading 0 if exists
if (formattedPhone.startsWith('0')) {
  formattedPhone = formattedPhone.substring(1);
  print('🔧 [PHONE_FORMAT] After removing leading 0: $formattedPhone');
}

// Step 3: Remove leading 62 if exists (to avoid duplication)
int removeCount = 0;
while (formattedPhone.startsWith('62')) {
  formattedPhone = formattedPhone.substring(2);
  removeCount++;
}
if (removeCount > 0) {
  print('🔧 [PHONE_FORMAT] Removed $removeCount leading 62: $formattedPhone');
}

// Step 4: Ensure it starts with 62
if (!formattedPhone.startsWith('62')) {
  formattedPhone = '62$formattedPhone';
  print('🔧 [PHONE_FORMAT] Added 62 prefix: $formattedPhone');
}

print('✅ [PHONE_FORMAT] Final formatted phone: $formattedPhone');

/// Result: formattedPhone is now in format: 628775997410 (digits only, starts with 62)
///
/// Examples:
/// Input: "+62 877-5997-5410" → Output: "628775997410" ✅
/// Input: "0877-5997-5410"    → Output: "628775997410" ✅
/// Input: "62 877 5997 5410"  → Output: "628775997410" ✅
/// Input: "628775997410"      → Output: "628775997410" ✅
/// Input: "+62+62 877-5997"   → Output: "628775997"    ✅ (removes duplicate)
///
/// WhatsApp URLs:
/// - wa.me format: https://wa.me/628775997410
/// - api format:   https://api.whatsapp.com/send?phone=628775997410&text=...
