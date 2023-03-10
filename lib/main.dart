import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  await Hive.openBox('shopping_box');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'fauzipayy',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();

  List<Map<String, dynamic>> _items = [];

  final _shoppingBox = Hive.box('shopping_box');
  @override
  void initState() {
    super.initState();
    _refreshItems();
  }

  // refresh data
  void _refreshItems() {
    final data = _shoppingBox.keys.map((key) {
      final item = _shoppingBox.get(key);
      return {
        "key": key,
        "name": item["name"],
        "quantity": item['quantity'],
      };
    }).toList();

    setState(() {
      _items = data.reversed.toList();
      print(_items.length);
    });
  }

  // create new item
  Future<void> _createItem(Map<String, dynamic> newItem) async {
    await _shoppingBox.add(newItem);
    _refreshItems();
  }

  // update item
  Future<void> _updateItem(int itemKey, Map<String, dynamic> item) async {
    await _shoppingBox.put(itemKey, item);
    _refreshItems();
  }

  // delete item
  Future<void> _deleteItem(int itemKey) async {
    await _shoppingBox.delete(itemKey);
    _refreshItems();

    // display notif
    // ignore: use_build_context_synchronously
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("An item has been deleted"),
      ),
    );
  }

  void _showForm(BuildContext ctx, int? itemKey, String? actionText) async {
    if (itemKey != null && actionText == "update") {
      final existingItem =
          _items.firstWhere((element) => element['key'] == itemKey);

      _nameController.text = existingItem['name'];
      _quantityController.text = existingItem['quantity'];
    } else if (itemKey != null && actionText == "view") {
      final existingItem =
          _items.firstWhere((element) => element['key'] == itemKey);

      _nameController.text = existingItem['name'];
      _quantityController.text = existingItem['quantity'];
    } else {
      actionText = "create";
      _nameController.text = '';
      _quantityController.text = '';
    }

    showModalBottomSheet(
      context: ctx,
      builder: (_) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          top: 15,
          left: 15,
          right: 15,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              TextField(
                controller: _nameController,
                readOnly: actionText != "view" ? false : true,
                decoration: const InputDecoration(hintText: 'Name'),
              ),
              const SizedBox(
                height: 10,
              ),
              TextField(
                controller: _quantityController,
                readOnly: actionText != "view" ? false : true,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(hintText: 'Quantity'),
              ),
              const SizedBox(
                height: 20,
              ),
              actionText != "view"
                  ? ElevatedButton(
                      onPressed: () async {
                        if (itemKey == null) {
                          _createItem({
                            "name": _nameController.text,
                            "quantity": _quantityController.text,
                          });
                        }

                        if (itemKey != null) {
                          _updateItem(itemKey, {
                            'name': _nameController.text.trim(),
                            'quantity': _quantityController.text.trim(),
                          });
                        }

                        // clear the text fields
                        _nameController.text = '';
                        _quantityController.text = '';

                        Navigator.of(context).pop();
                      },
                      child: actionText == "create"
                          ? const Text('Create New')
                          : const Text("Update Data"),
                    )
                  : const SizedBox(),
              const SizedBox(
                height: 15,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Hive"),
      ),
      body: ListView.builder(
        itemCount: _items.length,
        itemBuilder: (_, index) {
          final currentItem = _items[index];
          return Card(
            color: Colors.orange.shade100,
            margin: const EdgeInsets.all(10),
            elevation: 3,
            child: ListTile(
              title: Text(currentItem['name']),
              subtitle: Text(currentItem['quantity'].toString()),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () {
                      _showForm(context, currentItem['key'], "update");
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.remove_red_eye),
                    onPressed: () {
                      _showForm(context, currentItem['key'], "view");
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () {
                      _deleteItem(currentItem['key']);
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(context, null, null),
        child: const Icon(Icons.add),
      ),
    );
  }
}
