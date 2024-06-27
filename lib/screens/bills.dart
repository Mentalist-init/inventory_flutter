import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:namer_app/models/bills.dart';
import 'package:namer_app/models/customer.dart';
import 'package:namer_app/models/item.dart';
import 'package:namer_app/services/bills.dart';
import 'package:namer_app/theme/theme.dart';
import 'package:namer_app/components/input_field.dart';

class BillsPage extends StatefulWidget {
  @override
  _BillsPageState createState() => _BillsPageState();
}

class _BillsPageState extends State<BillsPage> {
  final BillService _billService = BillService();
  List<Bill> _bills = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchBills();
  }

  Future<void> _fetchBills() async {
    final bills = await _billService.getBills();
    setState(() {
      _bills = bills;
      _isLoading = false;
    });
  }

  void _showAddEditBillDialog({Bill? bill}) {
    showDialog(
      context: context,
      builder: (context) => AddEditBillDialog(
        bill: bill,
        onBillSaved: _fetchBills,
      ),
    );
  }

  Future<void> _deleteBill(String id) async {
    await _billService.deleteBill(id);
    _fetchBills();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: AppTheme.inputDecoration('Search bills...'),
              onChanged: (value) {
                // Implement search logic here
              },
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _bills.length,
              itemBuilder: (context, index) {
                final bill = _bills[index];
                return Card(
                  margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: ListTile(
                    title: Text('Bill ID: ${bill.id}', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Total Amount: \$${bill.totalAmount}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _showAddEditBillDialog(bill: bill),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteBill(bill.id),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditBillDialog(),
        child: Icon(Icons.add),
      ),
    );
  }
}

class AddEditBillDialog extends StatefulWidget {
  final Bill? bill;
  final VoidCallback onBillSaved;

  const AddEditBillDialog({Key? key, this.bill, required this.onBillSaved}) : super(key: key);

  @override
  _AddEditBillDialogState createState() => _AddEditBillDialogState();
}

class _AddEditBillDialogState extends State<AddEditBillDialog> {
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _promiseDateController = TextEditingController();
  final TextEditingController _totalAmountController = TextEditingController();
  final TextEditingController _balanceController = TextEditingController();
  final TextEditingController _customerController = TextEditingController();
  final TextEditingController _itemController = TextEditingController();
  final BillService _billService = BillService();
  bool _isLoading = false;

  List<Customer> _customers = [];
  List<Item> _items = [];
  String? _selectedCustomerId;
  Customer? _selectedCustomer;
  List<BillItem> _selectedItems = [];
  String _selectedStatus = 'Non Completed';
  double _totalAmount = 0;

  @override
  void initState() {
    super.initState();
    _fetchItems();
    _fetchCustomers();
    if (widget.bill != null) {
      _selectedCustomerId = widget.bill!.customerId;
      _dateController.text = widget.bill!.date;
      _selectedItems = widget.bill!.items;
      _totalAmountController.text = widget.bill!.totalAmount.toString();
      _selectedStatus = widget.bill!.status;
      _calculateTotalAmount();
      _fetchCustomerDetails();
    }
  }

  Future<void> _fetchCustomers() async {
    final customers = await _billService.getCustomers();
    setState(() {
      _customers = customers;
    });
  }

  Future<void> _fetchItems() async {
    final items = await _billService.getItems();
    setState(() {
      _items = items;
    });
  }

  Future<void> _fetchCustomerDetails() async {
    if (_selectedCustomerId != null) {
      final customer = await _billService.getCustomerById(_selectedCustomerId!);
      setState(() {
        _selectedCustomer = customer;
        _balanceController.text = customer.balance.toString();
      });
    }
  }

  void _addItemToBill(Item item) {
    if (item.availableQuantity > 0) {
      setState(() {
        _selectedItems.add(BillItem(
          itemId: item.id,
          name: item.name,
          quantity: 1,
          saleRate: item.saleRate,
          purchaseRate: item.purchaseRate,
          total: item.saleRate,
        ));
        _calculateTotalAmount();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Selected item is out of stock')),
      );
    }
  }

  void _removeItemFromBill(BillItem item) {
    setState(() {
      _selectedItems.remove(item);
      _calculateTotalAmount();
    });
  }

  void _updateItemQuantity(BillItem item, int quantity) {
    if (quantity <= _items.firstWhere((i) => i.id == item.itemId).availableQuantity) {
      setState(() {
        item.quantity = quantity;
        item.total = item.saleRate * quantity;
        _calculateTotalAmount();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Quantity exceeds available stock')),
      );
    }
  }

  void _updateItemRateForBill(BillItem item, double saleRate) {
    setState(() {
      item.saleRate = saleRate;
      item.total = item.saleRate * item.quantity;
      _calculateTotalAmount();
    });
  }

  void _calculateTotalAmount() {
    double total = 0;
    for (var item in _selectedItems) {
      total += item.total;
    }
    setState(() {
      _totalAmount = total;
      _totalAmountController.text = _totalAmount.toStringAsFixed(2);
    });
  }

  Future<void> _handleSave() async {
    setState(() {
      _isLoading = true;
    });

    final date = _dateController.text;
    final promiseDate = _promiseDateController.text;

    if (widget.bill == null) {
      await _billService.addBill(Bill(
        id: '',
        customerId: _selectedCustomerId!,
        date: date,
        items: _selectedItems,
        totalAmount: _totalAmount,
        status: _selectedStatus,
      ));
    } else {
      await _billService.updateBill(widget.bill!.id, Bill(
        id: widget.bill!.id,
        customerId: _selectedCustomerId!,
        date: date,
        items: _selectedItems,
        totalAmount: _totalAmount,
        status: _selectedStatus,
      ));
    }

    await _billService.updateCustomerBalance(_selectedCustomerId!, _selectedCustomer!.balance + _totalAmount);

    setState(() {
      _isLoading = false;
    });

    widget.onBillSaved();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Container(
        padding: EdgeInsets.all(16),
        child: _isLoading
            ? Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.bill == null ? 'Add Bill' : 'Edit Bill', style: AppTheme.headline6),
              SizedBox(height: 16),
              SizedBox(
                width: 400,
                child: TypeAheadFormField<Customer>(
                  textFieldConfiguration: TextFieldConfiguration(
                    controller: _customerController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Customer',
                    ),
                  ),
                  suggestionsCallback: (pattern) {
                    return _customers.where((customer) => customer.name.toLowerCase().contains(pattern.toLowerCase()) || customer.id.contains(pattern));
                  },
                  itemBuilder: (context, Customer suggestion) {
                    return ListTile(
                      title: Text(suggestion.name),
                      subtitle: Text(suggestion.id),
                    );
                  },
                  onSuggestionSelected: (Customer suggestion) {
                    setState(() {
                      _selectedCustomerId = suggestion.id;
                      _selectedCustomer = suggestion;
                      _customerController.text = "${suggestion.id} - ${suggestion.name}";
                      _balanceController.text = suggestion.balance.toString();
                    });
                  },
                  noItemsFoundBuilder: (context) => Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('No customers found.'),
                  ),
                ),
              ),
              SizedBox(height: 16),
              SizedBox(
                width: 400,
                child: TextField(
                  controller: _balanceController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Balance',
                  ),
                  readOnly: true,
                ),
              ),
              SizedBox(height: 16),
              SizedBox(
                width: 400,
                child: TextField(
                  controller: _dateController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Date',
                  ),
                  readOnly: true,
                  onTap: () async {
                    DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2101),
                    );

                    if (pickedDate != null) {
                      setState(() {
                        _dateController.text = "${pickedDate.toLocal()}".split(' ')[0];
                      });
                    }
                  },
                ),
              ),
              SizedBox(height: 16),
              SizedBox(
                width: 400,
                child: TypeAheadFormField<Item>(
                  textFieldConfiguration: TextFieldConfiguration(
                    controller: _itemController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Items',
                    ),
                  ),
                  suggestionsCallback: (pattern) {
                    return _items.where((item) => item.name.toLowerCase().contains(pattern.toLowerCase()));
                  },
                  itemBuilder: (context, Item suggestion) {
                    return ListTile(
                      title: Text(suggestion.name),
                    );
                  },
                  onSuggestionSelected: (Item suggestion) {
                    _addItemToBill(suggestion);
                    _itemController.clear();
                  },
                  noItemsFoundBuilder: (context) => Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('No items found.'),
                  ),
                ),
              ),
              SizedBox(height: 16),
              Column(
                children: _selectedItems.map((item) {
                  return SizedBox(
                    width: 400,
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(item.name,
                              style: TextStyle(fontWeight: FontWeight.bold,fontSize: 16),
                            ),
                            // Text('Rate: \$${item.saleRate.toStringAsFixed(2)}',
                            //   style: TextStyle(fontSize: 16),
                            // ),
                          ],
                        ),
                        SizedBox(height: 15),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            SizedBox(
                              width: 80,
                              child: TextField(
                                controller: TextEditingController(text: item.quantity.toString()),
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(),
                                  labelText: 'Qty',
                                ),
                                onChanged: (value) {
                                  int? quantity = int.tryParse(value);
                                  if (quantity != null && quantity > 0) {
                                    _updateItemQuantity(item, quantity);
                                  }
                                },
                              ),
                            ),
                            SizedBox(
                              width: 100,
                              child: TextField(
                                controller: TextEditingController(text: item.saleRate.toStringAsFixed(2)),
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(),
                                  labelText: 'Sale Rate',
                                ),
                                onChanged: (value) {
                                  double? saleRate = double.tryParse(value);
                                  if (saleRate != null && saleRate > 0) {
                                    _updateItemRateForBill(item, saleRate);
                                  }
                                },
                              ),
                            ),
                            SizedBox(
                              width: 100,
                              child: TextField(
                                controller: TextEditingController(text: item.purchaseRate.toString()),
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(),
                                  labelText: 'Purchase Rate',
                                ),
                                onChanged: (value) {
                                  double? purchaseRate = double.tryParse(value);
                                  if (purchaseRate != null && purchaseRate > 0) {
                                    _updateItemRateForBill(item, item.saleRate);
                                  }
                                },
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _removeItemFromBill(item),
                            ),
                          ],
                        ),
                        SizedBox(height: 15),

                      ],
                    ),
                  );
                }).toList(),
              ),
              SizedBox(height: 16),
              CustomTextField(
                controller: _totalAmountController,
                label: 'Total Amount',
                keyboardType: TextInputType.number,
                readOnly: true,
              ),
              SizedBox(height: 16),
              SizedBox(
                width: 400,
                child: DropdownButtonFormField<String>(
                  value: _selectedStatus,
                  hint: Text('Select Status'),
                  onChanged: (value) {
                    setState(() {
                      _selectedStatus = value!;
                    });
                  },
                  items: ['Completed', 'Non Completed'].map((status) {
                    return DropdownMenuItem(
                      value: status,
                      child: Text(status),
                    );
                  }).toList(),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Status',
                  ),
                ),
              ),
              SizedBox(height: 16),
              _isLoading
                  ? CircularProgressIndicator()
                  : ElevatedButton(
                onPressed: _handleSave,
                style: AppTheme.elevatedButtonStyle,
                child: Text('Save', style: AppTheme.button),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
