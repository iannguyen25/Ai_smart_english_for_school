class Fomulator {
  static String priceM2({required double price, required double area}) {
    double priceM2 = double.parse((area / price).toStringAsFixed(2));
    if (priceM2.toString().contains(".00")) {
      return priceM2.toInt().toString();
    }
    return priceM2.toString();
  }

  static String acronym(String data) {
    List<String> dataList = data.split(" ");
    String acronym = "";
    dataList.forEach((element) {
      acronym += element.substring(0, 0) + " ";
    });
    return acronym.trim();
  }
}
