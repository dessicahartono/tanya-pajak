# Struktur File TanyaPajak

Catatan ini menjelaskan isi tiap file di proyek. Bagian yang paling penting ada di
`training-ml/`, `backend/`, dan `lib/`, karena di situ kode yang kami tulis sendiri.
Folder `android/`, `ios/`, dan `macos/` kebanyakan dibuat otomatis oleh Flutter, jadi
cukup dijelaskan singkat.

```
tanyapajak/
├── training-ml/
│   ├── TanyaPajak.ipynb
│   └── dataset-tanyapajak.csv
├── backend/
│   ├── main.py
│   ├── requirements.txt
│   ├── tanyapajak_lengkap.joblib
│   └── venv/
├── lib/
│   ├── main.dart
│   ├── config.dart
│   ├── theme.dart
│   ├── data/topics.dart
│   ├── models/chat_message.dart
│   ├── models/prediction.dart
│   ├── services/tanya_pajak_service.dart
│   ├── screens/home_screen.dart
│   ├── screens/chat_screen.dart
│   ├── widgets/common.dart
│   └── widgets/chat_widgets.dart
├── assets/google_fonts/
├── test/topics_test.dart
├── test/prediction_test.dart
├── docs/
│   ├── summary.md
│   └── struktur-file.md
├── android/  ios/  macos/  web/
├── pubspec.yaml  pubspec.lock  analysis_options.yaml
└── README.md  .gitignore
```

## Alur singkat

Pengguna mengetik pertanyaan di aplikasi Flutter. Pertanyaan dikirim ke
`POST /predict` di backend. Backend membersihkan teksnya, lalu penyaring mengecek
apakah pertanyaannya soal pajak. Kalau bukan, backend langsung menolak dengan sopan.
Kalau soal pajak, model menebak topiknya. Kalau model cukup yakin (confidence minimal
0.5), backend mencari FAQ yang paling mirip di topik itu, dan kalau tidak ada yang
cukup mirip, pencarian diulang di semua topik. Kalau kurang yakin, aplikasi
menampilkan tiga saran topik. Pengguna bisa memilih salah satunya, lalu aplikasi
memanggil `GET /jawaban/{topik}` sambil mengirim lagi pertanyaan aslinya.

## training-ml/

Folder yang dikumpulkan sebagai Project Final. Isinya cuma boleh satu notebook dan satu
CSV.

### TanyaPajak.ipynb

Seluruh proses dari eksplorasi data, pra-pemrosesan, pembagian data, perbandingan
model, sampai evaluasi. Bagian 8 berisi model akhir, penyaring pertanyaan di luar
pajak (8.1), pencarian jawaban (8.2 sampai 8.4), penyimpanan paket untuk backend
(8.5), evaluasi dengan 85 pertanyaan bebas (8.6), dan daftar celah FAQ (8.7). Notebook
bisa dijalankan di Colab maupun di komputer sendiri, dan di akhir menyimpan
`tanyapajak_lengkap.joblib`.

### dataset-tanyapajak.csv

848 baris: 777 pertanyaan pajak dalam 11 topik (FAQ asli, parafrase, variasi, dan
pertanyaan buatan) ditambah 71 contoh pertanyaan bukan pajak (V418 sampai V488, topik
`Di luar pajak`) yang hanya dipakai untuk melatih penyaring. Kolom `jawaban` diisi
untuk 359 FAQ.

## backend/

### main.py

Seluruh kode API ada di file ini. Isinya kira-kira begini, urut dari atas:

1. **Load model.** File `tanyapajak_lengkap.joblib` di-load sekali waktu server
   dinyalakan. Path-nya bisa diganti lewat env `TANYAPAJAK_MODEL`, berguna untuk
   mencoba joblib lain tanpa menimpa yang aktif. Nilai ambang (`AMBANG`,
   `KEMIRIPAN_MIN`, `AMBANG_PENYARING`), bobot pencarian (`BOBOT`), penyaring, kamus
   normalisasi, dan stopwords juga diambil dari file itu, jadi semuanya sama persis
   dengan yang dipakai di notebook.
2. **`bersihkan(teks)`.** Preprocessing yang sama dengan waktu training:
   - huruf kecil
   - menyatukan "e-filing" / "e filing" jadi "efiling" (juga efaktur, ebilling, dll.)
   - memisahkan huruf dan angka ("pph21" jadi "pph 21")
   - membuang tanda baca
   - normalisasi singkatan dan kata gaul ("gmn" jadi "bagaimana", "telat" jadi
     "terlambat"). Hasilnya boleh dua kata ("deadline" jadi "batas waktu")
   - membuang stopwords
   - stemming pakai Sastrawi

   Hasil stemming per kata disimpan di cache (`lru_cache`), karena Sastrawi
   lumayan lambat.
3. **`cari_faq(teks, topik)`.** Mengubah pertanyaan jadi vektor TF-IDF (gabungan
   level kata dan level huruf). Skor tiap FAQ = 0,6 × kemiripan dengan pertanyaan FAQ
   atau variasinya (diambil yang tertinggi) + 0,4 × kemiripan dengan teks jawabannya.
   Kalau `topik` diisi, yang dicari cuma FAQ di topik itu. Kalau `None`, semua FAQ.
   Hasilnya 3 FAQ teratas.
4. **`susun_jawaban(...)`.** Mencari di topik tebakan dulu, lalu di semua topik kalau
   skornya di bawah `KEMIRIPAN_MIN` (0.40). Pencarian ulang di semua topik ini bisa
   dimatikan lewat `ulang_semua_topik=False`, dipakai oleh `/jawaban/{topik}`. FAQ teratas jadi jawaban utama, dua
   sisanya jadi "pertanyaan terkait". Kalau jawabannya cuma rujukan ke berkas di
   halaman sumber, link sumbernya ditambahkan di akhir jawaban. Kalau skornya tetap di
   bawah ambang, yang dikirim pesan bahwa pertanyaannya belum ada di FAQ beserta
   arahan ke Kring Pajak 1500200 atau pajak.go.id, dan `faq_ditemukan` diisi `false`
   supaya aplikasi menampilkan tombol teleponnya.
5. **Endpoint.** Semua endpoint mengizinkan CORS dari asal mana pun, supaya versi web
   Flutter (yang jalan di port lain) boleh memanggilnya.
   - `GET /` untuk cek server hidup, sekaligus menampilkan daftar topik.
   - `POST /predict` untuk endpoint utama. Urutannya: penyaring dulu (kalau peluang
     bukan pajak minimal 0.5, `topik` diisi "Di luar pajak", `saran_topik` dikosongkan,
     dan jawabannya pesan penolakan yang sopan), lalu cek `KOSAKATA` (kalau tidak ada
     satu kata pun yang dikenal model, misalnya "halo", confidence dibuat 0 dan
     `saran_topik` dikosongkan), baru tebak topik dan cari FAQ. Kalau confidence di
     bawah ambang, FAQ langsung dicari di semua topik, tapi aplikasi tetap
     menampilkan layar "kurang yakin" karena tampilannya ditentukan dari confidence.
   - `GET /jawaban/{topik}?pertanyaan=...` dipakai waktu pengguna memilih saran
     topik. FAQ dicari pakai pertanyaan asli pengguna, tapi hanya di topik yang
     dipilih, dan tidak pindah ke topik lain. Ambangnya sama dengan `/predict`
     (0.40). Kalau tidak ada FAQ yang cukup mirip, yang dikirim pesan bahwa
     pertanyaannya belum ada di FAQ beserta arahan ke Kring Pajak, sama seperti di
     `/predict`. Dulu endpoint ini selalu memberi jawaban (kalau tidak ada yang mirip,
     pencarian memakai nama topiknya), sehingga pertanyaan yang FAQ-nya tidak ada
     tetap dapat jawaban.

### tanyapajak_lengkap.joblib

Hasil ekspor dari notebook (sekitar 1,4 MB). Isinya satu dictionary:

| Kunci | Isi |
|---|---|
| `model_topik` | Pipeline TF-IDF (unigram + bigram) + LinearSVC, dibungkus `CalibratedClassifierCV` supaya bisa mengeluarkan probabilitas |
| `model_penyaring` | Model pajak/bukan pajak dengan bentuk yang sama, dilatih dengan 777 pertanyaan pajak dan 71 contoh bukan pajak |
| `ambang_keyakinan` | Batas confidence topik, 0.5 |
| `ambang_penyaring` | Batas peluang bukan pajak, 0.5 |
| `kemiripan_min` | Batas skor FAQ, 0.40 |
| `bobot_pertanyaan` | Bobot kemiripan pertanyaan di skor FAQ, 0.6 (sisanya untuk jawaban) |
| `vec_kata`, `vec_huruf` | Dua TF-IDF vectorizer untuk pencarian FAQ, dipelajari dari pertanyaan dan jawaban FAQ |
| `M_indeks` | Matriks TF-IDF dari 598 pertanyaan FAQ dan variasinya |
| `M_jawaban` | Matriks TF-IDF dari teks jawaban 359 FAQ |
| `indeks` | Tabel yang menghubungkan tiap baris `M_indeks` ke `faq_id` dan topiknya |
| `faq` | 359 FAQ dari pajak.go.id (pertanyaan, topik, jawaban, link sumber) |
| `normalisasi` | Kamus kata gaul / singkatan (84 kata) |
| `stopwords` | 813 stopwords |

Ada 11 topik: NPWP, e-Filing, SPT Tahunan, PPh 21, PPN, Sanksi & Denda, EFIN,
Kode Billing, Coretax, e-SPT, dan Umum. Topik yang FAQ-nya paling banyak adalah PPN
(81). Yang paling sedikit Kode Billing (9).

### requirements.txt

Daftar library Python beserta versinya. Versi scikit-learn sengaja dikunci di 1.6.1
karena harus sama dengan versi yang dipakai menjalankan notebook, kalau tidak, file
joblib bisa gagal di-load.
`PySastrawi` dipakai untuk stemming.

### venv/ dan \_\_pycache\_\_/

`venv/` adalah virtual environment Python, tempat semua library di atas terpasang.
`__pycache__/` berisi hasil compile Python. Keduanya dibuat otomatis, tidak perlu
diubah, dan sudah masuk `.gitignore`.

## lib/

### main.dart

Titik awal aplikasi. Isinya memasang tema dan membuka `HomeScreen`. Di sini juga
`GoogleFonts.config.allowRuntimeFetching` dimatikan, supaya font tidak pernah
diunduh dari internet (lihat `assets/google_fonts/` di bawah).

### config.dart

Pengaturan yang mungkin perlu diganti:

- `apiBaseUrl`: alamat backend. Urutannya: kalau aplikasi di-build dengan
  `--dart-define=API_URL=...`, alamat itu yang dipakai. Kalau tidak, versi web memakai
  host yang sama dengan halamannya (port 8000), emulator Android otomatis `10.0.2.2`
  (alamat laptop dari dalam emulator), dan platform lain `127.0.0.1`. Kalau aplikasi
  native dicoba di HP langsung, ganti dengan IP laptop. Versi web dicek paling awal,
  karena di browser HP Android `defaultTargetPlatform` juga bernilai android.
- `confidenceThreshold`: 0.5, harus sama dengan `ambang_keyakinan` di backend.

### theme.dart

Warna dan font aplikasi. Semua warna dikumpulkan di kelas `AppColors` supaya
gampang diganti dari satu tempat. Font-nya Plus Jakarta Sans, dipasang lewat
`google_fonts`, tapi file-nya diambil dari `assets/google_fonts/`.

### data/topics.dart

Data untuk beranda:

- `topics`: 10 tombol topik. Masing-masing punya ikon dan satu pertanyaan
  pembuka yang langsung dikirim waktu tombolnya diketuk. Topik "Umum" sengaja
  tidak dibuatkan tombol.
- `exampleQuestions`: tiga contoh pertanyaan di bagian "Coba tanyakan".

### models/prediction.dart

Kelas `Prediction` untuk menampung hasil dari API (topik, confidence, jawaban,
link sumber, saran topik, pertanyaan terkait). `fromJson` menerjemahkan nama field
backend yang berbahasa Indonesia ke nama field di Dart.

### models/chat_message.dart

Kelas `ChatMessage` untuk satu pesan di layar chat. Bisa berupa pesan pengguna,
balasan bot (berisi `Prediction`), atau tanda loading.

### services/tanya_pajak_service.dart

Bagian yang berkomunikasi dengan backend. `ApiTanyaPajakService` punya dua method:
`ask()` memanggil `POST /predict`, dan `answerForTopic()` memanggil
`GET /jawaban/{topik}`. Timeout-nya 15 detik. Respons di-decode sebagai UTF-8
supaya huruf atau simbol khusus di jawaban FAQ tidak berubah jadi karakter aneh.

### screens/home_screen.dart

Beranda. Isinya judul, grid 10 topik, contoh pertanyaan, kolom input, dan tombol
info "Tentang TanyaPajak". Apa pun yang diketuk atau diketik akan membuka
`ChatScreen` dengan pertanyaan itu.

### screens/chat_screen.dart

Layar percakapan. Hal-hal yang diatur di sini:

- menyimpan daftar pesan dan otomatis scroll ke bawah
- `_run()` menampilkan loading, memanggil service, lalu mengganti loading
  dengan jawaban. Kalau gagal (misalnya backend mati), muncul snackbar "Gagal
  terhubung ke server".
- `_busy` mencegah pertanyaan baru dikirim sebelum jawaban sebelumnya datang.
- `_buildMessage()` memilih kartu yang ditampilkan: `AnswerCard` kalau
  confidence ≥ 0.5, `FallbackCard` kalau di bawah itu.
- tombol "Tulis ulang pertanyaan" mengisi lagi kolom input dengan pertanyaan
  terakhir.

Angka confidence tidak pernah ditampilkan ke pengguna, hanya dipakai untuk memilih
tampilan.

### widgets/common.dart

Widget yang dipakai di beranda dan di chat:

- `QuestionInput`: kolom ketik + tombol kirim bulat.
- `PillButton`: tombol lonjong untuk contoh pertanyaan dan pertanyaan terkait.
- `SectionLabel`: judul bagian kecil berhuruf kapital.

### widgets/chat_widgets.dart

Widget khusus layar chat:

- `UserBubble`: gelembung biru di kanan untuk pertanyaan pengguna.
- `TypingCard`: kartu "Mencari jawaban..." selama menunggu API.
- `AnswerCard`: label topik, isi jawaban, link sumber ke pajak.go.id, tombol
  jempol atas/bawah, dan tombol pertanyaan terkait di bawahnya. Tombol jempol
  saat ini hanya menampilkan ucapan terima kasih. Masukannya belum dikirim ke
  mana-mana. Kalau FAQ-nya tidak ketemu (`faqFound` false), link sumber dan
  tombol jempol diganti tombol Kring Pajak dan tombol tulis ulang.
- `FallbackCard`: muncul kalau model kurang yakin. Isinya saran topik, tombol
  telepon Kring Pajak 1500200, dan tombol tulis ulang. Kalau saran topiknya
  kosong, judulnya berubah jadi "belum paham" plus contoh kata kunci pajak.
- `openLink()`: membuka link atau nomor telepon di aplikasi luar.

## assets/google_fonts/

File font Plus Jakarta Sans untuk 5 ketebalan yang dipakai di aplikasi: Regular
(400), Medium (500), SemiBold (600), Bold (700), dan ExtraBold (800). Dengan file
ini, tampilan aplikasi tetap sesuai desain walaupun tidak ada internet, misalnya
waktu wifi bermasalah saat demo.

Nama file harus tetap seperti ini (misalnya `PlusJakartaSans-Bold.ttf`), karena
`google_fonts` mencocokkan font berdasarkan nama file. Kalau nanti ada teks yang
memakai ketebalan lain, misalnya `w300`, file-nya harus ditambahkan juga
(`PlusJakartaSans-Light.ttf`). Kalau tidak, aplikasi akan error, karena pengunduhan
font dari internet sudah dimatikan. `OFL.txt` adalah lisensi font-nya (SIL Open Font
License), dan wajib ikut disertakan.

## test/topics_test.dart

Test sederhana yang memastikan beranda punya 10 topik. Jalankan dengan
`flutter test`.

## test/prediction_test.dart

Mengecek `Prediction.fromJson` membaca `faq_ditemukan` dan `saran_topik` yang
kosong dengan benar. Kalau `faq_ditemukan` tidak dikirim backend, nilainya
dianggap `true`.

## File konfigurasi di root

- `pubspec.yaml`: nama proyek dan dependency Flutter (`google_fonts`,
  `url_launcher`, `http`, dan `flutter_lints` untuk pengecekan kode).
- `pubspec.lock`: versi persis tiap package hasil `flutter pub get`. Dibuat
  otomatis.
- `analysis_options.yaml`: aturan lint untuk `flutter analyze`. Folder platform
  dan `build/` dikecualikan dari pengecekan.
- `.gitignore`: daftar file yang tidak ikut ke git (build, cache, `venv`, dll.).
- `README.md`: cara menjalankan notebook, backend, dan aplikasi.
- `.metadata`, `.flutter-plugins-dependencies`, `tanyapajak.iml`: dibuat Flutter
  dan IDE, tidak perlu disentuh.

## Folder platform

Semua folder di bawah ini dibuat oleh `flutter create`. Hanya beberapa file yang
kami ubah.

### android/

- `app/src/main/AndroidManifest.xml`: nama aplikasi "TanyaPajak", izin
  `INTERNET`, dan `usesCleartextTraffic="true"`. Izin terakhir ini perlu karena
  backend memakai `http://`, bukan `https://`, dan Android memblokir koneksi
  http biasa secara default.
- `app/src/main/kotlin/.../MainActivity.kt`: activity bawaan Flutter.
- `app/src/main/res/`: ikon aplikasi dan tampilan splash screen.
- `app/src/debug/` dan `app/src/profile/`: manifest tambahan untuk mode debug.
- `build.gradle.kts`, `settings.gradle.kts`, `gradle.properties`, `gradlew`:
  konfigurasi build Android. `applicationId`-nya masih `com.example.tanyapajak`.
- `local.properties`: lokasi Android SDK dan Flutter SDK di laptop ini. Isinya
  berbeda di tiap komputer.

### ios/

- `Runner/Info.plist`: nama aplikasi yang tampil di HP ("TanyaPajak") dan
  pengaturan lain.
- `Runner/AppDelegate.swift`, `SceneDelegate.swift`: kode pembuka aplikasi
  bawaan Flutter.
- `Runner/Assets.xcassets`, `Base.lproj/`: ikon, gambar splash, dan storyboard.
- `Runner.xcodeproj`, `Runner.xcworkspace`: proyek Xcode.
- `Flutter/`: konfigurasi build dari Flutter. Isi folder `ephemeral/` dibuat
  ulang setiap kali build.

### macos/

Mirip dengan `ios/`. Yang perlu diperhatikan adalah `DebugProfile.entitlements`
dan `Release.entitlements`. Keduanya berisi izin `network.client`. Tanpa izin itu,
aplikasi macOS tidak bisa memanggil backend karena macOS menjalankan aplikasi di
sandbox.

### web/

Ditambahkan supaya aplikasi bisa dijalankan di browser. Isinya `index.html`,
`manifest.json` (nama aplikasi "TanyaPajak" dan warna tema), `favicon.png`, dan ikon
di `icons/` (masih ikon bawaan Flutter). Hasil `flutter build web` masuk ke
`build/web/`, dan folder itulah yang disajikan ke browser. Supaya browser boleh
memanggil backend dari port lain, `backend/main.py` memasang `CORSMiddleware`.

## Folder yang dibuat otomatis

`build/`, `.dart_tool/`, dan `.idea/` berisi hasil build, cache Dart, dan
pengaturan IDE. Folder-folder ini boleh dihapus kapan saja dan akan dibuat ulang
waktu `flutter run`. Sudah masuk `.gitignore` juga.
