// Screen: POS System page
// Tujuan: Pusat transaksi kasir untuk membuat invoice (weekday/weekend fees) dan memilih customer dari booking.
// Catatan: Dipindahkan ke folder pos_system_folder untuk struktur yang rapi.
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
import '../../models/pos_models.dart';
import 'pos_system_folder/categories_section.dart';
import 'pos_system_folder/products_header.dart';
import 'pos_system_folder/product_grid.dart';
import 'pos_system_folder/order_summary.dart';

/// POS System main page. If opened via redirect, optional `from` tells
/// which page triggered the redirect (e.g. 'invoice' or 'payments').
class PosSystemPage extends StatefulWidget {
  // Halaman POS sebagai pusat transaksi.
  // from: konteks asal redirect (invoice/payments/teeManage)
  // initialCustomer & initialQty: nilai awal dari halaman Manage Reservation.
  final String? from;
  final String? initialCustomer;
  final int? initialQty;
  const PosSystemPage({
    super.key,
    this.from,
    this.initialCustomer,
    this.initialQty,
  });

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
  // Kategori menggunakan model Category yang reusable
  final List<Category> _categories = const [
    Category(id: 'WEEKDAY', name: 'Weekday'),
    Category(id: 'WEEKEND', name: 'Weekend'),
  ];
  String? _selectedCategoryId = 'WEEKDAY';
  List<Product> _filtered = [];
  final List<OrderItem> _cart = [];
  String _sortBy = 'name_asc';

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
    _weekdayFees = const [
      Product(
        id: 'WD-1',
        name: 'Guest Member Fee',
        price: 1600000,
        categoryId: 'WEEKDAY',
      ),
      Product(
        id: 'WD-2',
        name: 'Visitor Fee',
        price: 3000000,
        categoryId: 'WEEKDAY',
      ),
      Product(
        id: 'WD-3',
        name: 'Caddy Fee',
        price: 300000,
        categoryId: 'WEEKDAY',
      ),
      Product(
        id: 'WD-4',
        name: 'Buggy Fee',
        price: 300000,
        categoryId: 'WEEKDAY',
      ),
    ];
    _weekendFees = const [
      Product(
        id: 'WE-1',
        name: 'Guest Member Fee',
        price: 3500000,
        categoryId: 'WEEKEND',
      ),
      Product(
        id: 'WE-2',
        name: 'Visitor Fee',
        price: 5000000,
        categoryId: 'WEEKEND',
      ),
      Product(
        id: 'WE-3',
        name: 'Caddy Fee',
        price: 300000,
        categoryId: 'WEEKEND',
      ),
      Product(
        id: 'WE-4',
        name: 'Buggy Fee',
        price: 300000,
        categoryId: 'WEEKEND',
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
    List<Product> base = _selectedCategoryId == 'WEEKDAY'
        ? List<Product>.from(_weekdayFees)
        : List<Product>.from(_weekendFees);
    // Search by name
    if (q.isNotEmpty) {
      base = base.where((p) => p.name.toLowerCase().contains(q)).toList();
    }
    // Sort
    switch (_sortBy) {
      case 'name_asc':
        base.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'name_desc':
        base.sort((a, b) => b.name.compareTo(a.name));
        break;
      case 'price_low':
        base.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'price_high':
        base.sort((a, b) => b.price.compareTo(a.price));
        break;
    }
    setState(() {
      _filtered = base;
    });
  }

  void _addToCart(Product p) {
    final idx = _cart.indexWhere((c) => c.product.id == p.id);
    setState(() {
      if (idx >= 0) {
        _cart[idx].quantity++;
      } else {
        _cart.add(OrderItem(product: p, quantity: 1));
      }
    });
  }

  // Fitur tambah item manual dihapus.

  void _removeFromCart(String productId) {
    setState(() {
      _cart.removeWhere((c) => c.product.id == productId);
    });
  }

  void _incrementItem(OrderItem it) {
    setState(() {
      it.quantity++;
    });
  }

  void _decrementItem(OrderItem it) {
    setState(() {
      if (it.quantity > 1) {
        it.quantity--;
      } else {
        _cart.remove(it);
      }
    });
  }

  void _removeItem(OrderItem it) {
    setState(() {
      _cart.remove(it);
    });
  }

  double get _subtotal => OrderSummaryHelper.total(_cart);

  // Format Rupiah (IDR) is centralized via Formatters.idr

  Future<void> _saveTransaction() async {
    if (_saving) return; // guard against double tap
    setState(() {
      _saving = true;
    });
    if (!_dbReady) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Database belum siap, coba lagi sebentar...'),
        ),
      );
      setState(() {
        _saving = false;
      });
      return;
    }
    final customer = _customerCtrl.text.trim().isEmpty
        ? 'Walk-in'
        : _customerCtrl.text.trim();
    final items = _cart
        .map(
          (c) => InvoiceItemInput(
            name: c.product.name,
            qty: c.quantity,
            price: c.product.price,
          ),
        )
        .toList();
    // Tidak menambahkan SEWA LAPANGAN otomatis; kasir memasukkan manual.
    try {
      await _invoiceRepo.createInvoice(customer: customer, items: items);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal menyimpan transaksi: $e')));
      setState(() {
        _saving = false;
      });
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
        final categoriesCard = Card(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: const BoxDecoration(
                  color: Color(0xFF198754),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
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
                child: CategoriesSection(
                  categories: _categories,
                  selectedCategoryId: _selectedCategoryId,
                  onSelectCategory: (id) {
                    setState(() {
                      _selectedCategoryId = id ?? 'WEEKDAY';
                    });
                    _applyFilter();
                  },
                ),
              ),
            ],
          ),
        );

        final content = isNarrow
            ? ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  categoriesCard,
                  const SizedBox(height: 12),
                  ProductsHeader(
                    searchController: _searchCtrl,
                    onSearchChanged: (_) => _applyFilter(),
                    sortBy: _sortBy,
                    onSortChanged: (v) {
                      setState(() {
                        _sortBy = v ?? 'name_asc';
                      });
                      _applyFilter();
                    },
                  ),
                  const SizedBox(height: 8),
                  ProductGrid(products: _filtered, onAddToCart: _addToCart),
                  const SizedBox(height: 12),
                  _customerAndSummary(),
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
                        categoriesCard,
                        const SizedBox(height: 12),
                        ProductsHeader(
                          searchController: _searchCtrl,
                          onSearchChanged: (_) => _applyFilter(),
                          sortBy: _sortBy,
                          onSortChanged: (v) {
                            setState(() {
                              _sortBy = v ?? 'name_asc';
                            });
                            _applyFilter();
                          },
                        ),
                        const SizedBox(height: 8),
                        ProductGrid(
                          products: _filtered,
                          onAddToCart: _addToCart,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Right sidebar: Order Summary (tetap)
                  SizedBox(width: 360, child: _customerAndSummary()),
                ],
              );

        return content;
      },
    );

    return AppScaffold(title: 'POS System', body: body);
  }

  // Customer section + reusable OrderSummary (keranjang)
  Widget _customerAndSummary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
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
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        OrderSummary(
          items: _cart,
          onIncrement: _incrementItem,
          onDecrement: _decrementItem,
          onRemove: _removeItem,
          onCheckout: _cart.isNotEmpty && !_saving ? _saveTransaction : () {},
        ),
      ],
    );
  }

  /// Buka bottom sheet untuk mencari pemain/booking.
  /// Memudahkan memilih nama customer dan jumlah pemain (qty) dari data reservasi.
  Future<void> _openBookingSearch() async {
    // Show loading dialog while fetching data
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading bookings...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      // Ambil semua data dengan status 'booked'
      List<TeeTimeModel> all = await _teeRepo.getAllReservations(
        status: 'booked',
      );

      // Get customers who already have invoices - these should be excluded
      // Customer names are compared in lowercase for case-insensitive matching
      final customersWithInvoices = await _invoiceRepo
          .getCustomersWithInvoices();

      // Filter out bookings from customers who already have invoices
      all = all.where((booking) {
        final playerName = (booking.playerName ?? '').toLowerCase().trim();
        return !customersWithInvoices.contains(playerName);
      }).toList();

      // Close loading dialog
      if (!mounted) return;
      Navigator.of(context).pop();

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
                        style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
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
                                separatorBuilder: (_, __) =>
                                    const Divider(height: 1),
                                itemBuilder: (ctx, i) {
                                  final m = filtered[i];
                                  return ListTile(
                                    title: Text(m.playerName ?? '-'),
                                    subtitle: Text(
                                      '${m.time} • ${m.date.toIso8601String().split('T').first} • pemain: ${m.playerCount ?? 1}',
                                    ),
                                    trailing: FilledButton.tonal(
                                      onPressed: () {
                                        _customerCtrl.text =
                                            m.playerName ?? 'Walk-in';
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
    } catch (e) {
      // Close loading dialog if error occurs
      if (!mounted) return;
      Navigator.of(context).pop();

      // Show error message
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading bookings: $e')));
    }
  }
}
