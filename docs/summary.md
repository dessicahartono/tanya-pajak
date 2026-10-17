# Kekurangan, Perbaikan, dan Evaluasi TanyaPajak

Catatan ini merangkum kekurangan yang ketemu waktu aplikasi dites langsung ke backend,
perbaikan yang sudah dilakukan beserta angka sebelum dan sesudahnya, kekurangan yang
masih tersisa, dan rencana pengembangannya. Semua contoh di bawah adalah hasil asli
dari server, bukan perkiraan.

Setelah sistem dua tahap jadi, saya coba ke server dengan pertanyaan-pertanyaan yang
biasa diketik orang. Ternyata masalahnya bukan cuma jawaban yang kurang tepat. Ada
pertanyaan yang FAQ-nya tidak ada tapi tetap dijawab dengan yakin, misalnya "berapa
tarif ppn sekarang" dijawab dengan FAQ soal tarif untuk NIK sebagai NPWP, dan "siapa
presiden pertama indonesia" dijawab dengan FAQ tax ratio Indonesia. Untuk urusan
pajak, ini lebih bahaya daripada tidak menjawab. Jadi targetnya saya ubah: pertanyaan
yang ada di FAQ harus dijawab benar walaupun ditulis santai atau salah ketik, sedangkan
pertanyaan di luar FAQ atau di luar pajak harus ditolak dengan jujur dan diarahkan ke
Kring Pajak 1500200 atau pajak.go.id.

Semua perbaikan tetap memakai machine learning klasik (TF-IDF dan SVM dari
scikit-learn) ditambah aturan dan kamus buatan sendiri. Tidak ada LLM, API AI, atau
model pretrained.

## Status singkat

| No | Kekurangan | Yang sudah dikerjakan | Status |
|---|---|---|---|
| 1 | Cakupan FAQ masih terbatas | Daftar celah FAQ disusun (notebook bagian 8.7) | FAQ-nya belum ditambahkan |
| 2 | Pencarian FAQ berbasis kata, jadi bisa salah pilih | Set uji bebas, kamus normalisasi, teks jawaban ikut dicocokkan, ambang dipilih dari data | Salah jawab turun dari 9 ke 4, penolakan naik dari 20% ke 60% |
| 3 | Belum bisa menolak pertanyaan di luar pajak | Penyaring pajak/bukan pajak di depan model topik | Penolakan naik lagi dari 60% ke 70%, salah jawab dari 4 ke 3 |
| 4 | Memilih topik di layar "kurang yakin" selalu dapat jawaban | Ambang skor juga dipakai di `/jawaban/{topik}` | Salah jawab di jalur ini turun dari 6 ke 0 |
| 5 | Pencarian belum memahami makna kalimat | Belum, karena proyek dibatasi ke machine learning klasik | Pengembangan berikutnya |

Angka di tabel berasal dari set_kunci, yaitu 34 pertanyaan bebas yang tidak pernah
dipakai untuk menyetel apa pun (penjelasannya di bawah).

## Cara mengukurnya

Sebelum mengubah apa pun, saya buat dulu set uji berisi 85 pertanyaan yang ditulis
bebas. Isinya pertanyaan santai (47), salah ketik (12), pertanyaan pajak yang FAQ-nya
memang tidak ada di dataset (12), dan pertanyaan bukan pajak (14). Setiap pertanyaan
saya cek kemiripannya ke 777 pertanyaan di dataset, dan yang terlalu mirip saya tulis
ulang. Di draf awal, dua pertanyaan ternyata persis sama dengan baris di dataset,
jadi ikut saya ganti.

Set ini dibagi dua. Set_setel (51 pertanyaan) boleh dipakai untuk menyetel ambang,
kamus, dan bobot. Set_kunci (34 pertanyaan) cuma dipakai sekali di akhir, supaya
angkanya benar-benar menggambarkan pertanyaan baru. Set ini ada di notebook
bagian 8.6 (variabel `UJI_BEBAS`), tidak disimpan sebagai CSV terpisah karena folder
`training-ml/` (yang dikumpulkan sebagai Project Final) cuma boleh berisi satu
notebook dan satu CSV.

Ada empat angka yang saya pantau:
- top-1: pertanyaan yang ada di FAQ dan langsung dijawab dengan FAQ yang benar
- top-3: FAQ yang benar ada di jawaban utama atau dua pertanyaan terkait
- tolak benar: pertanyaan yang seharusnya ditolak dan memang ditolak
- salah jawab: jumlah pertanyaan yang dijawab dengan FAQ yang salah. Ini yang paling
  ingin saya turunkan.

## Perubahan yang sudah dilakukan

### 1. Pencarian bisa pindah ke semua topik, dan jawaban rujukan diberi link

Yang diubah: kalau di topik tebakan tidak ada FAQ yang cukup mirip, atau keyakinan
topiknya di bawah 50%, pencarian diulang di seluruh topik. Selain itu, ada 14 jawaban
di dataset yang isinya cuma rujukan, misalnya "Petunjuk pengisian SPT 1770 SS tersedia
dalam bentuk dokumen PDF yang dapat diunduh dari halaman sumber". Untuk jawaban seperti
ini, link sumbernya sekarang ditambahkan langsung di akhir jawaban.

Alasannya: ada FAQ yang tersimpan di topik lain dari tebakan model. Contohnya FAQ cara
lapor SPT di Coretax ada di topik SPT Tahunan, padahal pertanyaannya ditebak Coretax.
Jawaban rujukan tanpa link juga tidak ada gunanya buat pengguna.

Tujuannya supaya FAQ yang benar tetap bisa ditemukan walaupun topiknya meleset, dan
jawaban rujukan tetap bisa ditindaklanjuti.

Angka: perubahan ini saya buat sebelum set uji ada, jadi sudah termasuk di angka
"awal" pada tabel di bawah.

### 2. Ambang kemiripan dari 0,20 menjadi 0,35

Yang diubah: batas minimal kemiripan supaya sebuah FAQ boleh dipakai sebagai jawaban.

Alasannya: angka 0,20 dulu saya tentukan sendiri, tanpa diukur. Waktu dites, banyak
jawaban salah yang skornya di atas 0,20, misalnya "restitusi pajak caranya" mendapat
FAQ laporan pasca amnesti pajak dengan skor 0,23.

Tujuannya supaya ambang dipilih dari data. Saya pakai 239 variasi (masing-masing
dicari tanpa dirinya sendiri) dan 19 pertanyaan bebas pertama, lalu pilih ambang yang
rata-rata jawaban benar dan penolakannya paling tinggi. Hasilnya 0,35, dengan
rata-rata 0,668, naik dari 0,594 pada ambang 0,20.

| | top-1 | tolak benar | salah jawab |
|---|---|---|---|
| set_setel, sebelum | 0,686 | 0,125 | 16 |
| set_setel, sesudah | 0,686 | 0,188 | 15 |
| set_kunci, sebelum | 0,750 | 0,200 | 9 |
| set_kunci, sesudah | 0,750 | 0,200 | 9 |

Dampaknya kecil. Satu pertanyaan bukan pajak jadi ditolak, tapi di set_kunci tidak
ada perubahan. Ternyata masalahnya bukan cuma soal ambang. Skor jawaban benar dan
jawaban salah banyak yang tumpang tindih, jadi tidak ada satu angka yang bisa
memisahkan keduanya dengan bersih.

### 3. Kamus normalisasi diperluas

Yang diubah: kamus kata tidak baku bertambah dari 35 menjadi 84 kata, misalnya ilang
jadi hilang, dapetin jadi mendapatkan, deadline jadi batas waktu, diundur jadi
ditunda, pake jadi gunakan, kadaluarsa jadi daluwarsa, ttd jadi ditandatangani.
Fungsi `bersihkan()` juga saya ubah supaya satu kata boleh dinormalisasi jadi dua kata
(deadline jadi batas waktu). Kamus ini dipakai sama persis di notebook dan backend,
karena ikut tersimpan di file joblib.

Alasannya: banyak pertanyaan santai yang gagal karena kata kuncinya tidak dikenal.
Contohnya "efin ku ilang, gmn dapetinnya lagi" dijawab dengan definisi EFIN, padahal
FAQ "cara mendapatkan kembali EFIN yang lupa" ada. Lalu "deadline spt tahunan bisa
diundur ga" dijawab dengan "apa yang dimaksud dengan SPT".

Tujuannya supaya bahasa santai diterjemahkan ke kata yang dipakai FAQ resmi. Kata-kata
untuk kamus hanya saya ambil dari data variasi/buatan dan set_setel, tidak dari
set_kunci. Salah ketik seperti "insatller" tidak saya masukkan, karena sudah ditangani
TF-IDF karakter.

| | top-1 | tolak benar | salah jawab |
|---|---|---|---|
| set_setel, sebelum | 0,686 | 0,188 | 15 |
| set_setel, sesudah | 0,829 | 0,188 | 12 |
| set_kunci, sebelum | 0,750 | 0,200 | 9 |
| set_kunci, sesudah | 0,750 | 0,200 | 9 |

Di set_setel kenaikannya besar, tapi di set_kunci tidak ada perubahan sama sekali.
Artinya kamusnya terlalu cocok dengan pertanyaan yang saya pakai untuk menyusunnya.
Justru ini alasan kenapa set_kunci harus dipisahkan. Kalau saya cuma melihat set_setel,
saya akan mengira kamus inilah perbaikan terbesar. Efek sampingnya juga ada: "djp
onlen msh bisa dipake ga skrg", yang sebelumnya masuk layar "kurang yakin", sekarang
dijawab dengan FAQ kode error.

### 4. Teks jawaban ikut dicocokkan, ambang menjadi 0,40

Yang diubah: dulu yang dicocokkan cuma pertanyaan FAQ dan variasinya. Sekarang teks
jawaban FAQ juga ikut dicocokkan, tetap dengan TF-IDF kata dan karakter. Skor FAQ =
0,6 × kemiripan pertanyaan + 0,4 × kemiripan jawaban. Pertanyaan diberi bobot lebih
besar karena gaya bahasanya paling dekat dengan pertanyaan pengguna. Ambang ikut
disetel ulang menjadi 0,40.

Alasannya: setelah kamus, 8 dari 12 salah jawab berasal dari pertanyaan yang
seharusnya ditolak. Contohnya "ptkp tahun ini berapa" dijawab dengan pengertian SPT,
"ppn 12 persen mulai kapan" dijawab dengan FAQ PP UMKM, dan "kartu npwp ilang mau
cetak ulang" dijawab dengan FAQ lupa EFIN. FAQ yang hanya mirip di pertanyaannya
belum tentu isinya membahas hal yang sama.

Tujuannya supaya FAQ yang isinya benar-benar membahas pertanyaan pengguna dapat skor
lebih tinggi, dan FAQ yang cuma kebetulan mirip judulnya dapat skor lebih rendah.
Bobot dan ambang saya pilih dari rata-rata empat ukuran: jawaban benar di 239 variasi,
penolakan di 176 pertanyaan buatan (pertanyaan pajak yang FAQ-nya memang tidak ada),
serta top-1 dan penolakan di set_setel. Jadi pilihannya tidak cuma bergantung pada 51
pertanyaan.

| | top-1 | tolak benar | salah jawab |
|---|---|---|---|
| set_setel, sebelum | 0,829 | 0,188 | 12 |
| set_setel, sesudah | 0,743 | 0,688 | 2 |
| set_kunci, sebelum | 0,750 | 0,200 | 9 |
| set_kunci, sesudah | 0,667 | 0,600 | 4 |

Ini perubahan yang paling berpengaruh, dan hasilnya terlihat juga di set_kunci. Di
set_kunci, "spt nihil gimana caranya", "pajak penghasilan youtuber gimana", dan "pbb
rumah telat bayar dendanya brp" dulu dijawab dengan FAQ yang salah, sekarang ditolak.
Ada harga yang dibayar: top-1 turun, karena beberapa pertanyaan yang sebelumnya
dijawab benar skornya sekarang di bawah 0,40. Contohnya "error winrar pas extract
espt" dan "badan itu definisinya apa menurut aturan pajak". Mereka diarahkan ke Kring
Pajak, jadi tidak mendapat jawaban yang salah. Di sisi pencarian, top-1 pada 239
variasi juga naik dari 61,1% menjadi 65,3%.

### 5. Penyaring pertanyaan di luar pajak

Yang diubah: saya tambah model kecil di depan model topik, khusus untuk membedakan
pajak dan bukan pajak. Modelnya SVM linear dengan TF-IDF, dikalibrasi, dan menolak
kalau peluang bukan pajaknya minimal 50%. Untuk melatihnya, dataset ditambah 71
contoh pertanyaan bukan pajak (V418 sampai V488, topik `Di luar pajak`), misalnya
urusan KTP, paspor, rekening bank, aplikasi HP, dan pertanyaan sehari-hari. Tema yang
ada di set uji (cuaca, wifi, BPJS, kurs, sepak bola, SIM, PLN, dan lainnya) sengaja
tidak saya pakai, supaya hasil uji tetap jujur. Kalau tersaring, backend menjawab
dengan sopan bahwa pertanyaannya di luar topik pajak dan mengarahkan ke Kring Pajak
atau pajak.go.id.

Alasannya: model topik selalu memilih salah satu dari 11 topik pajak, jadi "cara bikin
sim online" ditebak e-Filing dengan keyakinan 0,88. Ambang skor saja tidak cukup untuk
menahan semua pertanyaan seperti ini.

Tujuannya supaya pertanyaan bukan pajak ditolak lebih awal, tanpa mengganggu pertanyaan
pajak.

Awalnya saya coba cara yang lebih sederhana, yaitu menjadikan `Di luar pajak` kelas
ke-12 di SVM topik. Di set_setel penolakannya bahkan 100%, tapi F1 makro cross
validation model topik turun dari 0,863 ke 0,798, jadi target 0,85 tidak tercapai
lagi, dan uji tambahan turun dari 0,955 ke 0,864. Akhirnya saya pilih penyaring
terpisah, supaya model topiknya tetap sama persis.

| | top-1 | tolak benar | salah jawab |
|---|---|---|---|
| set_setel, sebelum | 0,743 | 0,688 | 2 |
| set_setel, sesudah | 0,743 | 0,812 | 2 |
| set_kunci, sebelum | 0,667 | 0,600 | 4 |
| set_kunci, sesudah | 0,667 | 0,700 | 3 |

Penyaringnya sendiri belum kuat. Di cross validation, penyaring hampir tidak pernah
salah menolak pertanyaan pajak (cuma 3 dari 777), tapi baru mengenali 22,5% pertanyaan
bukan pajak yang belum pernah dilihatnya. Contoh bukan pajak memang sangat beragam,
dan TF-IDF cuma kenal kata yang pernah muncul. Untungnya, sisa pertanyaan bukan pajak
biasanya masih tertahan oleh ambang keyakinan atau ambang skor. Di set_kunci,
"cara daftar bpjs kesehatan online" sekarang ditolak oleh penyaring, padahal
sebelumnya dijawab dengan FAQ saluran pendaftaran NPWP.

### 6. Daftar celah FAQ

Yang diubah: ini bukan perubahan sistem, tapi daftar FAQ yang perlu ditambahkan
(notebook bagian 8.7). Sumbernya 176 pertanyaan buatan di dataset dan 7 pertanyaan
"pajak tanpa FAQ" di set_setel. Semuanya dijalankan dengan sistem akhir.

Alasannya: sebagian pertanyaan memang tidak bisa dijawab karena FAQ-nya belum ada,
bukan karena sistemnya salah. Tanpa daftar ini, susah menentukan data apa yang harus
dicari berikutnya.

Hasilnya, dari 182 pertanyaan pajak tanpa FAQ, 123 tidak dijawab, tapi 59 (32%) masih
dijawab dengan FAQ yang kurang tepat. Risiko terbesar ada di Kode Billing: 17 dari 29
pertanyaan dijawab, kebanyakan dengan FAQ "masa daluwarsa kode billing", padahal yang
ditanya cara membuat kode billing, tempat bayar, atau NTPN. Urutan prioritas FAQ yang
perlu dicari di pajak.go.id: Kode Billing, SPT Tahunan (batas waktu, siapa wajib
lapor, kurang/lebih bayar, pembetulan), e-Filing (BPE, kode verifikasi, akun
terkunci), PPh 21 (cara hitung, TER, PTKP), Umum (restitusi, keberatan, jenis pajak),
Sanksi & Denda (denda telat lapor), PPN (tarif, PKP), lalu Coretax, EFIN, dan NPWP.
Pertanyaan soal PBB, BPHTB, dan pajak kendaraan termasuk pajak daerah, jadi lebih
tepat diarahkan ke pemda daripada dibuatkan FAQ DJP.

Jawaban untuk daftar ini sengaja tidak saya tulis sendiri. FAQ resminya dicari di
pajak.go.id, lalu diisi dan diverifikasi bersama praktisi pajak.

### 7. Ambang skor juga dipakai waktu pengguna memilih topik

Yang diubah: endpoint `/jawaban/{topik}`, yang dipanggil waktu pengguna memilih salah
satu saran topik di layar "kurang yakin", sekarang memakai ambang 0,40 yang sama
dengan `/predict`. Pencariannya tetap hanya di topik yang dipilih. Kalau tidak ada
FAQ yang cukup mirip, sistem menolak dengan jujur dan mengarahkan ke Kring Pajak.

Alasannya: dulu endpoint ini selalu memberi jawaban. Kalau pertanyaannya tidak mirip
dengan FAQ mana pun, pencarian memakai nama topiknya saja. Akibatnya semua pengaman
di `/predict` bisa jebol hanya karena pengguna menekan satu tombol. Contohnya "cara
bayar tagihan listrik pln" masuk layar "kurang yakin", lalu kalau pengguna memilih
Kode Billing, jawabannya "masa daluwarsa kode billing adalah 7 hari".

Tujuannya supaya aturan "lebih baik menolak daripada salah jawab" berlaku di semua
jalur, bukan cuma di jawaban pertama.

Angka: saya ambil semua pertanyaan uji (set_setel dan set_kunci) yang masuk layar
"kurang yakin", lalu disimulasikan pengguna memilih topik. Untuk pertanyaan yang ada
FAQ-nya, yang dipilih topik FAQ yang benar. Untuk pertanyaan yang harus ditolak, yang
dipilih saran pertama. Dari 8 pertanyaan yang bisa diuji:

| | dijawab benar atau ditolak dengan benar | salah jawab | ditolak padahal FAQ-nya ada |
|---|---|---|---|
| Sebelum | 2 | 6 | 0 |
| Sesudah | 7 | 0 | 1 |

Yang ditolak padahal FAQ-nya ada adalah "ga kerja tp punya npwp tetep lapor spt?".
Sebelumnya pertanyaan ini dijawab dengan FAQ pengertian SPT, jadi juga belum benar.
Angka di tabel ringkasan di bawah tidak berubah, karena tabel itu hanya mengukur
jawaban pertama dari `/predict`.

### Perubahan teknis lain

- Notebook sekarang bisa dijalankan di Google Colab maupun di komputer sendiri. Kalau
  dijalankan di Colab, dataset dibaca dari Drive. Kalau di komputer sendiri, dataset
  dibaca dari folder yang sama dengan notebook.
- Fungsi jawab di notebook (bagian 8.5) sekarang memakai alur yang sama persis dengan
  backend, jadi angka di notebook sama dengan yang dihasilkan server.
- Pemilihan model, pembagian data, dan evaluasi model topik di bagian 5–7 tidak
  berubah. Satu-satunya perubahan di model topik berasal dari kamus normalisasi, dan
  angkanya bergeser sedikit (F1 CV 0,864 menjadi 0,863, data uji 0,841 menjadi 0,838).

## Ringkasan angka

| Versi | set_setel top-1 | set_setel tolak | set_setel salah | set_kunci top-1 | set_kunci top-3 | set_kunci tolak | set_kunci salah |
|---|---|---|---|---|---|---|---|
| Awal | 0,686 | 0,125 | 16 | 0,750 | 0,958 | 0,200 | 9 |
| Ambang 0,35 | 0,686 | 0,188 | 15 | 0,750 | 0,958 | 0,200 | 9 |
| Kamus diperluas | 0,829 | 0,188 | 12 | 0,750 | 0,958 | 0,200 | 9 |
| Jawaban ikut dicocokkan | 0,743 | 0,688 | 2 | 0,667 | 0,958 | 0,600 | 4 |
| Penyaring (akhir) | 0,743 | 0,812 | 2 | 0,667 | 0,958 | 0,700 | 3 |

Singkatnya, sistem akhir lebih jujur. Di pertanyaan yang belum
pernah dipakai untuk menyetel, salah jawab turun dari 9 menjadi 3 dan penolakan naik
dari 20% menjadi 70%. Harganya, jawaban benar di urutan pertama turun dari 75% menjadi
67%, karena sistem lebih memilih menolak daripada menebak.

Hitungan aslinya begini. Set_kunci berisi 34 pertanyaan:
24 yang FAQ-nya ada, dan 10 yang harus ditolak (5 pertanyaan pajak yang FAQ-nya tidak
ada dan 5 pertanyaan bukan pajak).

- Salah jawab 9 jadi 3 (dari 34 pertanyaan). Di versi awal, 6 pertanyaan yang
  seharusnya ditolak malah dijawab, misalnya "spt nihil gimana caranya" dan "cara
  daftar bpjs kesehatan online", ditambah 3 pertanyaan yang FAQ-nya ada tapi dijawab
  dengan FAQ lain. Di versi akhir sisa 3: "lupa password wifi rumah" (bukan pajak tapi
  dijawab), "cara aktifin lagi npwp yg non efektif", dan "brwoser apa yg bisa dipake
  efiling".
- Penolakan 20% jadi 70% (dari 10 pertanyaan yang harus ditolak). Dulu cuma 2 yang
  ditolak ("cuaca jakarta besok gimana" dan "jadwal liga inggris malam ini"), sekarang
  7. Sisanya 2 masuk layar "kurang yakin" yang juga menampilkan tombol Kring Pajak, dan
  1 dijawab ("lupa password wifi rumah").
- Jawaban benar di urutan pertama 75% jadi 67% (dari 24 pertanyaan yang FAQ-nya ada),
  artinya 18 jadi 16. Tiga pertanyaan yang dulu dijawab benar sekarang ditolak karena
  skornya di bawah 0,40 ("gimana ngecek kita berhak dtp pph21 apa ngga", "badan itu
  definisinya apa menurut aturan pajak", "error winrar pas extract espt"). Sebaliknya,
  satu pertanyaan yang dulu salah sekarang jadi benar ("aktivsi efin pertama kali gmn").

Jumlahnya kecil, jadi satu pertanyaan saja menggeser persentase cukup jauh: sekitar 4%
untuk top-1 dan 10% untuk penolakan. Angka ini lebih tepat dibaca sebagai arah
perubahan, bukan angka pasti.

## Kekurangan yang masih ada

- Jawaban pertama yang tepat baru 67% di set_kunci, dan 3 dari 24 pertanyaan yang
  ada FAQ-nya malah ditolak karena skornya di bawah 0,40. Pencarian dengan TF-IDF cuma
  mencocokkan kata dan potongan huruf, belum memahami makna. Kalimat dengan maksud sama
  tapi kata berbeda dianggap tidak mirip, misalnya "restitusi" dan "pengembalian
  kelebihan bayar", atau "aktifin lagi" dan "mengaktifkan kembali". Contohnya "cara
  aktifin lagi npwp yg non efektif" masih dijawab dengan FAQ "kenapa NPWP non efektif",
  padahal FAQ cara mengaktifkannya ada di urutan kedua.
- FAQ untuk pertanyaan yang sering ditanya belum ada. Dari 182 pertanyaan pajak yang
  FAQ-nya tidak ada, 32% masih dijawab dengan FAQ yang kurang tepat, terutama di Kode
  Billing. Daftar FAQ yang perlu dicari ada di notebook bagian 8.7, dengan urutan
  prioritas Kode Billing, SPT Tahunan, e-Filing, PPh 21, Umum, Sanksi & Denda, PPN,
  lalu Coretax, EFIN, dan NPWP. Jawabannya sengaja tidak ditulis sendiri, karena
  aplikasi menampilkan label "Sumber: FAQ pajak.go.id". FAQ resminya perlu dicari di
  pajak.go.id (jangan lupa isi kolom `sumber` dengan link halamannya), lalu diisi dan
  diverifikasi bersama praktisi pajak. Kalau FAQ resminya memang tidak ada, biarkan
  saja, karena jawaban "belum ada di FAQ" + tombol Kring Pajak sudah jadi perilaku yang
  benar.
- Variasi pertanyaan per FAQ belum ditambah. Kamus normalisasi sudah ditambah, tapi
  `M_indeks` masih berisi 598 baris untuk 359 FAQ. Contohnya "telat lapor spt kena
  denda berapa" sekarang ditolak, padahal FAQ denda tidak lapor SPT (F319) ada. FAQ itu
  memakai kata "tidak lapor", sedangkan pengguna menulis "telat lapor". Yang paling
  perlu ditambah variasinya:

  | FAQ | Variasi yang bisa ditambah |
  |---|---|
  | F319 Sanksi tidak lapor pajak | telat lapor spt kena denda, denda terlambat lapor spt berapa |
  | F321 Cara mengaktifkan kembali NPWP non efektif | npwp non efektif mau diaktifin lagi |

  Jangan memakai kalimat dari set uji sebagai variasi. Kalau dipakai, hasil uji jadi
  terlalu bagus dan tidak bisa dipercaya lagi.
- Penyaring masih lemah. Penyaring baru mengenali sekitar seperempat pertanyaan
  bukan pajak yang belum pernah dilihatnya. "lupa password wifi rumah" masih lolos dan
  dijawab dengan FAQ lupa password DJP Online. Contoh bukan pajak perlu diperbanyak,
  terutama yang memakai kata khas pajak seperti "lupa password", "bayar", atau "daftar
  online".
- Pajak daerah belum ditangani khusus. Pertanyaan soal PBB, BPHTB, dan pajak
  kendaraan bukan wewenang DJP, jadi lebih tepat diarahkan ke pemda daripada dibuatkan
  FAQ DJP.
- Set uji masih kecil. Set uji bebas cuma 85 pertanyaan (rencana awal 100) dan saya
  tulis sendiri, jadi gaya bahasanya belum tentu mewakili semua pengguna. Set_kunci
  cuma 34 pertanyaan, jadi satu pertanyaan saja sudah menggeser angka sekitar 3–4%.
- Data dikumpulkan manual. Sebagian FAQ sudah lama (misalnya aturan sanksi tahun
  2015), dan jawaban yang ditampilkan masih ringkasan dari halaman sumber.

## Catatan teknis: ekspor dan pasang model

Setiap kali dataset atau notebook diubah, notebook dijalankan ulang sampai akhir, lalu
file `tanyapajak_lengkap.joblib` hasilnya disalin ke `backend/`.

```python
joblib.dump(paket, 'tanyapajak_lengkap.joblib', compress=3)
```

- Pastikan scikit-learn yang dipakai menjalankan notebook versi **1.6.1**, sama dengan
  backend. Cek dengan `import sklearn; sklearn.__version__`.
- Backend membaca kunci `model_topik`, `ambang_keyakinan`, `kemiripan_min`,
  `bobot_pertanyaan`, `vec_kata`, `vec_huruf`, `M_indeks`, `M_jawaban`, `indeks`,
  `faq`, `normalisasi`, `stopwords`, `model_penyaring`, dan `ambang_penyaring`. Joblib
  versi lama tidak punya kunci `bobot_pertanyaan`, `M_jawaban`, `model_penyaring`, dan
  `ambang_penyaring`, jadi tidak bisa dipakai lagi dengan `main.py` yang sekarang.
- Kolom di `faq` tetap `pertanyaan`, `topik`, `jawaban`, `sumber`, dengan index
  `faq_id`.
- Untuk mencoba joblib baru tanpa menimpa yang aktif, isi env `TANYAPAJAK_MODEL` dengan
  path file-nya sebelum menjalankan server.
- Setelah file diganti, restart server dan cek cepat lewat http://127.0.0.1:8000/docs.

## Kenapa tidak memakai LLM atau RAG

Pertanyaan ini hampir pasti muncul waktu presentasi, karena sekarang chatbot seperti ChatGPT bisa
menjawab pertanyaan pajak dengan bahasa yang luwes. Ada dua alasan saya tidak
memakainya.

Pertama, risiko jawaban mengarang. LLM bisa menulis jawaban yang terdengar meyakinkan
padahal salah, misalnya tarif atau batas waktu yang keliru, atau aturan yang sudah
tidak berlaku. Di urusan pajak, jawaban salah bisa berujung denda untuk penggunanya.
Sistem saya tidak bisa mengarang, karena yang ditampilkan selalu teks FAQ resmi apa
adanya, lengkap dengan link sumbernya. Kalau FAQ-nya tidak ada, sistem bilang terus
terang dan mengarahkan ke Kring Pajak. Hasil evaluasi di atas juga menunjukkan bahwa
yang paling susah justru tahu kapan harus menolak, dan itu lebih mudah dikontrol
dengan ambang yang bisa diukur.

Kedua, cakupan mata kuliah. Proyek ini memang dibatasi ke machine learning klasik:
pra-pemrosesan teks, TF-IDF, Naive Bayes, Logistic Regression, dan SVM, ditambah aturan
dan kamus buatan sendiri. Tujuannya supaya setiap langkah bisa saya jelaskan dan ukur
sendiri, dari kenapa satu kata dinormalisasi sampai kenapa ambangnya 0,40. Model
pretrained seperti BERT atau IndoBERT, apalagi API AI dari luar, tidak dipakai. Sistem
ini juga jadi ringan, gratis, dan bisa jalan di laptop tanpa internet.

## RAG sebagai pengembangan berikutnya

Sebenarnya bagian pencarian FAQ yang sudah ada adalah setengah dari RAG
(Retrieval-Augmented Generation), yaitu bagian retrieval-nya. Kalau proyek ini
dilanjutkan, RAG bisa ditambahkan dengan tetap menjaga keamanannya:

1. Retrieval tetap memakai FAQ resmi. Bagian ini bisa ditingkatkan dengan sentence
   embedding supaya lebih paham makna, misalnya "cara aktifin lagi npwp" lebih dekat
   ke FAQ cara mengaktifkan kembali NPWP.
2. LLM hanya boleh merangkum dari tiga FAQ teratas yang ditemukan, wajib menyebut
   sumbernya, dan harus menolak kalau ketiga FAQ itu tidak menjawab pertanyaan. Jadi
   LLM dipakai untuk bahasa, bukan sebagai sumber pengetahuan.
3. Pengaman yang sudah ada tetap dipakai: penyaring di luar pajak dan ambang skor tetap
   menentukan boleh tidaknya sistem menjawab, sebelum LLM dipanggil.
4. Evaluasinya tetap memakai set uji bebas, ditambah pengecekan apakah jawaban LLM
   benar-benar sesuai isi FAQ yang dirujuk. Hasilnya tetap diperiksa praktisi pajak.
5. Yang perlu dipikirkan: biaya API, waktu respons, dan data pertanyaan pengguna yang
   ikut terkirim ke layanan luar.

Selain RAG, ada pengembangan yang tidak butuh model baru sama sekali, dan menurut saya
justru paling berdampak: menambah FAQ resmi dari daftar celah di notebook bagian 8.7,
memperbanyak contoh bukan pajak untuk penyaring, dan memperbesar set uji dengan
pertanyaan dari pengguna sungguhan.
