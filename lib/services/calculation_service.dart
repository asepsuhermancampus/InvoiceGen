class CalculationService {
  static const List<String> _satuan = [
    '', 'Satu', 'Dua', 'Tiga', 'Empat', 'Lima', 'Enam', 'Tujuh', 'Delapan', 'Sembilan', 'Sepuluh', 'Sebelas'
  ];

  static String terbilang(double number) {
    if (number < 0) {
      return 'Minus ${terbilang(-number)}';
    }
    
    int num = number.round();
    
    if (num < 12) {
      return _satuan[num];
    } else if (num < 20) {
      return '${terbilang((num - 10).toDouble())} Belas';
    } else if (num < 100) {
      return '${terbilang((num / 10).floor().toDouble())} Puluh ${terbilang((num % 10).toDouble())}';
    } else if (num < 200) {
      return 'Seratus ${terbilang((num - 100).toDouble())}';
    } else if (num < 1000) {
      return '${terbilang((num / 100).floor().toDouble())} Ratus ${terbilang((num % 100).toDouble())}';
    } else if (num < 2000) {
      return 'Seribu ${terbilang((num - 1000).toDouble())}';
    } else if (num < 1000000) {
      return '${terbilang((num / 1000).floor().toDouble())} Ribu ${terbilang((num % 1000).toDouble())}';
    } else if (num < 1000000000) {
      return '${terbilang((num / 1000000).floor().toDouble())} Juta ${terbilang((num % 1000000).toDouble())}';
    } else if (num < 1000000000000) {
      return '${terbilang((num / 1000000000).floor().toDouble())} Milyar ${terbilang((num % 1000000000).toDouble())}';
    } else {
      return '${terbilang((num / 1000000000000).floor().toDouble())} Triliun ${terbilang((num % 1000000000000).toDouble())}';
    }
  }

  static double calculateSellingPrice(double costPrice, double markupPercentage) {
    return costPrice + (costPrice * markupPercentage / 100);
  }

  static double calculateItemSubtotal(double qty, double sellingPrice, double discount) {
    return (qty * sellingPrice) - discount;
  }

  static Map<String, double> calculateInvoiceTotals({
    required List<Map<String, double>> items, // Requires list of {qty, sellingPrice, discount}
    required double taxRate, // e.g. 11 for 11%
    required double pphRate, // e.g. 2 for 2%
  }) {
    double subtotal = 0;
    double totalDiscount = 0;

    for (var item in items) {
      double qty = item['qty'] ?? 0;
      double sp = item['sellingPrice'] ?? 0;
      double disc = item['discount'] ?? 0;
      
      subtotal += (qty * sp);
      totalDiscount += disc;
    }

    double taxableAmount = subtotal - totalDiscount;
    double taxTotal = taxableAmount * (taxRate / 100);
    double pphTotal = taxableAmount * (pphRate / 100);

    double grandTotal = taxableAmount + taxTotal - pphTotal;

    return {
      'subtotal': subtotal,
      'discountTotal': totalDiscount,
      'taxTotal': taxTotal,
      'pphTotal': pphTotal,
      'grandTotal': grandTotal,
    };
  }
}
