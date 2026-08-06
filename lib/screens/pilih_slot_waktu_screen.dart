import 'package:flutter/material.dart';
import '../models/jadwal_donor.dart';
import '../theme/app_theme.dart';
import 'e_tiket_screen.dart';

class SlotWaktu {
  final String jamMulai;
  final String jamSelesai;
  final int pendaftar;
  final int kapasitas;

  const SlotWaktu({
    required this.jamMulai,
    required this.jamSelesai,
    required this.pendaftar,
    required this.kapasitas,
  });

  String get label => '$jamMulai - $jamSelesai';
  bool get penuh => pendaftar >= kapasitas;
  bool get hampirPenuh => !penuh && (kapasitas - pendaftar) <= 2;
}

// GAP: endpoint slot waktu per-jadwal belum ada di backend. Data di bawah
// ini MOCK, ganti dengan hasil fetch JadwalService.getSlotWaktu(jadwal.idJadwal)
// begitu API-nya siap. Field ditebak dari kebutuhan UI: jam mulai/selesai,
// jumlah pendaftar saat ini, dan kapasitas per slot.
const List<SlotWaktu> _mockSlotWaktu = [
  SlotWaktu(jamMulai: '08:00', jamSelesai: '08:45', pendaftar: 3, kapasitas: 8),
  SlotWaktu(jamMulai: '09:00', jamSelesai: '09:45', pendaftar: 8, kapasitas: 8),
  SlotWaktu(jamMulai: '10:00', jamSelesai: '10:45', pendaftar: 6, kapasitas: 8),
  SlotWaktu(jamMulai: '11:00', jamSelesai: '11:45', pendaftar: 7, kapasitas: 8),
  SlotWaktu(jamMulai: '12:00', jamSelesai: '12:45', pendaftar: 5, kapasitas: 8),
  SlotWaktu(jamMulai: '13:00', jamSelesai: '13:45', pendaftar: 4, kapasitas: 8),
];

class PilihSlotWaktuScreen extends StatefulWidget {
  final JadwalDonor jadwal;

  const PilihSlotWaktuScreen({super.key, required this.jadwal});

  @override
  State<PilihSlotWaktuScreen> createState() => _PilihSlotWaktuScreenState();
}

class _PilihSlotWaktuScreenState extends State<PilihSlotWaktuScreen> {
  SlotWaktu? _slotDipilih;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(context),
                    const SizedBox(height: 24),
                    _buildSlotGrid(),
                    const SizedBox(height: 16),
                    _buildCatatan(),
                    if (_slotDipilih != null) ...[
                      const SizedBox(height: 16),
                      _buildRingkasan(),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _slotDipilih == null
                      ? null
                      : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ETiketScreen(
                                jadwal: widget.jadwal,
                                slot: _slotDipilih!,
                              ),
                            ),
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor: AppColors.buttonDisabledBg,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Konfirmasi Ambil Nomor Antrian',
                    style: AppText.button.copyWith(
                      color: _slotDipilih == null
                          ? AppColors.buttonDisabledText
                          : Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.inputBorder),
          ),
          child: IconButton(
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.chevron_left, size: 20),
            onPressed: () => Navigator.maybePop(context),
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'LANGKAH 5 DARI 5',
                style: AppText.label.copyWith(
                  color: AppColors.primary,
                  letterSpacing: 1.4,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Pilih slot waktu',
                style: AppText.headline.copyWith(fontSize: 19),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSlotGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _mockSlotWaktu.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.95,
      ),
      itemBuilder: (context, i) => _buildSlotCard(_mockSlotWaktu[i]),
    );
  }

  Widget _buildSlotCard(SlotWaktu slot) {
    final dipilih = _slotDipilih == slot;
    final penuh = slot.penuh;

    Color bg = Colors.white;
    Color border = AppColors.inputBorder;
    if (penuh) {
      bg = AppColors.tabInactiveBg;
      border = AppColors.tabInactiveBg;
    } else if (dipilih) {
      border = AppColors.primary;
    }

    String subteks;
    Color subtekColor;
    if (penuh) {
      subteks = 'Penuh';
      subtekColor = AppColors.neutralMuted;
    } else if (slot.hampirPenuh) {
      subteks = 'Slot terbatas';
      subtekColor = AppColors.primary;
    } else {
      subteks = '${slot.pendaftar} pendaftar';
      subtekColor = AppColors.textMuted;
    }

    return GestureDetector(
      onTap: penuh ? null : () => setState(() => _slotDipilih = slot),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border, width: dipilih ? 1.5 : 1),
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  slot.label,
                  style: AppText.inputText.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: penuh
                        ? AppColors.neutralMuted
                        : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subteks,
                  style: AppText.helper.copyWith(
                    fontSize: 11,
                    color: subtekColor,
                    fontWeight: slot.hampirPenuh
                        ? FontWeight.w700
                        : FontWeight.w400,
                  ),
                ),
              ],
            ),
            if (dipilih)
              const Positioned(
                top: 0,
                right: 0,
                child: Icon(
                  Icons.check_circle,
                  size: 18,
                  color: AppColors.primary,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCatatan() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.tabInactiveBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline,
            size: 16,
            color: AppColors.neutralMuted,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Datang 15 menit sebelum jam slot dimulai. Nomor antrian otomatis '
              'hangus jika Anda tidak hadir dalam 15 menit setelah jam mulai.',
              style: AppText.helper.copyWith(fontSize: 11.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRingkasan() {
    final jadwal = widget.jadwal;
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ringkasan konfirmasi',
            style: AppText.headline.copyWith(fontSize: 13),
          ),
          const SizedBox(height: 12),
          _ringkasanBaris(
            'Kegiatan',
            jadwal.namaKegiatan ??
                'Donor Darah Bersama ${jadwal.lokasi.namaLokasi}',
          ),
          _ringkasanBaris('Tanggal', _formatTanggal(jadwal.tanggal)),
          _ringkasanBaris('Slot waktu', '${_slotDipilih!.label} WIB'),
        ],
      ),
    );
  }

  Widget _ringkasanBaris(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(label, style: AppText.helper.copyWith(fontSize: 12)),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: AppText.inputText.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 12.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTanggal(DateTime tanggal) {
    const hari = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];
    const bulan = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    return '${hari[tanggal.weekday - 1]}, ${tanggal.day} '
        '${bulan[tanggal.month - 1]} ${tanggal.year}';
  }
}
