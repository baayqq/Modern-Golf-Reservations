import 'package:flutter/material.dart';
import '../../app_scaffold.dart';

class PosSystemPage extends StatefulWidget {
  const PosSystemPage({super.key});

  @override
  State<PosSystemPage> createState() => _PosSystemPageState();
}

class _PosSystemPageState extends State<PosSystemPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  final TextEditingController _customerCtrl = TextEditingController();

  // Dummy categories
  final List<String> _categories = const [
    'GREEN FEE',
    'BALLS',
    'GLOVES',
    'ACCS',
    'SHOES',
    'GOLFBAG',
    'HEADWARE',
    'SOCKS',
    'APPAREL',
    'OTHERS FEE',
  ];

  String _selectedCategory = 'GREEN FEE';

  // Dummy product list
  late List<Product> _allProducts;
  List<Product> _filtered = [];
  final List<CartItem> _cart = [];

  @override
  void initState() {
    super.initState();
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

  void _removeFromCart(String productId) {
    setState(() {
      _cart.removeWhere((c) => c.product.id == productId);
    });
  }

  double get _subtotal =>
      _cart.fold(0.0, (s, e) => s + e.product.price * e.qty);

  @override
  Widget build(BuildContext context) {
    final body = Row(
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
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
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
    );
  }

  Widget _orderSummary() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12),
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
              ..._cart.map((c) => _cartTile(c)).toList(),
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
                onPressed: _cart.isEmpty ? null : () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D6EFD),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Proceed to Pay'),
              ),
            ),
          ],
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
