/// Centralized fee configuration so prices are not hard-coded across files.
class Fees {
  /// Booking fee charged when a tee time is created/confirmed.
  static const double bookingFee = 200000.0;

  /// Default green fee used when creating invoices from reservation management.
  static const double greenFeeDefault = 750000.0;
}