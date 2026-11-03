# Sepucuk Janji — undangan pernikahan

Template scrapbook marun, satu index.html tanpa build/dependensi. Data awal adalah contoh; jangan dibagikan sebagai undangan final sebelum diganti.

## Susunan gratis

- GitHub Pages: hosting website dari branch `main`, folder `/ (root)`.
- Supabase Free: PostgreSQL untuk tamu/RSVP/ucapan dan Storage untuk media.
- Google Drive opsional untuk foto/video asli; tidak dibutuhkan website.
- Tidak memerlukan domain berbayar atau paket Pro. Pantau kuota di Dashboard; paket gratis tetap memiliki batas penggunaan dan ketentuan jeda proyek.

## Aktivasi Supabase

1. Masuk Supabase, gunakan project khusus undangan pada paket Free (bukan project aplikasi lain).
2. Di SQL Editor, jalankan `schema.sql` sekali. Simpan tabel tamu dan RSVP hanya di Supabase, bukan GitHub.
3. Isi `CONFIG.supabaseUrl` dengan Project URL (tanpa slash akhir) dan `CONFIG.supabaseKey` dengan publishable key atau legacy anon key dari pengaturan API project.
4. **Jangan memasukkan secret key/service_role, password, atau token tamu ke kode/repo.** Key publik hanya aman bersama izin/RLS yang disiapkan schema.sql.
5. Buka Table Editor → `wedding_guests`, tambahkan `name`, `max_guests` (1–10), `active=true`. Kolom `id` dan `token` otomatis dibuat.
6. Bagikan tautan pribadi `https://ALAMAT-WEBSITE/?t=TOKEN-TAMU`. Token adalah akses RSVP tamu tersebut; bagikan hanya kepada penerimanya. Parameter `?to=` hanya untuk pratinjau nama, bukan izin database.
7. Uji tamu khusus pengujian: kirim RSVP, lihat baris pada `wedding_rsvps`, lalu coba perbarui setelah 60 detik.
8. Ucapan baru disimpan dengan `approved=false`. Tinjau di Table Editor dan set `approved=true` jika layak. Ucapan hanya dipublikasikan jika tamu juga memberi `publish_consent=true`.
9. Mengubah RSVP akan mengembalikan ucapan ke antrean moderasi. Jika tamu tidak hadir, jumlah disimpan sebagai 0.

## Media dan isi

- Edit `CONFIG`: nama, nama lengkap, orang tua, tanggal/jam zona WIB, tempat, alamat, jadwal acara, URL Maps, foto/video/musik.
- Edit cerita pasangan dan dress code pada HTML.
- Upload media melalui Storage Dashboard → `wedding-media` → ambil public URL dan isi di CONFIG.
- `photos`: indeks 0 cover, 1 mempelai pertama, 2 mempelai kedua, 3–6 galeri (total 7 foto). Tanpa foto, ilustrasi pengganti tetap tampil.
- `videoUrl`: satu MP4 opsional; `musicUrl`: satu MP3 opsional. Gunakan media milik sendiri/berizin.
- Bucket template membatasi per file 20 MiB, tanpa akses upload publik. Konten bucket bersifat publik; jangan upload dokumen tamu/data pribadi.
- Foto WebP/JPEG terkompres, video pendek, dan musik ringan membantu menghemat kuota. Player video tidak mengunduh penuh sebelum diputar.
- Setelah data final selesai, set `demo:false` untuk menyembunyikan label contoh.
- RSVP WhatsApp hanya fallback bila Supabase belum dikonfigurasi dan `CONFIG.whatsapp` diisi angka internasional (628...). Tidak ada fallback otomatis saat server error agar tamu tahu apakah data tersimpan.

## GitHub Pages

Settings → Pages → Deploy from a branch → main → /(root) → Save. Tunggu deployment sukses. Tidak perlu GitHub Actions khusus. `.nojekyll` membuat file statis disajikan langsung.

Cloudflare Pages alternatif: hubungkan repo, preset None, tanpa build; pilih folder berisi index.html. Tidak perlu mengaktifkan R2 berbayar.

## Pemeriksaan sebelum dibagikan

- Ganti semua data contoh dan foto; pastikan tanggal, Maps, kalender, dan zona waktu benar.
- Uji HP/desktop: pembuka, navigasi, galeri, RSVP, musik dan video (jika diisi).
- Uji token salah/tanpa token: halaman dapat dilihat, tetapi RSVP tidak bisa dikirim.
- Tabel tamu/RSVP harus tidak bisa dibaca/ditulis langsung melalui anon key.
- Uji ucapan belum disetujui tidak tampil; ucapan disetujui tanpa izin publikasi juga tidak tampil.
- Mengelola data menggunakan login Supabase Dashboard; tidak ada halaman admin publik atau akun login tambahan dalam template ini.

## Status paket

Integrasi dan migrasi disiapkan; database baru aktif setelah schema.sql dijalankan dan konfigurasi URL/key diisi. Tanpa konfigurasi, halaman menyatakan mode pratinjau dan tidak mengaku menyimpan RSVP. SQL harus diuji di project Supabase sebelum dipakai untuk acara sungguhan.
