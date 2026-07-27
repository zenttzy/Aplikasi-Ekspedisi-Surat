import 'package:equatable/equatable.dart';

import '../../../core/config/app_constants.dart';

class Expedition extends Equatable {
  final String uuid;
  final String? nomorSurat;
  final String perihal;
  final String divisiPengirim;
  final String divisiTujuan;
  final String? penerima;
  final String? tanggalDiterima;
  final String? fotoPath;
  final String? fotoHash;
  final double? lat;
  final double? lng;
  final String? alamat;
  final String status;
  final String? kurirId;
  final bool isSynced;
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
    this.lng,
    this.alamat,
    required this.status,
    this.kurirId,
    required this.isSynced,
    required this.needsUpload,
  });

  static Expedition fromServerJson(Map<String, dynamic> json) {
    return Expedition(
      uuid: (json['uuid'] ?? json['id']) as String,
      nomorSurat: json['nomor_surat'] as String?,
      perihal: (json['perihal'] as String?) ?? '',
      divisiPengirim: (json['pengirim_nama'] as String?) ?? '',
      divisiTujuan: (json['tujuan_nama'] as String?) ?? '',
      penerima: json['nama_penerima'] as String?,
      tanggalDiterima: json['tanggal_terima'] as String?,
      status: (json['status'] as String?) ?? ExpeditionStatus.dikirim,
      kurirId: json['kurir_id'] as String?,
      isSynced: true,
      needsUpload: false,
    );
  }

  factory Expedition.fromSqlite(Map<String, dynamic> row) {
    return Expedition(
      uuid: row['uuid'] as String,
      nomorSurat: row['nomor_surat'] as String?,
      perihal: (row['perihal'] as String?) ?? '',
      divisiPengirim: (row['divisi_pengirim'] as String?) ?? '',
      divisiTujuan: (row['divisi_tujuan'] as String?) ?? '',
      penerima: row['penerima'] as String?,
      tanggalDiterima: row['tanggal_diterima'] as String?,
      fotoPath: row['foto_path'] as String?,
      fotoHash: row['foto_hash'] as String?,
      lat: row['lat'] as double?,
      lng: row['long'] as double?,
      alamat: row['alamat'] as String?,
      status: (row['status'] as String?) ?? ExpeditionStatus.dikirim,
      kurirId: row['kurir_id'] as String?,
      isSynced: (row['is_synced'] as int) == 1,
      needsUpload: (row['needs_upload'] as int) == 1,
    );
  }

  Map<String, dynamic> toSqliteMap() => {
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
        'long': lng,
        'alamat': alamat,
        'status': status,
        'kurir_id': kurirId,
        'is_synced': isSynced ? 1 : 0,
        'needs_upload': needsUpload ? 1 : 0,
      };

  Expedition copyWith({
    String? status,
    String? penerima,
    String? tanggalDiterima,
    String? fotoPath,
    String? fotoHash,
    double? lat,
    double? lng,
    String? alamat,
    bool? isSynced,
    bool? needsUpload,
  }) =>
      Expedition(
        uuid: uuid,
        nomorSurat: nomorSurat,
        perihal: perihal,
        divisiPengirim: divisiPengirim,
        divisiTujuan: divisiTujuan,
        penerima: penerima ?? this.penerima,
        tanggalDiterima: tanggalDiterima ?? this.tanggalDiterima,
        fotoPath: fotoPath ?? this.fotoPath,
        fotoHash: fotoHash ?? this.fotoHash,
        lat: lat ?? this.lat,
        lng: lng ?? this.lng,
        alamat: alamat ?? this.alamat,
        status: status ?? this.status,
        kurirId: kurirId,
        isSynced: isSynced ?? this.isSynced,
        needsUpload: needsUpload ?? this.needsUpload,
      );

  @override
  List<Object?> get props => [
        uuid, nomorSurat, perihal, divisiPengirim, divisiTujuan,
        penerima, tanggalDiterima, fotoPath, fotoHash, lat, lng,
        alamat, status, kurirId, isSynced, needsUpload,
      ];
}
