import 'package:equatable/equatable.dart';

import '../../../core/config/app_constants.dart';

/// Entitas Surat Ekspedisi — merepresentasikan satu baris pada tabel
/// `expeditions` di SQLite. Field diselaraskan dengan tabel
/// `surat_ekspedisi` pada server agar sinkronisasi konsisten.
class Expedition extends Equatable {
  /// UUID unik (dari server atau dibuat lokal). Primary key.
  final String uuid;

  /// Nomor surat fisik (format server: `EKS-YYYYMMDD-XXXX`).
  final String? nomorSurat;

  /// Perihal / judul surat.
  final String perihal;

  /// Nama divisi asal.
  final String divisiPengirim;

  /// Nama divisi tujuan.
  final String divisiTujuan;

  /// Nama orang yang menerima (diisi saat kurir menyerahkan surat).
  final String? penerima;

  /// Waktu surat diterima (ISO-8601).
  final String? tanggalDiterima;

  /// Path lokal foto overlay (berwatermark).
  final String? fotoPath;

  /// SHA-256 hash dari foto original (hex string).
  final String? fotoHash;

  /// Koordinat GPS saat foto diambil.
  final double? lat;
  final double? long;

  /// Alamat hasil reverse-geocoding (untuk overlay & metadata).
  final String? alamat;

  /// Status surat: 'draft' | 'dikirim' | 'diterima'.
  final String status;

  /// 1 jika sudah tersinkron dengan server, 0 jika belum.
  final bool isSynced;

  /// 1 jika ada data/foto baru yang perlu didorong ke server.
  final bool needsUpload;

  const Expedition({
    required this.uuid,
    this.nomorSurat,
    required this.perihal,
    required this.divisiPengirim,
    required this.divisiTujuan,
    this.penerima,
    this.tanggalDiterima,
    this.fotoPath,
    this.fotoHash,
    this.lat,
    this.long,
    this.alamat,
    this.status = ExpeditionStatus.dikirim,
    this.isSynced = false,
    this.needsUpload = false,
  });

  /// Membuat salinan dengan sebagian field diubah (immutability-friendly).
  Expedition copyWith({
    String? uuid,
    String? nomorSurat,
    String? perihal,
    String? divisiPengirim,
    String? divisiTujuan,
    String? penerima,
    String? tanggalDiterima,
    String? fotoPath,
    String? fotoHash,
    double? lat,
    double? long,
    String? alamat,
    String? status,
    bool? isSynced,
    bool? needsUpload,
  }) {
    return Expedition(
      uuid: uuid ?? this.uuid,
      nomorSurat: nomorSurat ?? this.nomorSurat,
      perihal: perihal ?? this.perihal,
      divisiPengirim: divisiPengirim ?? this.divisiPengirim,
      divisiTujuan: divisiTujuan ?? this.divisiTujuan,
      penerima: penerima ?? this.penerima,
      tanggalDiterima: tanggalDiterima ?? this.tanggalDiterima,
      fotoPath: fotoPath ?? this.fotoPath,
      fotoHash: fotoHash ?? this.fotoHash,
      lat: lat ?? this.lat,
      long: long ?? this.long,
      alamat: alamat ?? this.alamat,
      status: status ?? this.status,
      isSynced: isSynced ?? this.isSynced,
      needsUpload: needsUpload ?? this.needsUpload,
    );
  }

  /// Konversi ke Map untuk disimpan ke SQLite.
  Map<String, Object?> toDbMap() {
    return {
      'uuid': uuid,
      'nomor_surat': nomorSurat,
      'perihal': perihal,
      'divisi_pengirim': divisiPengirim,
      'divisi_tujuan': divisiTujuan,
      'penerima': penerima,
      'tanggal_diterima': tanggalDiterima,
      'foto_path': fotoPath,
      'foto_hash': fotoHash,
      'lat': lat,
      'long': long,
      'alamat': alamat,
      'status': status,
      'is_synced': isSynced ? 1 : 0,
      'needs_upload': needsUpload ? 1 : 0,
    };
  }

  /// Membuat instance dari baris SQLite.
  factory Expedition.fromDbMap(Map<String, Object?> map) {
    return Expedition(
      uuid: map['uuid'] as String,
      nomorSurat: map['nomor_surat'] as String?,
      perihal: (map['perihal'] as String?) ?? '',
      divisiPengirim: (map['divisi_pengirim'] as String?) ?? '',
      divisiTujuan: (map['divisi_tujuan'] as String?) ?? '',
      penerima: map['penerima'] as String?,
      tanggalDiterima: map['tanggal_diterima'] as String?,
      fotoPath: map['foto_path'] as String?,
      fotoHash: map['foto_hash'] as String?,
      lat: (map['lat'] as num?)?.toDouble(),
      long: (map['long'] as num?)?.toDouble(),
      alamat: map['alamat'] as String?,
      status: (map['status'] as String?) ?? ExpeditionStatus.dikirim,
      isSynced: (map['is_synced'] as int? ?? 0) == 1,
      needsUpload: (map['needs_upload'] as int? ?? 0) == 1,
    );
  }

  /// Membuat instance dari payload JSON `/sync/download`.
  ///
  /// Server memakai nama field `divisi_pengirim_nama` & `divisi_tujuan_nama`.
  factory Expedition.fromSyncJson(Map<String, dynamic> json) {
    return Expedition(
      uuid: json['uuid'] as String,
      nomorSurat: json['nomor_surat'] as String?,
      perihal: (json['perihal'] as String?) ?? '',
      divisiPengirim: (json['divisi_pengirim_nama'] as String?) ??
          (json['divisi_pengirim'] as String?) ??
          '',
      divisiTujuan: (json['divisi_tujuan_nama'] as String?) ??
          (json['divisi_tujuan'] as String?) ??
          '',
      penerima: json['nama_penerima'] as String?,
      tanggalDiterima: json['tanggal_penerimaan'] as String?,
      status: (json['status'] as String?) ?? ExpeditionStatus.dikirim,
      // Data dari server dianggap sudah tersinkron.
      isSynced: true,
      needsUpload: false,
    );
  }

  @override
  List<Object?> get props => [
        uuid,
        nomorSurat,
        perihal,
        divisiPengirim,
        divisiTujuan,
        penerima,
        tanggalDiterima,
        fotoPath,
        fotoHash,
        lat,
        long,
        alamat,
        status,
        isSynced,
        needsUpload,
      ];
}
