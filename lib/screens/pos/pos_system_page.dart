import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app_scaffold.dart';
import '../../services/invoice_repository.dart';
import '../../router.dart' show AppRoute;

class PosSystemPage extends StatefulWidget {
  const PosSystemPage({super.key});

  @override
  State<PosSystemPage> createState() => _PosSystemPageState();
}

class _PosSystemPageState extends State<PosSystemPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  final TextEditingController _customerCtrl = TextEditingController();
  // Manual item inputs (Green Fee)
  final TextEditingController _itemNameCtrl = TextEditingController(text: 'GREEN FEE');
  final TextEditingController _itemQtyCtrl = TextEditingController(text: '1');
  final TextEditingController _itemPriceCtrl = TextEditingController(text: '750000');

  // Kategori yang digunakan
  final List<String> _categories = const [
    'GREEN FEE',
  ];

  String _selectedCategory = 'GREEN FEE';

  // Dummy product list
  late List<Product> _allProducts;
  List<Product> _filtered = [];
  final List<CartItem> _cart = [];

  // SQLite repo for invoices
  final InvoiceRepository _invoiceRepo = InvoiceRepository();

  @override
  void initState() {
    super.initState();
    _initDb();
    _allProducts = List.generate(20, (i) {
      final names = [
        'SCORING ADMINISTRATION',
        'FORE CADDY',
        'Deductable Insurance Charge',
        'Extra Caddy',
        'Practice Balls',
        'Premium Gloves',
        'Divot Tool',
        'Spikeless Shoes',
        'Cart Fee',
        'Locker Fee',
      ];
      final cats = _categories;
      return Product(
        id: 'P$i',
        name: names[i % names.length],
        price: [
          750000,
          300000,
          1000000,
          300000,
          100000,
          250000,
          50000,
          150000,
          200000,
          50000,
        ][i % 10].toDouble(),
        stock: [19, 18, 299, 500, 120, 60, 999, 42, 75, 31][i % 10],
        category: cats[i % cats.length],
        // emblem placeholder
        image: Icons.verified, // using an icon as placeholder
      );
    });
    _applyFilter();
  }

  Future<void> _initDb() async {
    await _invoiceRepo.init();
  }

  void _applyFilter() {
    final q = _searchCtrl.text.trim().toLowerCase();
    setState(() {
      _filtered = _allProducts.where((p) {
        final catOk = p.category == _selectedCategory;
        final queryOk =
            q.isEmpty ||
            p.name.toLowerCase().contains(q) ||
            p.id.toLowerCase().contains(q);
        return catOk && queryOk;
      }).toList();
    });
  }

  void _addToCart(Product p) {
    final idx = _cart.indexWhere((c) => c.product.id == p.id);
    setState(() {
      if (idx >= 0) {
        _cart[idx] = _cart[idx].copyWith(qty: _cart[idx].qty + 1);
      } else {
        _cart.add(CartItem(product: p, qty: 1));
      }
    });
  }

  void _addManualItem() {
    final name = _itemNameCtrl.text.trim();
    final qty = int.tryParse(_itemQtyCtrl.text.trim()) ?? 0;
    final price = double.tryParse(_itemPriceCtrl.text.trim()) ?? 0.0;
    if (name.isEmpty || qty <= 0 || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Isi nama item, qty (>0), dan harga (>0)')),
      );
      return;
    }
    final id = 'M${DateTime.now().microsecondsSinceEpoch}';
    final p = Product(
      id: id,
      name: name,
      price: price,
      stock: 9999,
      category: 'GREEN FEE',
      image: Icons.flag,
    );
    final existingIdx = _cart.indexWhere((c) => c.product.name == name && (c.product.price - price).abs() < 0.0001);
    setState(() {
      if (existingIdx >= 0) {
        _cart[existingIdx] = _cart[existingIdx].copyWith(qty: _cart[existingIdx].qty + qty);
      } else {
        _cart.add(CartItem(product: p, qty: qty));
      }
    });
  }

  void _removeFromCart(String productId) {
    setState(() {
      _cart.removeWhere((c) => c.product.id == productId);
    });
  }

  double get _subtotal =>
      _cart.fold(0.0, (s, e) => s + e.product.price * e.qty);

  Future<void> _saveTransaction() async {
    if (_cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Keranjang masih kosong')),
      );
      return;
    }
    final customer = _customerCtrl.text.trim().isEmpty ? 'Walk-in' : _customerCtrl.text.trim();
    final items = _cart
        .map((c) => InvoiceItemInput(name: c.product.name, qty: c.qty, price: c.product.price))
        .toList();
    await _invoiceRepo.createInvoice(customer: customer, items: items);
    if (!mounted) return;
    // Optional: clear cart after save
    setState(() {
      _cart.clear();
    });
    GoRouter.of(context).goNamed(AppRoute.invoice.name);
  }

  @override
  Widget build(BuildContext context) {
    final body = LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 900;
        final content = isNarrow
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _categoriesSection(),
                  const SizedBox(height: 12),
                  _productsHeader(),
                  const SizedBox(height: 8),
                  _productGrid(),
                  const SizedBox(height: 12),
                  _orderSummary(),
                ],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left content
                  Expanded(
                    child: Column(
                      children: [
                        _categoriesSection(),
                        const SizedBox(height: 12),
                        _productsHeader(),
                        const SizedBox(height: 8),
                        _productGrid(),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Right sidebar: Order Summary
                  SizedBox(width: 320, child: _orderSummary()),
                ],
              );

        // Bungkus dengan SingleChildScrollView untuk mencegah overflow vertikal
        return SingleChildScrollView(child: Padding(
          padding: const EdgeInsets.all(12),
          child: content,
        ));
      },
    );

    return AppScaffold(title: 'POS System', body: body);
  }

  Widget _categoriesSection() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF0D6EFD),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(8),
              ),
            ),
            child: const Text(
              'Categories',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _categories.map((c) {
                  final selected = _selectedCategory == c;
                  return ChoiceChip(
                    selected: selected,
                    onSelected: (_) {
                      setState(() {
                        _selectedCategory = c;
                      });
                      _applyFilter();
                    },
                    label: Text(
                      c,
                      style: TextStyle(
                        color: selected
                            ? Colors.white
                            : const Color(0xFF0D6EFD),
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                    selectedColor: const Color(0xFF0D6EFD),
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFF0D6EFD)),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _productsHeader() {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF6C757D),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'Products / Services',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SizedBox(
            height: 42,
            child: TextField(
              controller: _searchCtrl,
              onChanged: (_) => _applyFilter(),
              decoration: InputDecoration(
                hintText: 'Search...',
                prefixIcon: const Icon(Icons.search),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _productGrid() {
    // 4 columns on wide screens, 2 on narrow
    final width = MediaQuery.of(context).size.width;
    final cols = width >= 1100 ? 4 : 2;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.5, // Tinggi container untuk scrolling
          child: GridView.builder(
            shrinkWrap: false,
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: _filtered.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.0,
          ),
          itemBuilder: (context, index) {
            final p = _filtered[index];
            return InkWell(
              onTap: () => _addToCart(p),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFDEE2E6)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Center(
                        child: Icon(
                          p.image,
                          size: 80,
                          color: Colors.brown.shade300,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${p.name} - Rp. ${p.price.toStringAsFixed(0)}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Stock: ${p.stock}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            );
          },
          ),
        ),
      ),
    );
  }

  Widget _orderSummary() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: SingleChildScrollView(
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF198754),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'Order Summary',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text('Customer'),
            const SizedBox(height: 6),
            TextField(
              controller: _customerCtrl,
              decoration: const InputDecoration(
                hintText: 'Enter customer name...',
              ),
            ),
            const SizedBox(height: 12),
            const Divider(),
            const Text('Tambah Item (Green Fee)'),
            const SizedBox(height: 6),
            TextField(
              controller: _itemNameCtrl,
              decoration: const InputDecoration(
                hintText: 'Nama item... (misal: GREEN FEE)',
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _itemQtyCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(hintText: 'Qty'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _itemPriceCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(hintText: 'Harga'),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 42,
                  child: ElevatedButton(
                    onPressed: _addManualItem,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF198754),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Tambah'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            // Cart list
            if (_cart.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'No items yet',
                  style: TextStyle(color: Colors.grey.shade600),
                  textAlign: TextAlign.center,
                ),
              )
            else
              ..._cart.map((c) => _cartTile(c)),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Subtotal:',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                Text('Rp. ${_subtotal.toStringAsFixed(2)}'),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 42,
              child: ElevatedButton(
                onPressed: _cart.isEmpty ? null : _saveTransaction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D6EFD),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Simpan Transaksi'),
              ),
            ),
          ],
          ),
        ),
      ),
    );
  }

  Widget _cartTile(CartItem c) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${c.product.name} x${c.qty}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text('Rp. ${(c.product.price * c.qty).toStringAsFixed(0)}'),
          IconButton(
            tooltip: 'Remove',
            onPressed: () => _removeFromCart(c.product.id),
            icon: const Icon(Icons.close, size: 18),
          ),
        ],
      ),
    );
  }
}

class Product {
  final String id;
  final String name;
  final double price;
  final int stock;
  final String category;
  final IconData image;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.stock,
    required this.category,
    required this.image,
  });
}

class CartItem {
  final Product product;
  final int qty;

  CartItem({required this.product, required this.qty});

  CartItem copyWith({Product? product, int? qty}) =>
      CartItem(product: product ?? this.product, qty: qty ?? this.qty);
}
