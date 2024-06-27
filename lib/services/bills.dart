import 'package:namer_app/models/bills.dart';
import 'package:namer_app/models/customer.dart';
import 'package:namer_app/models/item.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class BillService {
  final String apiUrl = 'http://localhost:3000';

  Future<List<Bill>> getBills() async {
    final response = await http.get(Uri.parse('$apiUrl/bills'));
    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((bill) => Bill.fromJson(bill)).toList();
    } else {
      throw Exception('Failed to load bills');
    }
  }

  Future<void> addBill(Bill bill) async {
    final response = await http.post(
      Uri.parse('$apiUrl/bills'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(bill.toJson()),
    );
    if (response.statusCode != 201) {
      throw Exception('Failed to add bill');
    }
  }

  Future<void> updateBill(String id, Bill bill) async {
    final response = await http.put(
      Uri.parse('$apiUrl/bills/$id'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(bill.toJson()),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update bill');
    }
  }

  Future<void> deleteBill(String id) async {
    final response = await http.delete(Uri.parse('$apiUrl/bills/$id'));
    if (response.statusCode != 200) {
      throw Exception('Failed to delete bill');
    }
  }

  Future<List<Customer>> getCustomers() async {
    final response = await http.get(Uri.parse('$apiUrl/customers'));
    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((customer) => Customer.fromJson(customer)).toList();
    } else {
      throw Exception('Failed to load customers');
    }
  }

  Future<Customer> getCustomerById(String id) async {
    final response = await http.get(Uri.parse('$apiUrl/customers/$id'));
    if (response.statusCode == 200) {
      return Customer.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load customer');
    }
  }

  Future<List<Item>> getItems() async {
    final response = await http.get(Uri.parse('$apiUrl/items'));
    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((item) => Item.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load items');
    }
  }

  Future<void> updateCustomerBalance(String customerId, double newBalance) async {
    final response = await http.put(
      Uri.parse('$apiUrl/customers/$customerId/balance'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'balance': newBalance}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update customer balance');
    }
  }
}

