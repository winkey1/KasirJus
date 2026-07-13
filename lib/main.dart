import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'database/stock_dao.dart';
import 'logic/cart_notifier.dart';
import 'ui/main_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  // Reset gula ke 0 jika hari baru, sebelum app dibuka
  await StockDao().ensureGulaReset();
  runApp(const QuickJuiceApp());
}

class QuickJuiceApp extends StatelessWidget {
  const QuickJuiceApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QuickJuice POS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF2E7D32),
        useMaterial3: true,
      ),
      home: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => CartNotifier()),
        ],
        child: const MainShell(),
      ),
    );
  }
}
