typedef Validator = String? Function(String?);

class V {
  static Validator required([String message = 'Поле обязательно']) {
    return (value) => (value == null || value.trim().isEmpty) ? message : null;
  }

  static Validator length({int min = 0, int max = 255}) {
    return (value) {
      final text = value?.trim() ?? '';
      if (text.length < min) return 'Не короче $min символов';
      if (text.length > max) return 'Не длиннее $max символов';
      return null;
    };
  }

  static Validator integer({int? min, int? max}) {
    return (value) {
      final n = int.tryParse(value?.trim() ?? '');
      if (n == null) return 'Введите целое число';
      if (min != null && n < min) return 'Значение не меньше $min';
      if (max != null && n > max) return 'Значение не больше $max';
      return null;
    };
  }

  static Validator email() {
    final re = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');
    return (value) => re.hasMatch(value?.trim() ?? '') ? null : 'Некорректный адрес почты';
  }

  static Validator phone() {
    final re = RegExp(r'^\+?[0-9][0-9\-\s]{9,16}$');
    return (value) => re.hasMatch(value?.trim() ?? '') ? null : 'Некорректный телефон';
  }

  static Validator date() {
    final re = RegExp(r'^\d{4}-\d{2}-\d{2}$');
    return (value) {
      final text = value?.trim() ?? '';
      if (!re.hasMatch(text)) return 'Дата в формате ГГГГ-ММ-ДД';
      if (DateTime.tryParse(text) == null) return 'Такой даты нет';
      return null;
    };
  }

  static Validator pattern(RegExp re, String message) {
    return (value) => re.hasMatch(value?.trim() ?? '') ? null : message;
  }

  static Validator combine(List<Validator> validators) {
    return (value) {
      for (final validator in validators) {
        final error = validator(value);
        if (error != null) return error;
      }
      return null;
    };
  }
}
