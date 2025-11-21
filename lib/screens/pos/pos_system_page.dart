import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app_scaffold.dart';
import '../../services/invoice_repository.dart';
import '../../router.dart' show AppRoute;
import '../../main.dart' show MyAppStateBridge;
import '../../config/fees.dart';
import 'package:modern_golf_reservations/utils/currency.dart';
import '../../services/tee_time_repository.dart';
import '../../models/tee_time_model.dart';

/// POS System main page. If opened via redirect, optional `from` tells
/// which page triggered the redirect (e.g. 'invoice' or 'payments').
class PosSystemPage extends StatefulWidget {
  // Halaman POS sebagai pusat transaksi.
  // from: konteks asal redirect (invoice/payments/teeManage)
  // initialCustomer & initialQty: nilai awal dari halaman Manage Reservation.
  final String? from;
  final String? initialCustomer;
  final int? initialQty;
  const PosSystemPage({super.key, this.from, this.initialCustomer, this.initialQty});

  @override
  State<PosSystemPage> createState() => _PosSystemPageState();
}

class _PosSystemPageState extends State<PosSystemPage> {
  // Flag to ensure database is initialized before saving
  bool _dbReady = false;
  // Prevent double-submit causing duplicate invoices
  bool _saving = false;
  final TextEditingController _searchCtrl = TextEditingController();
  final TextEditingController _customerCtrl = TextEditingController();
  // Manual item inputs dihapus (tidak digunakan lagi).

  // Daftar harga sewa: dipisahkan WEEKDAY & WEEKEND (bukan barang belanja).
  late List<Product> _weekdayFees;
  late List<Product> _weekendFees;
  // Tab kategori seperti UI sebelumnya
  final List<String> _categories = const ['WEEKDAY', 'WEEKEND'];
  String _selectedCategory = 'WEEKDAY';
  List<Product> _filtered = [];
  final List<CartItem> _cart = [];

  // SQLite repo for invoices
  final InvoiceRepository _invoiceRepo = InvoiceRepository();
  // Repo untuk mencari booking/pemain
  final TeeTimeRepository _teeRepo = TeeTimeRepository();
  // Tidak ada auto SEWA LAPANGAN dari booking. Kasir akan input manual.

  @override
  void initState() {
    super.initState();
    _initDb();
    // Tandai bahwa user telah memasuki POS pada sesi ini.
    MyAppStateBridge.posEnteredNotifier.value = true;
    // Jika halaman ini dibuka dari redirect ketika mencoba akses Invoice/Payments,
    // tampilkan pesan bantuan ringan agar alur jelas.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final from = widget.from;
      if (from == 'invoice' || from == 'payments') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Silakan gunakan menu POS terlebih dahulu, lalu lanjut ke ${from == 'invoice' ? 'Invoice' : 'Payment History'}',
            ),
          ),
        );
      }
    });
    // Inisialisasi list harga sewa (POS mengganti list barang menjadi fee):
    _weekdayFees = [
      Product(
        id: 'WD-1',
        name: 'Member Fee',
        price: 1600000,
        stock: 9999,
        category: 'WEEKDAY',
        image: Icons.attach_money,
      ),
      Product(
        id: 'WD-2',
        name: 'Visitor Fee',
        price: 3000000,
        stock: 9999,
        category: 'WEEKDAY',
        image: Icons.attach_money,
      ),
      Product(
        id: 'WD-3',
        name: 'Caddy Fee',
        price: 300000,
        stock: 9999,
        category: 'WEEKDAY',
        image: Icons.attach_money,
      ),
      Product(
        id: 'WD-4',
        name: 'Buggy Fee',
        price: 300000,
        stock: 9999,
        category: 'WEEKDAY',
        image: Icons.attach_money,
      ),
    ];
    _weekendFees = [
      Product(
        id: 'WE-1',
        name: 'Member Fee',
        price: 3500000,
        stock: 9999,
        category: 'WEEKEND',
        image: Icons.attach_money,
      ),
      Product(
        id: 'WE-2',
        name: 'Visitor Fee',
        price: 5000000,
        stock: 9999,
        category: 'WEEKEND',
        image: Icons.attach_money,
      ),
      Product(
        id: 'WE-3',
        name: 'Caddy Fee',
        price: 300000,
        stock: 9999,
        category: 'WEEKEND',
        image: Icons.attach_money,
      ),
      Product(
        id: 'WE-4',
        name: 'Buggy Fee',
        price: 300000,
        stock: 9999,
        category: 'WEEKEND',
        image: Icons.attach_money,
      ),
    ];
    _applyFilter();
    // Prefill dari query (jika ada)
    if (widget.initialCustomer != null && widget.initialCustomer!.isNotEmpty) {
      _customerCtrl.text = widget.initialCustomer!;
    }
    // Tidak ada auto-qty SEWA LAPANGAN; kasir akan set manual.
  }

  Future<void> _initDb() async {
    await _invoiceRepo.init();
    await _teeRepo.init();
    if (mounted) {
      setState(() {
        _dbReady = true;
      });
    }
  }

  void _applyFilter() {
    final q = _searchCtrl.text.trim().toLowerCase();
    setState(() {
      // Tanpa search bar: tampilkan sesuai tab terpilih.
      _filtered = _selectedCategory == 'WEEKDAY'
          ? List<Product>.from(_weekdayFees)
          : List<Product>.from(_weekendFees);
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

  // Fitur tambah item manual dihapus.

  void _removeFromCart(String productId) {
    setState(() {
      _cart.removeWhere((c) => c.product.id == productId);
    });
  }

  double get _subtotal =>
      _cart.fold(0.0, (s, e) => s + e.product.price * e.qty);

  // Format Rupiah (IDR) is centralized via Formatters.idr

  Future<void> _saveTransaction() async {
    if (_saving) return; // guard against double tap
    setState(() { _saving = true; });
    if (!_dbReady) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Database belum siap, coba lagi sebentar...')),
      );
      setState(() { _saving = false; });
      return;
    }
    final customer = _customerCtrl.text.trim().isEmpty
        ? 'Walk-in'
        : _customerCtrl.text.trim();
    final items = _cart
        .map(
          (c) => InvoiceItemInput(
            name: c.product.name,
            qty: c.qty,
            price: c.product.price,
          ),
        )
        .toList();
    // Tidak menambahkan SEWA LAPANGAN otomatis; kasir memasukkan manual.
    try {
      await _invoiceRepo.createInvoice(customer: customer, items: items);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan transaksi: $e')),
      );
      setState(() { _saving = false; });
      return;
    }
    if (!mounted) return;
    // Optional: clear cart after save
    setState(() {
      _cart.clear();
      _saving = false;
    });
    GoRouter.of(context).goNamed(AppRoute.invoice.name);
  }

  @override
  Widget build(BuildContext context) {
    final body = LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 900;
        final content = isNarrow
            ? ListView(
                padding: const EdgeInsets.all(12),
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
                  // Left content scrollable
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(12),
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
                  // Right sidebar: Order Summary (tetap)
                  SizedBox(width: 320, child: _orderSummary()),
                ],
              );

        return content;
      },
    );

    return AppScaffold(title: 'POS System', body: body);
  }

  // Kategori UI seperti sebelumnya: chip untuk memilih Weekday/Weekend
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
              color: const Color(0xFF198754),
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
                      setState(() { _selectedCategory = c; });
                      _applyFilter();
                    },
                    label: Text(
                      c,
                      style: TextStyle(
                        color: selected
                            ? Colors.white
                            : const Color(0xFF198754),
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                    selectedColor: const Color(0xFF198754),
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFF198754)),
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
    // Hapus search bar; pertahankan header kiri seperti sebelumnya
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
      ],
    );
  }

  Widget _productGrid() {
    // Grid seperti sebelumnya: berdasarkan tab terpilih
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
            childAspectRatio: 1.2,
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
                    Row(
                      children: [
                        Icon(p.image, size: 20, color: Colors.grey.shade600),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            p.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      Formatters.idr(p.price),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF198754),
                          ) ?? const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
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
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
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
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _customerCtrl,
                      decoration: const InputDecoration(
                        hintText: 'Enter customer name...',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 42,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.search),
                      label: const Text('Cari Booking'),
                      onPressed: _openBookingSearch,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(),
              const Divider(),
              // Tidak ada SEWA LAPANGAN default. Kasir menambahkan manual bila perlu.
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
                  Text(Formatters.idr(_subtotal)),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 42,
                child: ElevatedButton(
                  onPressed: _cart.isNotEmpty && !_saving ? _saveTransaction : null,
                  // Gunakan warna default dari ElevatedButtonTheme (primary)
                  child: _saving ? const Text('Menyimpan...') : const Text('Simpan Transaksi'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Buka bottom sheet untuk mencari pemain/booking.
  /// Memudahkan memilih nama customer dan jumlah pemain (qty) dari data reservasi.
  Future<void> _openBookingSearch() async {
    // Ambil semua data dengan status 'booked'
    List<TeeTimeModel> all = await _teeRepo.getAllReservations(status: 'booked');
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        final qCtrl = TextEditingController();
        List<TeeTimeModel> filtered = List.of(all);
        void apply() {
          final q = qCtrl.text.trim().toLowerCase();
          filtered = all.where((e) {
            final name = (e.playerName ?? '').toLowerCase();
            return q.isEmpty || name.contains(q);
          }).toList();
        }
        apply();
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
              ),
              child: SizedBox(
                height: MediaQuery.of(ctx).size.height * 0.7,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cari Booking',
                      style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: qCtrl,
                      decoration: const InputDecoration(
                        hintText: 'Masukkan nama pemain...',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (_) {
                        setModalState(() {
                          apply();
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: filtered.isEmpty
                          ? Center(
                              child: Text(
                                'Tidak ada hasil',
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                            )
                          : ListView.separated(
                              itemCount: filtered.length,
                              separatorBuilder: (_, __) => const Divider(height: 1),
                              itemBuilder: (ctx, i) {
                                final m = filtered[i];
                                return ListTile(
                                  title: Text(m.playerName ?? '-'),
                                  subtitle: Text('${m.time} • ${m.date.toIso8601String().split('T').first} • pemain: ${m.playerCount ?? 1}'),
                                  trailing: FilledButton.tonal(
                                    onPressed: () {
                                      _customerCtrl.text = m.playerName ?? 'Walk-in';
                                      // Tidak menambahkan item otomatis dari booking.
                                      Navigator.of(ctx).pop();
                                    },
                                    child: const Text('Pilih'),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
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
          Text(Formatters.idr(c.product.price * c.qty)),
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
