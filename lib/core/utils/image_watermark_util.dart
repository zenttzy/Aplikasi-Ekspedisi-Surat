import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';

class ImageWatermarkUtil {
  /// Membaca foto asli dari [imagePath], menyematkan watermark overlay di bagian bawah,
  /// menyimpannya ke berkas baru, lalu mengembalikan path foto watermarked dan hash SHA-256 foto tersebut.
  static Future<({String watermarkedPath, String hash})> addWatermarkAndGetHash({
    required String imagePath,
    required String nomorSurat,
    required double latitude,
    required double longitude,
    required String address,
  }) async {
    final bytes = await File(imagePath).readAsBytes();

    // Decode foto
    final image = img.decodeImage(bytes);
    if (image == null) {
      throw Exception('Format gambar tidak valid atau tidak didukung');
    }

    final timeStr = DateTime.now().toLocal().toString().substring(0, 19);
    final text = 'Surat: $nomorSurat\nGPS: $latitude, $longitude\nAlamat: $address\nWaktu: $timeStr';

    // Buat latar hitam semi transparan di bagian bawah agar teks watermark mudah dibaca
    final rectHeight = (image.height * 0.15).round().clamp(100, 200);
    final rectY = image.height - rectHeight;

    img.fillRect(
      image,
      x1: 0,
      y1: rectY,
      x2: image.width,
      y2: image.height,
      color: img.ColorRgba8(0, 0, 0, 160),
    );

    // Sematkan teks menggunakan font bawaan (arial24 untuk resolusi tinggi)
    img.drawString(
      image,
      text,
      font: img.arial24,
      x: 20,
      y: rectY + 15,
      color: img.ColorRgba8(255, 255, 255, 255),
    );

    // Encode kembali menjadi JPG dengan kualitas 85% untuk kompresi ukuran berkas
    final watermarkedBytes = img.encodeJpg(image, quality: 85);

    // Hitung SHA-256 Hash dari berkas watermarked untuk anti-tampering
    final hashObj = sha256.convert(watermarkedBytes);
    final hashHex = hashObj.toString();

    // Simpan berkas hasil watermark ke aplikasi dokumen direktori
    final directory = await getApplicationDocumentsDirectory();
    final newPath = '${directory.path}/proof_${DateTime.now().millisecondsSinceEpoch}.jpg';
    await File(newPath).writeAsBytes(watermarkedBytes);

    return (watermarkedPath: newPath, hash: hashHex);
  }
}
