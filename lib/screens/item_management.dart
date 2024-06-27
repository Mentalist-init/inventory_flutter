import 'package:flutter/material.dart';
import 'package:namer_app/models/item.dart';
import 'package:namer_app/services/items.dart';
import 'package:namer_app/theme/theme.dart';
import 'package:namer_app/components/input_field.dart';

class ItemDataSource extends DataTableSource {
  final List<Item> items;
  final void Function(Item) onEdit;
  final void Function(String) onDelete;
  final BuildContext context;
  final void Function(Item, int) onAddStock;
  List<Item> filteredItems;

  ItemDataSource({
    required this.items,
    required this.onEdit,
    required this.onDelete,
    required this.onAddStock,
    required this.context,
  }) : filteredItems = List.from(items);

  void filterItems(String query) {
    final lowerQuery = query.toLowerCase();
    filteredItems
      ..clear()
      ..addAll(items.where((item) => item.name.toLowerCase().contains(lowerQuery)));
    notifyListeners();
  }

  void sortItems<T>(Comparable<T> Function(Item item) getField, bool ascending) {
    filteredItems.sort((a, b) {
      if (!ascending) {
        final Item c = a;
        a = b;
        b = c;
      }
      final Comparable<T> aValue = getField(a);
      final Comparable<T> bValue = getField(b);
      return Comparable.compare(aValue, bValue);
    });
    notifyListeners();
  }

  @override
  DataRow? getRow(int index) {
    final item = filteredItems[index];
    final bool isLowStock = item.availableQuantity < 100;
    return DataRow.byIndex(
      index: index,
      cells: [
        DataCell(Text(item.name)),
        DataCell(Text(item.brand)),
        DataCell(Text(item.availableQuantity.toString())),
        DataCell(Text(item.nameInUrdu ?? '')),
        DataCell(Text(item.miniUnit ?? '')),
        DataCell(Text(item.packaging ?? '')),
        DataCell(Text(item.purchaseRate.toString())),
        DataCell(Text(item.saleRate.toString())),
        DataCell(Text(item.minStock.toString())),
        DataCell(Text(item.location ?? '')),
        DataCell(Text(item.picture ?? '')),
        DataCell(Row(
          children: [
            IconButton(
              icon: Icon(Icons.add, color: Colors.green),
              onPressed: () => _showAddStockDialog(item),
            ),
            IconButton(
              icon: Icon(Icons.edit, color: Colors.blue),
              onPressed: () => onEdit(item),
            ),
            IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: () => onDelete(item.id),
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
          return isLowStock ? Colors.red.withOpacity(0.2) : null;
        },
      ),
    );
  }

  @override
  int get rowCount => filteredItems.length;

  @override
  bool get isRowCountApproximate => false;

  @override
  int get selectedRowCount => 0;

  void _showAddStockDialog(Item item) {
    showDialog(
      context: context,
      builder: (context) => AddStockDialog(
        item: item,
        onStockAdded: (quantity) => onAddStock(item, quantity),
      ),
    );
  }
}

class ItemsPage extends StatefulWidget {
  @override
  _ItemsPageState createState() => _ItemsPageState();
}

class _ItemsPageState extends State<ItemsPage> {
  final ItemService _itemService = ItemService();
  List<Item> _items = [];
  ItemDataSource? _dataSource;
  bool _isLoading = true;
  int _rowsPerPage = PaginatedDataTable.defaultRowsPerPage;
  String _searchQuery = '';
  int _sortColumnIndex = 0;
  bool _sortAscending = true;

  @override
  void initState() {
    super.initState();
    _fetchItems();
  }

  Future<void> _fetchItems() async {
    final items = await _itemService.getItems();
    setState(() {
      _items = items;
      _dataSource = ItemDataSource(
        items: _items,
        onEdit: _showAddEditItemDialog,
        onDelete: _deleteItem,
        onAddStock: _addStock,
        context: context,
      );
      _isLoading = false;
    });
  }

  void _showAddEditItemDialog([Item? item]) {
    showDialog(
      context: context,
      builder: (context) => AddEditItemDialog(
        item: item,
        onItemSaved: _fetchItems,
      ),
    );
  }

  Future<void> _deleteItem(String id) async {
    await _itemService.deleteItem(id);
    _fetchItems();
  }

  Future<void> _addStock(Item item, int quantity) async {
    final updatedItem = item.copyWith(availableQuantity: item.availableQuantity + quantity);
    await _itemService.updateItem(item.id, updatedItem);
    _fetchItems();
  }

  void _onSearch(String query) {
    setState(() {
      _searchQuery = query;
      _dataSource?.filterItems(query);
    });
  }

  void _onSort<T>(Comparable<T> Function(Item item) getField, int columnIndex, bool ascending) {
    setState(() {
      _sortColumnIndex = columnIndex;
      _sortAscending = ascending;
      _dataSource?.sortItems(getField, ascending);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _dataSource == null
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Center(

            child:
                Container(
                  width: MediaQuery.of(context).size.width * 0.9,
                  margin: EdgeInsets.all(16),
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.white,

                  ),
                  // width: double.infinity,
                  child: PaginatedDataTable(
                    header: Row(
                      children: [
                        Text('Items', style: AppTheme.headline6),
                        Spacer(),
                        Container(
                          width: MediaQuery.of(context).size.width * 0.15,
                          child: TextField(
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
                          onPressed: _fetchItems,
                        ),
                      ],
                    ),
                    headingRowColor: MaterialStateProperty.resolveWith<Color?>(
                          (Set<MaterialState> states) {
                        return Colors.blue.withOpacity(0.2);
                      },
                    ),
                    columns: [
                      DataColumn(
                        label: Text('Name'),
                        onSort: (columnIndex, ascending) => _onSort((item) => item.name, columnIndex, ascending),
                      ),
                      DataColumn(
                        label: Text('Brand'),
                        onSort: (columnIndex, ascending) => _onSort((item) => item.brand, columnIndex, ascending),
                      ),
                      DataColumn(
                        label: Text('Quantity'),
                        onSort: (columnIndex, ascending) => _onSort((item) => item.availableQuantity, columnIndex, ascending),
                      ),
                      DataColumn(
                        label: Text('Name in Urdu'),
                        onSort: (columnIndex, ascending) => _onSort((item) => item.nameInUrdu ?? '', columnIndex, ascending),
                      ),
                      DataColumn(
                        label: Text('Mini Unit'),
                        onSort: (columnIndex, ascending) => _onSort((item) => item.miniUnit ?? '', columnIndex, ascending),
                      ),
                      DataColumn(
                        label: Text('Packaging'),
                        onSort: (columnIndex, ascending) => _onSort((item) => item.packaging ?? '', columnIndex, ascending),
                      ),
                      DataColumn(
                        label: Text('Purchase Rate'),
                        onSort: (columnIndex, ascending) => _onSort((item) => item.purchaseRate, columnIndex, ascending),
                      ),
                      DataColumn(
                        label: Text('Sale Rate'),
                        onSort: (columnIndex, ascending) => _onSort((item) => item.saleRate, columnIndex, ascending),
                      ),
                      DataColumn(
                        label: Text('Min Stock'),
                        onSort: (columnIndex, ascending) => _onSort((item) => item.minStock, columnIndex, ascending),
                      ),
                      DataColumn(
                        label: Text('Location'),
                        onSort: (columnIndex, ascending) => _onSort((item) => item.location ?? '', columnIndex, ascending),
                      ),
                      DataColumn(
                        label: Text('Picture'),
                        onSort: (columnIndex, ascending) => _onSort((item) => item.picture ?? '', columnIndex, ascending),
                      ),
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
                    sortColumnIndex: _sortColumnIndex,
                    sortAscending: _sortAscending,
                  ),
                ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditItemDialog(),
        child: Icon(Icons.add),
      ),
    );
  }
}

class AddEditItemDialog extends StatefulWidget {
  final Item? item;
  final VoidCallback onItemSaved;

  const AddEditItemDialog({Key? key, this.item, required this.onItemSaved}) : super(key: key);

  @override
  _AddEditItemDialogState createState() => _AddEditItemDialogState();
}

class _AddEditItemDialogState extends State<AddEditItemDialog> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _brandController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _nameInUrduController = TextEditingController();
  final TextEditingController _miniUnitController = TextEditingController();
  final TextEditingController _packagingController = TextEditingController();
  final TextEditingController _purchaseRateController = TextEditingController();
  final TextEditingController _saleRateController = TextEditingController();
  final TextEditingController _minStockController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _pictureController = TextEditingController();
  final ItemService _itemService = ItemService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.item != null) {
      _nameController.text = widget.item!.name;
      _brandController.text = widget.item!.brand;
      _quantityController.text = widget.item!.availableQuantity.toString();
      _nameInUrduController.text = widget.item!.nameInUrdu!;
      _miniUnitController.text = widget.item!.miniUnit!;
      _packagingController.text = widget.item!.packaging!;
      _purchaseRateController.text = widget.item!.purchaseRate.toString();
      _saleRateController.text = widget.item!.saleRate.toString();
      _minStockController.text = widget.item!.minStock.toString();
      _locationController.text = widget.item!.location!;
      _pictureController.text = widget.item!.picture!;
    }
  }

  Future<void> _handleSave() async {
    setState(() {
      _isLoading = true;
    });

    final name = _nameController.text;
    final brand = _brandController.text;
    final quantity = int.tryParse(_quantityController.text) ?? 0;
    final nameInUrdu = _nameInUrduController.text;
    final miniUnit = _miniUnitController.text;
    final packaging = _packagingController.text;
    final purchaseRate = double.tryParse(_purchaseRateController.text) ?? 0;
    final saleRate = double.tryParse(_saleRateController.text) ?? 0;
    final minStock = int.tryParse(_minStockController.text) ?? 0;
    final location = _locationController.text;
    final picture = _pictureController.text;

    if (widget.item == null) {
      await _itemService.addItem(Item(
        id: '', // Placeholder, ID will be generated by backend
        name: name,
        brand: brand,
        availableQuantity: quantity,
        nameInUrdu: nameInUrdu,
        miniUnit: miniUnit,
        packaging: packaging,
        purchaseRate: purchaseRate,
        saleRate: saleRate,
        minStock: minStock,
        addedEditDate: DateTime.now(),
        location: location,
        picture: picture,
      ));
    } else {
      await _itemService.updateItem(widget.item!.id, Item(
        id: widget.item!.id,
        name: name,
        brand: brand,
        availableQuantity: quantity,
        nameInUrdu: nameInUrdu,
        miniUnit: miniUnit,
        packaging: packaging,
        purchaseRate: purchaseRate,
        saleRate: saleRate,
        minStock: minStock,
        addedEditDate: widget.item!.addedEditDate,
        location: location,
        picture: picture,
      ));
    }

    setState(() {
      _isLoading = false;
    });

    widget.onItemSaved();
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
              Text(widget.item == null ? 'Add Item' : 'Edit Item', style: AppTheme.headline6),
              SizedBox(height: 16),
              CustomTextField(
                controller: _nameController,
                label: 'Item Name',
              ),
              SizedBox(height: 16),
              CustomTextField(
                controller: _brandController,
                label: 'Brand',
              ),
              SizedBox(height: 16),
              CustomTextField(
                controller: _quantityController,
                label: 'Available Quantity',
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 16),
              CustomTextField(
                controller: _nameInUrduController,
                label: 'Name in Urdu',
              ),
              SizedBox(height: 16),
              CustomTextField(
                controller: _miniUnitController,
                label: 'Mini Unit',
              ),
              SizedBox(height: 16),
              CustomTextField(
                controller: _packagingController,
                label: 'Packaging',
              ),
              SizedBox(height: 16),
              CustomTextField(
                controller: _purchaseRateController,
                label: 'Purchase Rate',
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 16),
              CustomTextField(
                controller: _saleRateController,
                label: 'Sale Rate',
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 16),
              CustomTextField(
                controller: _minStockController,
                label: 'Min Stock',
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 16),
              CustomTextField(
                controller: _locationController,
                label: 'Location',
              ),
              SizedBox(height: 16),
              CustomTextField(
                controller: _pictureController,
                label: 'Picture URL',
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

class AddStockDialog extends StatefulWidget {
  final Item item;
  final void Function(int) onStockAdded;

  const AddStockDialog({required this.item, required this.onStockAdded, Key? key}) : super(key: key);

  @override
  _AddStockDialogState createState() => _AddStockDialogState();
}

class _AddStockDialogState extends State<AddStockDialog> {
  final TextEditingController _quantityController = TextEditingController();

  void _handleAddStock() {
    final quantity = int.tryParse(_quantityController.text) ?? 0;
    widget.onStockAdded(quantity);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Add Stock to ${widget.item.name}'),
      content: TextField(
        controller: _quantityController,
        decoration: InputDecoration(labelText: 'Quantity'),
        keyboardType: TextInputType.number,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _handleAddStock,
          child: Text('Add Stock'),
        ),
      ],
    );
  }
}
