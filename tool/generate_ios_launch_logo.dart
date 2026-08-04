import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart' as img;

const _sourcePath = 'LogoZentra.png';
const _launchImageDirectory = 'ios/Runner/Assets.xcassets/LaunchImage.imageset';
const _sharedLogoPath = 'assets/images/zentra_logo.png';

const _outputs = <String, int>{
  'LaunchImage.png': 168,
  'LaunchImage@2x.png': 336,
  'LaunchImage@3x.png': 504,
};

void main() {
  final sourceBytes = File(_sourcePath).readAsBytesSync();
  final decoded = img.decodePng(sourceBytes);
  if (decoded == null) {
    stderr.writeln('No se pudo decodificar $_sourcePath.');
    exitCode = 1;
    return;
  }

  final transparentLogo = decoded.convert(numChannels: 4);
  var transparentPixels = 0;

  for (final pixel in transparentLogo) {
    final brightest = math.max(pixel.r, math.max(pixel.g, pixel.b));

    // LogoZentra is the opaque App Store icon source. Its outer canvas is
    // pure black, while the launch screen needs that outer canvas to be
    // transparent. Keep the teal icon and bird untouched.
    if (brightest <= 12) {
      transparentLogo.setPixelRgba(pixel.x, pixel.y, 0, 0, 0, 0);
      transparentPixels++;
    }
  }

  if (transparentPixels == 0) {
    stderr.writeln('No se encontró el fondo negro esperado en $_sourcePath.');
    exitCode = 1;
    return;
  }

  final sharedLogo = File(_sharedLogoPath);
  sharedLogo.parent.createSync(recursive: true);
  sharedLogo.writeAsBytesSync(img.encodePng(transparentLogo, level: 9));
  stdout.writeln(
    '${sharedLogo.path}: ${transparentLogo.width}x${transparentLogo.height}, '
    'fondo transparente',
  );

  for (final entry in _outputs.entries) {
    final resized = img.copyResize(
      transparentLogo,
      width: entry.value,
      height: entry.value,
      interpolation: img.Interpolation.cubic,
    );
    final output = File('$_launchImageDirectory/${entry.key}');
    output.parent.createSync(recursive: true);
    output.writeAsBytesSync(img.encodePng(resized, level: 9));
    stdout.writeln(
      '${output.path}: ${resized.width}x${resized.height}, fondo transparente',
    );
  }
}
