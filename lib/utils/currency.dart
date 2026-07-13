import 'package:intl/intl.dart';

final _fmt = NumberFormat.currency(
    locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

String formatRupiah(int amount) => _fmt.format(amount);
