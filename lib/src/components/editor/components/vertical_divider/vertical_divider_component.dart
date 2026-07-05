import 'package:nocterm/nocterm.dart';

class VerticalDividerComponent extends StatelessComponent {
  const VerticalDividerComponent({super.key});

  @override
  Component build(BuildContext context) {
    return const VerticalDivider(
      style: DividerStyle.bold,
      width: 1,
      thickness: 1,
      indent: 0,
      endIndent: 0,
    );
  }
}