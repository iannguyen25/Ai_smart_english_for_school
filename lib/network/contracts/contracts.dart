enum ItemType { Category, Product }

extension ItemTypeExt on ItemType {
  int get value {
    switch (this) {
      case ItemType.Category:
        return 1;
      case ItemType.Product:
        return 2;
    }
  }
}
