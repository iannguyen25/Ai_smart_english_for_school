class InputValidator {
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email không được để trống';
    }
    // Regex cho email
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Email không hợp lệ';
    }
    return null;
  }

  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Tên không được để trống';
    }
    if (value.length < 2) {
      return 'Tên phải có ít nhất 2 ký tự';
    }
    if (value.length > 50) {
      return 'Tên không được quá 50 ký tự';
    }
    return null;
  }

  static String? validateTitle(String? value) {
    if (value == null || value.isEmpty) {
      return 'Tiêu đề không được để trống';
    }
    if (value.length < 3) {
      return 'Tiêu đề phải có ít nhất 3 ký tự';
    }
    if (value.length > 200) {
      return 'Tiêu đề không được quá 200 ký tự';
    }
    return null;
  }

  static String? validateDescription(String? value) {
    if (value == null || value.isEmpty) {
      return 'Mô tả không được để trống';
    }
    if (value.length > 2000) {
      return 'Mô tả không được quá 2000 ký tự';
    }
    return null;
  }

  static String? validateUrl(String? value) {
    if (value == null || value.isEmpty) {
      return 'URL không được để trống';
    }
    // Regex cho URL
    final urlRegex = RegExp(
      r'^(http:\/\/www\.|https:\/\/www\.|http:\/\/|https:\/\/)?[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(:[0-9]{1,5})?(\/.*)?$'
    );
    if (!urlRegex.hasMatch(value)) {
      return 'URL không hợp lệ';
    }
    return null;
  }

  static String? validateFileSize(int? value) {
    if (value == null) {
      return 'Kích thước file không được để trống';
    }
    if (value <= 0) {
      return 'Kích thước file phải lớn hơn 0';
    }
    // Giới hạn file 100MB
    if (value > 102400) {
      return 'Kích thước file không được quá 100MB';
    }
    return null;
  }

  static String? validateTags(List<String>? tags) {
    if (tags == null || tags.isEmpty) {
      return 'Phải có ít nhất 1 tag';
    }
    if (tags.length > 10) {
      return 'Không được quá 10 tags';
    }
    for (var tag in tags) {
      if (tag.length > 30) {
        return 'Mỗi tag không được quá 30 ký tự';
      }
    }
    return null;
  }

  static String? validateEstimatedMinutes(int? value) {
    if (value == null) {
      return 'Thời gian ước tính không được để trống';
    }
    if (value <= 0) {
      return 'Thời gian ước tính phải lớn hơn 0';
    }
    // Giới hạn 8 giờ
    if (value > 480) {
      return 'Thời gian ước tính không được quá 8 giờ';
    }
    return null;
  }
} 