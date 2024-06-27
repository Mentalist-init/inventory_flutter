import 'package:flutter/material.dart';
import 'package:namer_app/models/customer.dart';
import 'package:namer_app/services/customers.dart';
import 'package:namer_app/theme/theme.dart';
import 'package:namer_app/components/input_field.dart';

class CustomerDataSource extends DataTableSource {
  final List<Customer> customers;
  final void Function(Customer) onEdit;
  final void Function(String) onDelete;
  List<Customer> filteredCustomers;

  CustomerDataSource({
    required this.customers,
    required this.onEdit,
    required this.onDelete,
  }) : filteredCustomers = List.from(customers);

  void filterCustomers(String query) {
    final lowerQuery = query.toLowerCase();
    filteredCustomers = customers.where((customer) {
      return customer.name.toLowerCase().contains(lowerQuery);
    }).toList();
    notifyListeners();
  }

  @override
  DataRow? getRow(int index) {
    final customer = filteredCustomers[index];
    return DataRow.byIndex(
      index: index,
      cells: [
        DataCell(Text(customer.name)),
        DataCell(Text(customer.phoneNumber)),
        DataCell(Text(customer.address)),
        DataCell(Text(customer.tour)),
        DataCell(Text('\$${customer.balance.toStringAsFixed(2)}')),
        DataCell(Row(
          children: [
            IconButton(
              icon: Icon(Icons.edit, color: Colors.blue),
              onPressed: () => onEdit(customer),
            ),
            IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: () => onDelete(customer.id),
            ),
          ],
        )),
      ],
      onSelectChanged: (selected) {
        // Optional: Add any onSelect behavior
      },
      color: MaterialStateProperty.resolveWith<Color?>(
            (Set<MaterialState> states) {
          if (states.contains(MaterialState.hovered)) {
            return Colors.blue.withOpacity(0.1);
          }
          return null;
        },
      ),
    );
  }

  @override
  int get rowCount => filteredCustomers.length;

  @override
  bool get isRowCountApproximate => false;

  @override
  int get selectedRowCount => 0;
}

class CustomerPage extends StatefulWidget {
  @override
  _CustomerPageState createState() => _CustomerPageState();
}

class _CustomerPageState extends State<CustomerPage> {
  final CustomerService _customerService = CustomerService();
  List<Customer> _customers = [];
  CustomerDataSource? _dataSource;
  bool _isLoading = true;
  int _rowsPerPage = PaginatedDataTable.defaultRowsPerPage;
  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchCustomers();
  }

  Future<void> _fetchCustomers() async {
    final customers = await _customerService.getCustomers();
    setState(() {
      _customers = customers;
      _dataSource = CustomerDataSource(
        customers: _customers,
        onEdit: _showAddEditCustomerDialog,
        onDelete: _deleteCustomer,
      );
      _isLoading = false;
    });
  }

  void _showAddEditCustomerDialog([Customer? customer]) {
    showDialog(
      context: context,
      builder: (context) => AddEditCustomerDialog(
        customer: customer,
        onCustomerSaved: _fetchCustomers,
      ),
    );
  }

  Future<void> _deleteCustomer(String id) async {
    await _customerService.deleteCustomer(id);
    _fetchCustomers();
  }

  void _onSearch(String query) {
    _dataSource?.filterCustomers(query);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Center(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            margin: EdgeInsets.all(16),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              boxShadow: [BoxShadow(color: Colors.grey, blurRadius: 5)],
              color: Colors.white,
            ),
            child: PaginatedDataTable(
              header: Row(
                children: [
                  Text('Customer List', style: AppTheme.headline6),
                  Spacer(),
                  Container(
                    width: MediaQuery.of(context).size.width * 0.15,
                    child: TextField(
                      controller: _searchController,
                      onChanged: _onSearch,
                      decoration: InputDecoration(
                        labelText: 'Search',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.refresh),
                    onPressed: _fetchCustomers,
                  ),
                ],
              ),
              headingRowColor: MaterialStateProperty.resolveWith<Color?>(
                    (Set<MaterialState> states) {
                  return Colors.blue.withOpacity(0.2);
                },
              ),
              columns: [
                DataColumn(label: Text('Name')),
                DataColumn(label: Text('Phone')),
                DataColumn(label: Text('Address')),
                DataColumn(label: Text('Tour')),
                DataColumn(label: Text('Balance')),
                DataColumn(label: Text('Actions')),
              ],
              source: _dataSource!,
              rowsPerPage: _rowsPerPage,
              onRowsPerPageChanged: (value) {
                setState(() {
                  _rowsPerPage = value!;
                });
              },
              availableRowsPerPage: [5, 10, 20, 30],
              columnSpacing: 20,
              horizontalMargin: 20,
              showCheckboxColumn: false,
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditCustomerDialog(),
        child: Icon(Icons.add),
      ),
    );
  }
}

class AddEditCustomerDialog extends StatefulWidget {
  final Customer? customer;
  final VoidCallback onCustomerSaved;

  const AddEditCustomerDialog({Key? key, this.customer, required this.onCustomerSaved}) : super(key: key);

  @override
  _AddEditCustomerDialogState createState() => _AddEditCustomerDialogState();
}

class _AddEditCustomerDialogState extends State<AddEditCustomerDialog> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _tourController = TextEditingController();
  final TextEditingController _balanceController = TextEditingController(text: '0');
  final CustomerService _customerService = CustomerService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.customer != null) {
      _nameController.text = widget.customer!.name;
      _phoneNumberController.text = widget.customer!.phoneNumber;
      _addressController.text = widget.customer!.address;
      _tourController.text = widget.customer!.tour;
      _balanceController.text = widget.customer!.balance.toString();
    }
  }

  Future<void> _handleSave() async {
    setState(() {
      _isLoading = true;
    });

    final name = _nameController.text;
    final phoneNumber = _phoneNumberController.text;
    final address = _addressController.text;
    final tour = _tourController.text;
    final balance = double.parse(_balanceController.text);

    final customer = Customer(
      id: widget.customer?.id ?? '',
      name: name,
      phoneNumber: phoneNumber,
      address: address,
      tour: tour,
      balance: widget.customer == null ? 0 : balance,
    );

    if (widget.customer == null) {
      await _customerService.addCustomer(customer);
    } else {
      await _customerService.updateCustomer(widget.customer!.id, customer);
    }

    setState(() {
      _isLoading = false;
    });

    widget.onCustomerSaved();
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
              Text(widget.customer == null ? 'Add Customer' : 'Edit Customer', style: AppTheme.headline6),
              SizedBox(height: 16),
              CustomTextField(controller: _nameController, label: 'Name'),
              SizedBox(height: 16),
              CustomTextField(controller: _phoneNumberController, label: 'Phone Number'),
              SizedBox(height: 16),
              SizedBox(
                width: 400,
                child: TextField(
                  controller: _addressController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Address',
                  ),
                  maxLines: 3,
                ),
              ),
              SizedBox(height: 16),
              SizedBox(height: 16),
              CustomTextField(controller: _tourController, label: 'Tour'),
              SizedBox(height: 16),
              CustomTextField(controller: _balanceController, label: 'Balance', keyboardType: TextInputType.number),
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
