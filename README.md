# TanyaPajak

Proyek akhir mata kuliah AI. Aplikasinya buat tanya-jawab seputar pajak: pertanyaan
pengguna disaring dulu (pajak atau bukan), lalu diklasifikasi topiknya, terus dicari
FAQ pajak.go.id yang paling mirip. Kalau FAQ-nya tidak ada atau pertanyaannya bukan
soal pajak, sistem bilang terus terang dan mengarahkan ke Kring Pajak 1500200.

Isinya tiga bagian. Folder `training-ml/` berisi notebook dan dataset (ini yang
dikumpulkan sebagai Project Final). Folder `backend/` berisi API FastAPI yang memuat model
`tanyapajak_lengkap.joblib` hasil notebook. Folder `lib/` berisi aplikasi Flutter-nya.

## Notebook

`training-ml/TanyaPajak.ipynb` bisa dijalankan di Google Colab atau di komputer
sendiri. Di Colab, dataset dibaca dari Drive
(`MyDrive/ArtificialIntelligenceALP/dataset-tanyapajak.csv`). Di komputer sendiri,
dataset dibaca dari folder yang sama dengan notebook. Kalau jalan di komputer sendiri,
selain library di `backend/requirements.txt` perlu juga `jupyter`, `matplotlib`, dan
`seaborn`.

Di akhir, notebook menyimpan `tanyapajak_lengkap.joblib`. Kalau dataset atau notebook
diubah, file ini yang disalin ke `backend/`.

## Backend

Pakai Python 3.13 dan scikit-learn 1.6.1. Versi scikit-learn harus sama dengan yang
dipakai waktu menjalankan notebook, kalau beda model bisa gagal di-load.

```bash
cd backend
python3.13 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

Kalau sudah jalan, buka http://127.0.0.1:8000/docs untuk coba endpoint-nya.

Ada dua endpoint yang dipakai aplikasi:

- `POST /predict` dengan body `{"pertanyaan": "..."}`
- `GET /jawaban/{topik}?pertanyaan=...`, dipanggil kalau pengguna memilih salah satu
  saran topik. Pertanyaan aslinya ikut dikirim, lalu FAQ dicari hanya di topik yang
  dipilih dengan ambang skor yang sama (0.40). Kalau tidak ada yang cukup mirip,
  jawabannya tetap ditolak dengan jujur

Contoh respons `/predict`:

```json
{"topik": "EFIN", "confidence": 0.92, "jawaban": "...", "sumber": "https://...",
 "label_sumber": "Sumber: FAQ pajak.go.id", "saran_topik": ["EFIN", "e-Filing", "PPN"],
 "pertanyaan_terkait": ["..."], "faq_ditemukan": true}
```

Urutan yang dicek backend:

1. Kalau penyaring menilai pertanyaannya bukan soal pajak (peluang minimal 50%),
   `topik` diisi `"Di luar pajak"`, `saran_topik` dikosongkan, dan jawabannya pesan
   sopan yang mengarahkan ke Kring Pajak atau pajak.go.id.
2. Kalau tidak ada satu kata pun yang dikenal model (misalnya "halo"), `saran_topik`
   dikosongkan dan aplikasi cuma minta pengguna menulis ulang pertanyaannya.
3. Kalau confidence topiknya di bawah 0.5, aplikasi menampilkan layar "kurang yakin"
   berisi tiga saran topik dan tombol Kring Pajak.
4. Kalau topiknya yakin, FAQ dicari di topik itu. Kalau tidak ada yang skornya minimal
   0.40, pencarian diulang di semua topik. Kalau tetap tidak ada, `faq_ditemukan`
   bernilai `false` dan aplikasi menampilkan tombol Kring Pajak di kartu jawaban.

Untuk mencoba joblib lain tanpa menimpa yang aktif, isi env `TANYAPAJAK_MODEL` dengan
path file joblib-nya sebelum menjalankan server.

## Aplikasi Flutter

Nyalakan backend dulu, baru di terminal lain:

```bash
flutter pub get
flutter run
```

Alamat API diatur di `lib/config.dart` dan sudah otomatis: `10.0.2.2` untuk
emulator Android, `127.0.0.1` untuk macOS dan simulator iOS. Kalau dites
di HP langsung, ganti dengan IP laptop (HP dan laptop harus satu wifi).

### Versi web

Aplikasi juga bisa dijalankan di browser, jadi tidak harus pakai macOS. Backend
tetap harus nyala dengan `--host 0.0.0.0` seperti di atas.

```bash
# coba cepat di Chrome
flutter run -d chrome

# atau build sekali, lalu buka dari browser mana pun di wifi yang sama
flutter build web
python3 -m http.server 5000 -d build/web
```

Setelah itu buka http://localhost:5000 di laptop, atau http://IP-laptop:5000 dari HP.
Versi web otomatis memanggil backend di host yang sama dengan halamannya (port 8000),
jadi alamat API tidak perlu diganti. Backend sudah mengizinkan CORS supaya browser
boleh memanggilnya.

Kalau backend nanti di-deploy ke server, build dengan alamatnya:

```bash
flutter build web --dart-define=API_URL=https://alamat-backend
```

Kalau halaman web-nya dibuka lewat `https://`, backend juga harus `https://`, karena
browser memblokir panggilan dari halaman https ke alamat http. Tombol telepon Kring
Pajak di browser laptop biasanya tidak bisa membuka aplikasi telepon, jadi yang muncul
pesan "Tidak bisa membuka tel:1500200". Di browser HP tombolnya tetap jalan.

## Contoh pertanyaan buat demo

- "lapor spt online gmn ya?" masuk ke topik e-Filing dan dapat langkah lapor SPT
- "lupa efin gimana?" masuk ke topik EFIN
- "ptkp tahun ini berapa" FAQ-nya tidak ada, jadi sistem bilang terus terang dan
  muncul tombol Kring Pajak
- "cara bikin akun instagram baru" ditolak penyaring karena bukan soal pajak
- "bayar pajak online" keyakinannya 0.45, jadi muncul layar "kurang yakin" dengan tiga
  saran topik
- "resep nasi goreng enak" tidak ada kata yang dikenal, jadi muncul pesan "belum paham"
