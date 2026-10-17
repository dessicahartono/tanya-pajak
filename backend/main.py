import os
import re
from functools import lru_cache

import joblib
import numpy as np
import pandas as pd
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from scipy.sparse import hstack
from sklearn.metrics.pairwise import cosine_similarity
from Sastrawi.Stemmer.StemmerFactory import StemmerFactory

# TANYAPAJAK_MODEL dipakai saat evaluasi untuk mencoba joblib lain tanpa menimpa yang aktif.
MODEL_PATH = os.environ.get('TANYAPAJAK_MODEL',
                            os.path.join(os.path.dirname(__file__), 'tanyapajak_lengkap.joblib'))
paket = joblib.load(MODEL_PATH)

model = paket['model_topik']
AMBANG = paket['ambang_keyakinan']
KEMIRIPAN_MIN = paket['kemiripan_min']
BOBOT = paket['bobot_pertanyaan']
PENYARING = paket['model_penyaring']
AMBANG_PENYARING = paket['ambang_penyaring']
DI_LUAR_PAJAK = 'Di luar pajak'
KRING_PAJAK = 'hubungi Kring Pajak 1500200 atau kunjungi www.pajak.go.id'
NORMALISASI = paket['normalisasi']
STOPWORDS = paket['stopwords']

stemmer = StemmerFactory().create_stemmer()

# Semua kata yang dikenal model klasifikasi. CalibratedClassifierCV (SVM) menyimpan 3 salinan
# pipeline (cv=3), jadi kosakatanya digabung.
if hasattr(model, 'calibrated_classifiers_'):
    KOSAKATA = set().union(*(c.estimator.named_steps['tfidf'].vocabulary_
                             for c in model.calibrated_classifiers_))
else:
    KOSAKATA = set(model.named_steps['tfidf'].vocabulary_)


@lru_cache(maxsize=None)
def stem_kata(kata):
    return stemmer.stem(kata)


def bersihkan(teks):
    t = str(teks).lower()
    t = re.sub(r'\be[-\s]?(filing|filling|faktur|spt|billing|bupot|form|objection)\b', r'e\1', t)
    t = re.sub(r'([a-z])(\d)', r'\1 \2', t)
    t = re.sub(r'(\d)([a-z])', r'\1 \2', t)
    t = re.sub(r'[^a-z0-9\s]', ' ', t)
    # Hasil normalisasi bisa 2 kata (deadline -> batas waktu), jadi dipecah lagi.
    kata = ' '.join(NORMALISASI.get(k, k) for k in t.split()).split()
    kata = [k for k in kata if k not in STOPWORDS]
    kata = [stem_kata(k) for k in kata]
    return ' '.join(kata)


def cari_faq(teks, topik=None, k=3):
    # topik=None berarti cari di seluruh korpus.
    # Skor FAQ = BOBOT x kemiripan pertanyaan terbaik + (1 - BOBOT) x kemiripan jawaban.
    q = hstack([paket['vec_kata'].transform([teks]),
                paket['vec_huruf'].transform([teks])]).tocsr()
    q = q / max(float(np.sqrt(q.multiply(q).sum())), 1e-12)
    indeks, M = paket['indeks'], paket['M_indeks']
    if topik is not None:
        mask = (indeks['topik'] == topik).to_numpy()
        indeks, M = indeks[mask], M[mask]
    skor_p = indeks.assign(skor=cosine_similarity(q, M).ravel()).groupby('faq_id')['skor'].max()
    skor_j = pd.Series(cosine_similarity(q, paket['M_jawaban']).ravel(), index=paket['faq'].index)
    skor = BOBOT * skor_p + (1 - BOBOT) * skor_j[skor_p.index]
    return skor.sort_values(ascending=False).head(k)


def susun_jawaban(teks, topik, keyakinan, saran_topik, filter_topik=True, ulang_semua_topik=True):
    respons = {
        'topik': topik,
        'confidence': keyakinan,
        'saran_topik': saran_topik,
        'label_sumber': 'Sumber: FAQ pajak.go.id',
        'sumber': None,
        'pertanyaan_terkait': [],
        'faq_ditemukan': True,
    }
    hasil = cari_faq(teks, topik if filter_topik else None)
    if filter_topik and ulang_semua_topik and (hasil.empty or hasil.iloc[0] < KEMIRIPAN_MIN):
        # Tidak ada yang cukup mirip di topik ini, coba di seluruh korpus.
        hasil = cari_faq(teks)
    if hasil.empty or hasil.iloc[0] < KEMIRIPAN_MIN:
        # Flutter menampilkan tombol Kring Pajak kalau faq_ditemukan = False.
        respons['jawaban'] = ('Maaf, pertanyaan ini belum ada di FAQ pajak.go.id yang saya punya, '
                              f'jadi saya tidak mau menebak jawabannya. Untuk jawaban yang pasti, {KRING_PAJAK}.')
        respons['label_sumber'] = None
        respons['faq_ditemukan'] = False
        return respons

    faq = paket['faq'].loc[hasil.index[0]]
    respons['jawaban'] = faq['jawaban']
    respons['sumber'] = faq['sumber'] if isinstance(faq['sumber'], str) else None
    if respons['sumber'] and re.search(r'halaman sumber\.?$', faq['jawaban']):
        # Jawaban placeholder: isi lengkapnya hanya ada di halaman sumber.
        respons['jawaban'] += f"\n\nSelengkapnya: {respons['sumber']}"
    respons['pertanyaan_terkait'] = [paket['faq'].loc[f, 'pertanyaan'] for f in hasil.index[1:]]
    return respons


app = FastAPI(title='TanyaPajak API')
# Versi web Flutter jalan di port lain, jadi browser butuh izin CORS untuk memanggil API ini.
# Prototipe tanpa login atau cookie, jadi semua asal diizinkan.
app.add_middleware(CORSMiddleware, allow_origins=['*'], allow_methods=['GET', 'POST'], allow_headers=['*'])


class Pertanyaan(BaseModel):
    pertanyaan: str


@app.get('/')
def cek():
    return {'status': 'ok', 'topik': list(model.classes_)}


@app.post('/predict')
def predict(body: Pertanyaan):
    teks = bersihkan(body.pertanyaan)
    peluang_luar = float(PENYARING.predict_proba([teks])[0, 1])
    if peluang_luar >= AMBANG_PENYARING:
        # Penyaring menilai ini bukan pertanyaan pajak, jadi ditolak dengan sopan.
        # saran_topik kosong supaya Flutter tidak menawarkan tombol topik.
        return {'topik': DI_LUAR_PAJAK, 'confidence': round(peluang_luar, 2), 'saran_topik': [],
                'label_sumber': None, 'sumber': None, 'pertanyaan_terkait': [], 'faq_ditemukan': False,
                'jawaban': ('Maaf, pertanyaan ini sepertinya di luar topik pajak, jadi saya belum bisa '
                            f'menjawabnya. Untuk urusan pajak, silakan tanya di sini atau {KRING_PAJAK}.')}
    if not any(k in KOSAKATA for k in teks.split()):
        # Tidak ada kata yang dikenal model, jadi tebakan topiknya tidak berarti apa-apa
        # (selalu sama untuk semua input). Saran topik dikosongkan supaya Flutter
        # menampilkan pesan "belum paham" tanpa tombol topik.
        return {'topik': 'Umum', 'confidence': 0.0, 'jawaban': '', 'saran_topik': []}

    proba = model.predict_proba([teks])[0]
    urut = np.argsort(proba)[::-1]
    kelas = model.classes_

    topik = str(kelas[urut[0]])
    yakin = round(float(proba[urut[0]]), 2)
    saran = [str(kelas[i]) for i in urut[:3]]

    # Kalau kurang yakin, FAQ dicari di seluruh korpus. Flutter tetap menampilkan layar
    # "kurang yakin" + tombol saran_topik karena itu ditentukan dari confidence.
    return susun_jawaban(teks, topik, yakin, saran, filter_topik=yakin >= AMBANG)


@app.get('/jawaban/{topik}')
def jawaban(topik: str, pertanyaan: str = ''):
    # Dipanggil saat pengguna memilih topik di layar "kurang yakin".
    # FAQ dicari pakai pertanyaan asli pengguna, hanya di topik yang dipilih, dengan ambang
    # yang sama seperti /predict. Kalau tidak ada yang cukup mirip, ditolak dengan jujur.
    if topik not in model.classes_:
        raise HTTPException(404, f'Topik tidak dikenal: {topik}')
    return susun_jawaban(bersihkan(pertanyaan), topik, 1.0, [], ulang_semua_topik=False)
