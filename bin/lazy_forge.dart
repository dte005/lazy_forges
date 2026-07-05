import 'package:lazy_forge/lazy_forge.dart';
import 'package:nocterm/nocterm.dart';

void main() {
  // function that taker terminal control
  runApp(TuiTheme(data: TuiThemeData.dark, child: const LazyForgeApp()));
}
