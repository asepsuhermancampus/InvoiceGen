# 📄 Invoice Generator (Inv Gen)

Aplikasi pembuatan Invoice, Penawaran Harga, Quotation, dan Proforma Invoice berbasis **Flutter** dengan fitur **PDF multi-template**, **manajemen status**, dan **kalkulasi otomatis**.

---

## 📋 Daftar Isi

- [Instalasi & Menjalankan Aplikasi](#-instalasi--menjalankan-aplikasi)
- [Alur Penggunaan](#-alur-penggunaan)
- [1. Dashboard](#1-dashboard)
- [2. Membuat Company (Perusahaan)](#2-membuat-company-perusahaan)
- [3. Membuat Customer (PIC/Penerima)](#3-membuat-customer-picpenerima)
- [4. Membuat Invoice Baru](#4-membuat-invoice-baru)
- [5. Preview & Cetak PDF](#5-preview--cetak-pdf)
- [6. Daftar Invoice](#6-daftar-invoice)
- [7. Template PDF](#7-template-pdf)
- [8. Pengaturan](#8-pengaturan)
- [Template PDF yang Tersedia](#-template-pdf-yang-tersedia)
- [Tipe Dokumen](#-tipe-dokumen)
- [Tips & Trik](#-tips--trik)
- [Teknologi yang Digunakan](#-teknologi-yang-digunakan)

---

## 🚀 Instalasi & Menjalankan Aplikasi

### Prasyarat
- Flutter SDK (versi 3.x atau lebih baru)
- Android Studio / VS Code
- Perangkat Android / Emulator

### Langkah-langkah

```bash
# 1. Clone repository
git clone https://github.com/asepsuhermancampus/InvoiceGen.git

# 2. Masuk ke direktori project
cd InvoiceGen

# 3. Install dependencies
flutter pub get

# 4. Jalankan aplikasi
flutter run
```

---

## 🔄 Alur Penggunaan

Berikut adalah alur penggunaan aplikasi dari awal sampai akhir:

```
Buat Company → Buat Customer → Buat Invoice → Tambah Item → Preview PDF → Kirim/Cetak
      ↓                                                                        ↓
  (Satu kali)                                                          Ubah Status:
                                                                   Draft → Sent → Paid
```

---

## 1. Dashboard

Dashboard adalah halaman utama yang menampilkan:

| Elemen | Keterangan |
|--------|-----------|
| **Statistik** | Jumlah Invoice, Customer, Company |
| **Total Nilai Invoice** | Akumulasi grand total dari seluruh invoice |
| **Aksi Cepat** | 6 tombol pintasan: Buat Invoice, Daftar Company, Daftar PIC, Daftar Invoice, Template PDF, Pengaturan |
| **Invoice Terbaru** | 5 invoice terakhir yang dibuat |

### Tombol Aksi Cepat:
- 🔵 **Buat Invoice** — Langsung ke form pembuatan invoice
- 🟢 **Daftar Company** — Kelola data perusahaan pengirim
- 🟠 **Daftar PIC** — Kelola data customer/penerima
- 🔷 **Daftar Invoice** — Lihat semua invoice + filter status
- 🟣 **Template PDF** — Lihat & kelola template
- ⚙️ **Pengaturan** — Konfigurasi aplikasi

---

## 2. Membuat Company (Perusahaan)

Company adalah **data perusahaan pengirim** yang akan muncul di header PDF.

### Cara Membuat:
1. Dari Dashboard, tap **"Daftar Company"**
2. Tap tombol **"+"** di kanan bawah
3. Isi data berikut:

| Field | Keterangan | Wajib? |
|-------|-----------|--------|
| **Nama Perusahaan** | Nama PT / CV / Perusahaan | ✅ Ya |
| **Cabang** | Nama cabang (misal: "Kantor Pusat Jakarta") | ❌ Opsional |
| **Slogan** | Tagline perusahaan | ❌ Opsional |
| **Alamat** | Alamat lengkap perusahaan | ✅ Ya |
| **No. Telepon** | Nomor telepon kantor | ❌ Opsional |
| **Email** | Email perusahaan | ❌ Opsional |
| **Website** | Website perusahaan | ❌ Opsional |

4. Tap **"Simpan"**

> **💡 Tips:** Buat satu company dahulu sebelum membuat invoice. Company bisa ditambah lebih dari satu untuk berbagai cabang.

---

## 3. Membuat Customer (PIC/Penerima)

Customer adalah **data penerima invoice** yang akan muncul di bagian "KEPADA:" pada PDF.

### Cara Membuat:
1. Dari Dashboard, tap **"Daftar PIC"**
2. Tap tombol **"+"** di kanan bawah
3. Isi data berikut:

| Field | Keterangan | Wajib? |
|-------|-----------|--------|
| **Nama** | Nama PIC / perorangan | ✅ Ya |
| **Nama Perusahaan** | Nama PT penerima (kosongkan untuk perorangan) | ❌ Opsional |
| **Alamat** | Alamat lengkap penerima | ❌ Opsional |
| **No. Telepon** | Nomor telepon penerima | ❌ Opsional |
| **Email** | Email penerima | ❌ Opsional |

4. Tap **"Simpan"**

### Untuk Perusahaan vs Perorangan:

| Kebutuhan | Yang Diisi | Hasil di PDF |
|-----------|-----------|-------------|
| **Perusahaan** | Isi "Nama Perusahaan" + "Nama" | Muncul: `Perusahaan : PT. XYZ` lalu `Nama : Budi` |
| **Perorangan** | Kosongkan "Nama Perusahaan", isi "Nama" saja | Langsung muncul: `Nama : Budi` (tanpa baris Perusahaan) |

---

## 4. Membuat Invoice Baru

### Cara Membuat:
1. Dari Dashboard, tap **"Buat Invoice"** atau tombol **"+ Buat Invoice"** di bawah
2. Isi form invoice dengan lengkap

### Bagian Form Invoice:

#### A. Header Dokumen

| Field | Keterangan |
|-------|-----------|
| **Nomor Invoice** | Auto-generate (misal: `INV-20260721-001`), bisa diedit |
| **Tanggal** | Pilih tanggal dokumen |
| **Tipe Dokumen** | Pilih: Invoice, Penawaran Harga, Quotation, atau Proforma Invoice |
| **Mata Uang** | IDR (default) |
| **Company** | Pilih perusahaan pengirim dari daftar |
| **Customer** | Pilih penerima dari daftar |

#### B. Teks Pembuka (Intro Text)

Pilih template teks pembuka yang sesuai:
- **Invoice** — Teks tagihan standar
- **Penawaran Harga** — Teks penawaran standar
- **Quotation** — Teks quotation (Bahasa Inggris)
- **Proforma Invoice** — Teks proforma standar
- **Kosong** — Tanpa teks pembuka
- **Custom** — Tulis sendiri teks pembuka

#### C. Daftar Item/Barang

Tap tombol **"+ Tambah Item"** untuk menambah barang/jasa.

| Field | Keterangan |
|-------|-----------|
| **Nama Barang** | Nama item/jasa |
| **Spesifikasi** | Detail spesifikasi (opsional) |
| **Qty** | Jumlah |
| **Satuan** | Pilih: Pcs, Unit, Set, Lot, Paket, Bulan, Tahun, Meter, Kg, Box, Roll, Lembar, Rim |
| **Harga Jual** | Harga per satuan |

> **💡 Tips:** Item yang sudah ditambahkan bisa di-**edit** (ikon pensil) atau di-**hapus** (ikon tempat sampah).

#### D. Pajak & Perhitungan

| Field | Keterangan |
|-------|-----------|
| **PPN (%)** | Tarif PPN (default: 11%) |
| **Sembunyikan Subtotal** | Toggle untuk hide/unhide subtotal di PDF |
| **Sembunyikan Pajak** | Toggle untuk hide/unhide baris PPN di PDF |

Perhitungan otomatis:
```
Subtotal     = Σ (Qty × Harga Jual) per item
PPN          = Subtotal × Tarif PPN%
Grand Total  = Subtotal + PPN
Terbilang    = Konversi otomatis ke teks Indonesia
```

#### E. Footer & Tanda Tangan

| Field | Keterangan |
|-------|-----------|
| **Catatan** | Catatan/keterangan di bawah tabel (misal: info rekening) |
| **Syarat Pembayaran** | Ketentuan pembayaran (misal: "Net 14 Days") |
| **Nama Penandatangan** | Nama yang muncul di kolom tanda tangan |

3. Tap **"Preview PDF"** untuk melihat hasil, atau **"Simpan"** untuk menyimpan sebagai Draft

---

## 5. Preview & Cetak PDF

Setelah membuat invoice, Anda akan masuk ke halaman Preview PDF.

### Fitur di halaman Preview:
- **Ganti Template** — Tap chip template di bagian atas (Classic, Modern, Corporate, Clean Elegant)
- **Share** — Kirim PDF via WhatsApp, Email, dll (ikon 📤)
- **Print** — Cetak langsung ke printer (ikon 🖨️)

---

## 6. Daftar Invoice

Halaman ini menampilkan semua invoice yang telah dibuat.

### Filter Status:
Gunakan filter chip di bagian atas untuk menyaring invoice:

| Filter | Keterangan |
|--------|-----------|
| **Semua** | Tampilkan semua invoice |
| **Draft** | Invoice yang masih dalam proses |
| **Sent** | Invoice yang sudah dikirim ke customer |
| **Paid** | Invoice yang sudah dibayar/lunas |

### Aksi pada Setiap Invoice:

| Ikon | Aksi | Kapan Muncul |
|------|------|-------------|
| 📤 **Send** | Ubah status Draft → Sent | Saat status = Draft |
| ✅ **Paid** | Ubah status Sent → Paid | Saat status = Sent |
| ↩️ **Undo** | Kembalikan status Paid → Draft | Saat status = Paid |
| 📋 **Duplicate** | Gandakan invoice (nama + "-Clone") | Selalu |
| ✏️ **Edit** | Edit isi invoice | Selalu |
| 🗑️ **Hapus** | Hapus invoice permanen | Selalu |

### Alur Status:

```
┌─────────┐    📤 Send    ┌─────────┐    ✅ Paid    ┌─────────┐
│  Draft  │ ────────────→ │  Sent   │ ────────────→ │  Paid   │
│(abu-abu)│               │ (oranye)│               │ (hijau) │
└─────────┘               └─────────┘               └─────────┘
     ↑                                                    │
     │                    ↩️ Undo                          │
     └────────────────────────────────────────────────────┘
```

### Fitur Duplicate:
- Tap ikon 📋 pada invoice yang ingin digandakan
- Salinan akan dibuat dengan nomor invoice + **"-Clone"**
- Status otomatis menjadi **Draft**
- Semua item, data company, dan customer ikut tersalin

---

## 7. Template PDF

Tersedia 4 template PDF bawaan dan kemampuan membuat hingga 3 template custom.

### Cara Mengakses:
1. Dashboard → **"Template PDF"**
2. Lihat daftar template bawaan dan template custom

### Template Custom:
- Tap **"Buat Baru"** untuk membuat template custom dengan drag & drop builder
- Maksimal **3 template custom**
- Template custom bisa diedit dan dihapus

---

## 8. Pengaturan

Halaman pengaturan untuk konfigurasi global aplikasi.

---

## 🎨 Template PDF yang Tersedia

| # | Template | Karakteristik |
|---|----------|--------------|
| 1 | **Classic** | Header navy full-width, tabel profesional, cocok untuk semua industri |
| 2 | **Modern** | Tampilan minimalis dengan garis vertikal aksen, kesan modern |
| 3 | **Corporate** | Header 2-baris bold, kesan elegan dan korporat |
| 4 | **Clean Elegant** | Garis tipis, tipografi besar, sangat elegan dan bersih |

### Elemen yang Muncul di Setiap Template:
- ✅ Header perusahaan (nama, cabang, slogan, alamat, telepon)
- ✅ Nomor & tanggal dokumen
- ✅ Bagian "KEPADA:" (Perusahaan, Nama, Alamat, No. Telp)
- ✅ Teks pembuka (opsional)
- ✅ Tabel item (No, Nama Barang, Qty, Satuan, Harga Satuan, Total)
- ✅ Summary (Subtotal, PPN, TOTAL)
- ✅ Terbilang
- ✅ Catatan & Syarat Pembayaran
- ✅ Tanda tangan
- ✅ Nomor halaman (multi-page support)

---

## 📑 Tipe Dokumen

| Tipe | Prefix Otomatis | Kegunaan |
|------|----------------|---------|
| **Invoice** | INV- | Tagihan resmi |
| **Penawaran Harga** | PH- | Penawaran harga ke calon customer |
| **Quotation** | QT- | Penawaran harga (Bahasa Inggris) |
| **Proforma Invoice** | PI- | Invoice sementara sebelum pembayaran |

---

## 💡 Tips & Trik

### Umum
- **Pull-to-refresh** di Dashboard dan Daftar Invoice untuk memperbarui data
- Nomor invoice di-**auto-generate** berdasarkan tanggal, tapi bisa diedit manual
- Gunakan fitur **Duplicate** untuk mempercepat pembuatan invoice serupa

### Kepada (Penerima)
- Untuk **perorangan**: kosongkan field "Nama Perusahaan" di data Customer
- Untuk **perusahaan**: isi field "Nama Perusahaan" agar muncul baris "Perusahaan" di PDF
- Field **ATTN** di form invoice digunakan untuk menimpa nama penerima di PDF (berguna jika penerima berbeda dari PIC yang tersimpan)

### Pajak
- Set PPN ke **0** jika tidak ingin menampilkan pajak
- Gunakan toggle **"Sembunyikan Pajak"** untuk tetap menghitung tapi tidak menampilkan di PDF
- Gunakan toggle **"Sembunyikan Subtotal"** jika hanya ingin menampilkan TOTAL saja

### PDF
- Setiap template mendukung **multi-page** secara otomatis (item banyak akan lanjut ke halaman berikutnya)
- Gunakan fitur **Share** untuk mengirim PDF langsung via WhatsApp, Email, Google Drive, dll
- Gunakan fitur **Print** untuk mencetak langsung ke printer

---

## 🛠️ Teknologi yang Digunakan

| Teknologi | Kegunaan |
|-----------|---------|
| **Flutter** | Framework UI cross-platform |
| **Riverpod** | State management |
| **Isar** | Database lokal (NoSQL) |
| **pdf / printing** | Pembuatan & preview PDF |
| **share_plus** | Fitur berbagi file |
| **path_provider** | Akses direktori penyimpanan |
| **intl** | Format tanggal & mata uang (Bahasa Indonesia) |

---

## 📁 Struktur Project

```
lib/
├── core/
│   ├── pdf_engine/          # Engine pembuatan PDF
│   │   ├── pdf_builder.dart # Builder utama (4 template)
│   │   ├── template_models.dart
│   │   └── default_templates.dart
│   ├── providers/           # Riverpod providers
│   ├── repositories/        # Akses database
│   └── theme.dart           # Tema aplikasi
├── database/
│   └── models/              # Model data (Isar collections)
│       ├── invoice.dart
│       ├── company.dart
│       ├── customer.dart
│       ├── template.dart
│       ├── settings.dart
│       └── history.dart
├── features/
│   ├── dashboard/           # Halaman utama
│   ├── invoice/             # Form, List, Preview invoice
│   ├── company/             # CRUD company
│   ├── customer/            # CRUD customer
│   ├── template/            # Kelola template
│   ├── builder/             # Drag & drop template builder
│   └── settings/            # Pengaturan
├── services/
│   └── calculation_service.dart  # Kalkulasi & terbilang
└── main.dart
```

---

## 📝 Lisensi

Private project — All rights reserved.
