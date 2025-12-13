/// Validators that match backend validation rules
/// All messages are in Arabic for RTL UI
class Validators {
  Validators._();

  /// Email validation
  /// - Required
  /// - Must be valid email format
  static String? email(String? value, {bool required = true}) {
    if (value == null || value.isEmpty) {
      return required ? 'يرجى إدخال البريد الإلكتروني' : null;
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'يرجى إدخال بريد إلكتروني صحيح';
    }
    return null;
  }

  /// Password validation - matches backend requirements
  /// - Minimum 8 characters
  /// - At least one uppercase letter
  /// - At least one lowercase letter  
  /// - At least one number
  static String? password(String? value, {bool required = true}) {
    if (value == null || value.isEmpty) {
      return required ? 'يرجى إدخال كلمة المرور' : null;
    }
    if (value.length < 8) {
      return 'كلمة المرور يجب أن تكون 8 أحرف على الأقل';
    }
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'كلمة المرور يجب أن تحتوي على حرف صغير';
    }
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'كلمة المرور يجب أن تحتوي على حرف كبير';
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'كلمة المرور يجب أن تحتوي على رقم';
    }
    return null;
  }

  /// Confirm password validation
  static String? confirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'يرجى تأكيد كلمة المرور';
    }
    if (value != password) {
      return 'كلمتا المرور غير متطابقتين';
    }
    return null;
  }

  /// Full name validation
  /// - Required
  /// - Minimum 3 characters
  static String? fullName(String? value, {bool required = true}) {
    if (value == null || value.trim().isEmpty) {
      return required ? 'يرجى إدخال الاسم الكامل' : null;
    }
    if (value.trim().length < 3) {
      return 'الاسم يجب أن يكون 3 أحرف على الأقل';
    }
    return null;
  }

  /// Saudi phone number validation
  /// Accepts formats:
  /// - +966xxxxxxxxx (with country code)
  /// - 966xxxxxxxxx (without +)
  /// - 05xxxxxxxx (local format)
  /// - 5xxxxxxxx (without leading 0)
  static String? saudiPhone(String? value, {bool required = false}) {
    if (value == null || value.isEmpty) {
      return required ? 'يرجى إدخال رقم الجوال' : null;
    }
    
    // Remove spaces and dashes
    final cleaned = value.replaceAll(RegExp(r'[\s\-]'), '');
    
    // Saudi phone patterns
    final patterns = [
      RegExp(r'^\+966[5][0-9]{8}$'),    // +966500000000
      RegExp(r'^966[5][0-9]{8}$'),       // 966500000000
      RegExp(r'^0[5][0-9]{8}$'),         // 0500000000
      RegExp(r'^[5][0-9]{8}$'),          // 500000000
    ];
    
    final isValid = patterns.any((pattern) => pattern.hasMatch(cleaned));
    
    if (!isValid) {
      return 'يرجى إدخال رقم جوال سعودي صحيح (مثال: 05xxxxxxxx)';
    }
    return null;
  }

  /// Generic required field validation
  static String? requiredField(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return 'يرجى إدخال $fieldName';
    }
    return null;
  }

  /// Minimum length validation
  static String? minLength(String? value, int min, String fieldName) {
    if (value == null || value.length < min) {
      return '$fieldName يجب أن يكون $min أحرف على الأقل';
    }
    return null;
  }

  /// Maximum length validation
  static String? maxLength(String? value, int max, String fieldName) {
    if (value != null && value.length > max) {
      return '$fieldName يجب أن لا يتجاوز $max حرف';
    }
    return null;
  }

  /// Project name validation
  static String? projectName(String? value, {bool required = true}) {
    if (value == null || value.trim().isEmpty) {
      return required ? 'يرجى إدخال اسم المشروع' : null;
    }
    if (value.trim().length < 2) {
      return 'اسم المشروع قصير جداً';
    }
    return null;
  }

  /// Price validation
  static String? price(String? value, {bool required = true}) {
    if (value == null || value.isEmpty) {
      return required ? 'يرجى إدخال السعر' : null;
    }
    final price = double.tryParse(value);
    if (price == null || price < 0) {
      return 'يرجى إدخال سعر صحيح';
    }
    return null;
  }

  /// Quantity validation
  static String? quantity(String? value, {bool required = true}) {
    if (value == null || value.isEmpty) {
      return required ? 'يرجى إدخال الكمية' : null;
    }
    final qty = int.tryParse(value);
    if (qty == null || qty < 0) {
      return 'يرجى إدخال كمية صحيحة';
    }
    return null;
  }
}

