import 'dart:io';

class ClipboardService {
  static Future<void> copy(String text) async {
    if (Platform.isWindows) {
      await _copyWithCommand('cmd', const ['/c', 'clip'], text);
      return;
    }
    if (Platform.isMacOS) {
      await _copyWithCommand('pbcopy', const <String>[], text);
      return;
    }

    try {
      await _copyWithCommand('xclip', const ['-selection', 'clipboard'], text);
      return;
    } catch (_) {
      await _copyWithCommand('xsel', const ['--clipboard', '--input'], text);
    }
  }

  static Future<void> _copyWithCommand(
    String executable,
    List<String> arguments,
    String text,
  ) async {
    final process = await Process.start(executable, arguments);
    process.stdin.write(text);
    await process.stdin.close();
    final exitCode = await process.exitCode;
    if (exitCode != 0) {
      throw ProcessException(executable, arguments, 'Falha ao copiar.', exitCode);
    }
  }
}
