import 'dart:math' as math;
import 'dart:typed_data';

/// Single-precision helpers. Anki's scheduler (Rust) computes in `f32`;
/// Dart only has 64-bit doubles. Rounding every intermediate result to the
/// nearest f32 reproduces Rust's `+ - * /` exactly (IEEE operations are
/// correctly rounded, and a double has enough precision that rounding its
/// exact result to f32 gives the same value). For `exp`/`ln`/`powf` the
/// double result is rounded once; Rust's libm may differ in the last bit
/// for some inputs, which can only matter when a value lands exactly on a
/// rounding boundary.
final _buf = Float32List(1);

double f32(double x) {
  _buf[0] = x;
  return _buf[0];
}

double f32Exp(double x) => f32(math.exp(x));
double f32Ln(double x) => f32(math.log(x));
double f32Pow(double x, double y) => f32(math.pow(x, y).toDouble());

/// `x.exp_m1()` for f32.
double f32ExpM1(double x) => f32(x.abs() < 1e-5 ? x + x * x / 2 : math.exp(x) - 1);

/// The largest f32 strictly below [x] (for positive finite x).
double f32PrevDown(double x) {
  final b = ByteData(4)..setFloat32(0, x);
  b.setUint32(0, b.getUint32(0) - 1);
  return b.getFloat32(0);
}

/// Rust's `f32::round` (half away from zero) and `as u32` (saturating,
/// NaN -> 0) as used throughout the scheduler.
int roundToU32(double x) {
  if (x.isNaN || x <= 0) return 0;
  final r = x.roundToDouble(); // Dart rounds half away from zero, like Rust
  return r >= 4294967295 ? 4294967295 : r.toInt();
}

/// `x as u32` (truncation toward zero, saturating).
int truncToU32(double x) {
  if (x.isNaN || x <= 0) return 0;
  return x >= 4294967295 ? 4294967295 : x.truncate();
}
