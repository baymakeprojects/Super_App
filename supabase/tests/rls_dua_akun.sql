-- Uji RLS dua akun (W1-07, "Selesai bila": A tidak bisa membaca data B).
--
-- Cara pakai: jalankan seluruh isi file ini di SQL Editor proyek **dev**
-- (atau lewat Supabase MCP execute_sql). Semua perubahan dibatalkan di
-- akhir (rollback), jadi tidak ada akun atau data uji yang tersisa.
-- Kalau ada cek yang gagal, skrip berhenti dengan pesan "GAGAL: …".

begin;

-- Dua akun uji, hanya ada di dalam transaksi ini.
insert into auth.users (id, email, aud, role, raw_user_meta_data)
values
  ('00000000-0000-4000-a000-00000000000a', 'akun-a@uji.local', 'authenticated', 'authenticated',
   '{"full_name": "Akun A"}'),
  ('00000000-0000-4000-a000-00000000000b', 'akun-b@uji.local', 'authenticated', 'authenticated',
   '{"full_name": "Akun B"}');

-- Mulai dari sini bertindak sebagai pengguna app biasa (bukan admin).
set local role authenticated;

do $$
declare
  a constant uuid := '00000000-0000-4000-a000-00000000000a';
  b constant uuid := '00000000-0000-4000-a000-00000000000b';
  semester_b uuid := gen_random_uuid();
  course_b uuid := gen_random_uuid();
  task_b uuid := gen_random_uuid();
  wallet_b uuid := gen_random_uuid();
  category_b uuid := gen_random_uuid();
  n integer;
begin
  -- ===== Sebagai B: isi satu baris di setiap tabel =====
  perform set_config('request.jwt.claims', json_build_object('sub', b, 'role', 'authenticated')::text, true);

  insert into public.semesters (id, name, is_active) values (semester_b, 'Semester 7', true);
  insert into public.courses (id, semester_id, name) values (course_b, semester_b, 'Pemrograman Mobile');
  insert into public.class_sessions (course_id, weekday, starts_at, ends_at) values (course_b, 5, '08:00', '09:40');
  insert into public.tasks (id, course_id, title) values (task_b, course_b, 'Laporan praktikum');
  insert into public.subtasks (task_id, title) values (task_b, 'Bab 1');
  insert into public.wallets (id, name, kind, opening_balance) values (wallet_b, 'Tunai', 'cash', 100000);
  insert into public.categories (id, name, kind) values (category_b, 'Makan', 'expense');
  insert into public.transactions (wallet_id, category_id, kind, amount) values (wallet_b, category_b, 'expense', 15000);

  select count(*) into n from public.profiles;
  if n <> 1 then raise exception 'GAGAL: B harus melihat tepat 1 profil miliknya, terlihat %', n; end if;
  select count(*) into n from public.transactions;
  if n <> 1 then raise exception 'GAGAL: B harus melihat transaksinya sendiri, terlihat %', n; end if;

  -- ===== Sebagai A: tidak boleh melihat atau mengubah data B =====
  perform set_config('request.jwt.claims', json_build_object('sub', a, 'role', 'authenticated')::text, true);

  select count(*) into n from public.profiles;
  if n <> 1 then raise exception 'GAGAL: A harus melihat hanya profilnya sendiri, terlihat %', n; end if;

  select
    (select count(*) from public.semesters) + (select count(*) from public.courses)
    + (select count(*) from public.class_sessions) + (select count(*) from public.tasks)
    + (select count(*) from public.subtasks) + (select count(*) from public.wallets)
    + (select count(*) from public.categories) + (select count(*) from public.transactions)
  into n;
  if n <> 0 then raise exception 'GAGAL: A bisa membaca % baris milik B', n; end if;

  update public.wallets set name = 'Dibajak' where id = wallet_b;
  get diagnostics n = row_count;
  if n <> 0 then raise exception 'GAGAL: A bisa mengubah dompet B'; end if;

  update public.tasks set deleted_at = now() where id = task_b;
  get diagnostics n = row_count;
  if n <> 0 then raise exception 'GAGAL: A bisa menghapus (soft delete) tugas B'; end if;

  delete from public.transactions;
  get diagnostics n = row_count;
  if n <> 0 then raise exception 'GAGAL: A bisa menghapus transaksi B'; end if;

  -- A tidak boleh menulis baris atas nama B.
  begin
    insert into public.wallets (user_id, name, kind) values (b, 'Palsu', 'cash');
    raise exception 'GAGAL: A bisa membuat dompet atas nama B';
  exception
    when insufficient_privilege then null; -- ditolak RLS: benar
  end;

  -- ===== Kembali sebagai B: datanya masih utuh =====
  perform set_config('request.jwt.claims', json_build_object('sub', b, 'role', 'authenticated')::text, true);

  select count(*) into n from public.wallets where name = 'Tunai';
  if n <> 1 then raise exception 'GAGAL: dompet B berubah atau hilang'; end if;
  select count(*) into n from public.tasks where deleted_at is null;
  if n <> 1 then raise exception 'GAGAL: tugas B ikut terhapus'; end if;
  select count(*) into n from public.transactions;
  if n <> 1 then raise exception 'GAGAL: transaksi B ikut terhapus'; end if;

end;
$$;

rollback;

-- Baris ini hanya tercapai kalau semua cek di atas lulus.
select 'LULUS: A tidak bisa membaca, mengubah, menghapus, atau menulis data B.' as hasil;
