-- W1-07: tabel MVP Super App dengan Row Level Security.
-- Acuan: docs/spesifikasi-teknis.md (Model data, Keamanan data).
--
-- Aturan yang berlaku untuk semua tabel:
-- - id uuid dibuat di HP (default di sini hanya cadangan).
-- - user_id pemilik baris; RLS "hanya milik sendiri".
-- - created_at, updated_at (diisi server saat diubah), deleted_at (soft delete).
-- - Nominal uang = bigint rupiah. Saldo dompet tidak disimpan.

-- ---------------------------------------------------------------------------
-- Fungsi umum
-- ---------------------------------------------------------------------------

-- Mengisi updated_at dengan waktu server setiap baris diubah. Mesin sinkron
-- menarik baris yang updated_at-nya lebih baru dari tarikan terakhir.
create or replace function public.set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

-- ---------------------------------------------------------------------------
-- Tabel
-- ---------------------------------------------------------------------------

create table public.profiles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null unique default auth.uid()
    references auth.users (id) on delete cascade,
  name text,
  avatar_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create table public.semesters (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid()
    references auth.users (id) on delete cascade,
  name text not null,
  starts_on date,
  ends_on date,
  is_active boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  constraint semesters_dates_check check (ends_on is null or starts_on is null or ends_on >= starts_on),
  -- Target foreign key komposit: anak hanya boleh menunjuk induk milik
  -- pengguna yang sama (RLS saja tidak memeriksa kolom relasi).
  constraint semesters_id_user_id_key unique (id, user_id)
);

create table public.courses (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid()
    references auth.users (id) on delete cascade,
  semester_id uuid not null,
  name text not null,
  code text,
  credits smallint check (credits >= 0),
  lecturer text,
  room text,
  color text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  constraint courses_id_user_id_key unique (id, user_id),
  constraint courses_semester_fkey foreign key (semester_id, user_id)
    references public.semesters (id, user_id) on delete cascade
);

create table public.class_sessions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid()
    references auth.users (id) on delete cascade,
  course_id uuid not null,
  -- 1 = Senin … 7 = Minggu (ISO 8601).
  weekday smallint not null check (weekday between 1 and 7),
  starts_at time not null,
  ends_at time not null,
  room text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  constraint class_sessions_times_check check (ends_at > starts_at),
  constraint class_sessions_course_fkey foreign key (course_id, user_id)
    references public.courses (id, user_id) on delete cascade
);

create table public.tasks (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid()
    references auth.users (id) on delete cascade,
  -- Opsional: tugas tanpa mata kuliah.
  course_id uuid,
  title text not null,
  notes text,
  due_at timestamptz,
  priority text check (priority in ('low', 'medium', 'high')),
  status text not null default 'active' check (status in ('active', 'done')),
  completed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  constraint tasks_id_user_id_key unique (id, user_id),
  -- Kalau mata kuliah dihapus permanen, hanya course_id yang dikosongkan.
  constraint tasks_course_fkey foreign key (course_id, user_id)
    references public.courses (id, user_id) on delete set null (course_id)
);

create table public.subtasks (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid()
    references auth.users (id) on delete cascade,
  task_id uuid not null,
  title text not null,
  is_done boolean not null default false,
  position integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  constraint subtasks_task_fkey foreign key (task_id, user_id)
    references public.tasks (id, user_id) on delete cascade
);

create table public.wallets (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid()
    references auth.users (id) on delete cascade,
  name text not null,
  kind text not null check (kind in ('cash', 'bank', 'ewallet')),
  -- Rupiah. Saldo sekarang = opening_balance + semua transaksi dompet ini.
  opening_balance bigint not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  constraint wallets_id_user_id_key unique (id, user_id)
);

create table public.categories (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid()
    references auth.users (id) on delete cascade,
  name text not null,
  kind text not null check (kind in ('income', 'expense')),
  icon text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  constraint categories_id_user_id_key unique (id, user_id)
);

create table public.transactions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid()
    references auth.users (id) on delete cascade,
  wallet_id uuid not null,
  category_id uuid,
  kind text not null check (kind in ('income', 'expense')),
  -- Rupiah, selalu positif; arah uang ditentukan oleh kind.
  amount bigint not null check (amount > 0),
  notes text,
  occurred_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  constraint transactions_wallet_fkey foreign key (wallet_id, user_id)
    references public.wallets (id, user_id) on delete cascade,
  constraint transactions_category_fkey foreign key (category_id, user_id)
    references public.categories (id, user_id) on delete set null (category_id)
);

-- Index untuk kolom relasi (mempercepat join dan penghapusan berantai).
create index courses_semester_id_idx on public.courses (semester_id);
create index class_sessions_course_id_idx on public.class_sessions (course_id);
create index tasks_course_id_idx on public.tasks (course_id);
create index subtasks_task_id_idx on public.subtasks (task_id);
create index transactions_wallet_id_idx on public.transactions (wallet_id);
create index transactions_category_id_idx on public.transactions (category_id);

-- ---------------------------------------------------------------------------
-- Aturan yang sama untuk semua tabel: index sinkron, trigger updated_at,
-- Row Level Security "hanya milik sendiri".
-- ---------------------------------------------------------------------------

do $$
declare
  t text;
begin
  foreach t in array array[
    'profiles', 'semesters', 'courses', 'class_sessions', 'tasks',
    'subtasks', 'wallets', 'categories', 'transactions'
  ] loop
    execute format(
      'create index %I on public.%I (user_id, updated_at)',
      t || '_user_id_updated_at_idx', t
    );
    execute format(
      'create trigger set_updated_at before update on public.%I '
      'for each row execute function public.set_updated_at()',
      t
    );
    execute format('alter table public.%I enable row level security', t);
    execute format(
      'create policy "hanya milik sendiri" on public.%I for all '
      'to authenticated '
      'using ((select auth.uid()) = user_id) '
      'with check ((select auth.uid()) = user_id)',
      t
    );
  end loop;
end;
$$;

-- ---------------------------------------------------------------------------
-- Profil otomatis saat akun pertama kali login (PRD: "Login Google membuat
-- profil di Supabase"). Nama dan foto diambil dari data akun Google.
-- ---------------------------------------------------------------------------

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (user_id, name, avatar_url)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'full_name', new.raw_user_meta_data ->> 'name'),
    coalesce(new.raw_user_meta_data ->> 'avatar_url', new.raw_user_meta_data ->> 'picture')
  );
  return new;
end;
$$;

-- Fungsi ini hanya untuk trigger, tidak boleh dipanggil lewat API.
revoke execute on function public.handle_new_user() from public, anon, authenticated;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();
