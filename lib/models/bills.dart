class Bill {
  String id;
  String customerId;
  List<BillItem> items;
  double totalAmount;
  String status;
  String date;

  Bill({
    required this.id,
    required this.customerId,
    required this.items,
    required this.totalAmount,
    required this.status,
    required this.date,
  });

  factory Bill.fromJson(Map<String, dynamic> json) {
    return Bill(
      id: json['_id'],
      customerId: json['customer'],
      items: (json['items'] as List).map((item) => BillItem.fromJson(item)).toList(),
      totalAmount: json['totalAmount'].toDouble(),
      status: json['status'],
      date: json['date'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'customer': customerId,
      'items': items.map((item) => item.toJson()).toList(),
      'totalAmount': totalAmount,
      'status': status,
      'date': date,
    };
  }
}

class BillItem {
  String itemId;
  int quantity;
  double saleRate;
  double total;
  String name;
  double purchaseRate;


  BillItem({
    required this.itemId,
    required this.quantity,
    required this.saleRate,
    required this.total,
    required this.name,
    required this.purchaseRate
  });

  factory BillItem.fromJson(Map<String, dynamic> json) {
    return BillItem(
      itemId: json['item'],
      quantity: json['quantity'],
      saleRate: json['saleRate'].toDouble(),
      total: json['total'].toDouble(),
      name: json['name'],
      purchaseRate: json['purchaseRate'].toDouble()
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'item': itemId,
      'quantity': quantity,
      'saleRate': saleRate,
      'total': total,
      'name': name,
      'purchaseRate': purchaseRate
    };
  }
}
