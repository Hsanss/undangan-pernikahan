-- Jalankan seluruh file di Supabase SQL Editor pada project undangan (Free).
-- Tidak mengubah tabel aplikasi lain. Data tamu tidak dapat dibaca anon/authenticated.
begin;
create table if not exists public.wedding_guests (
 id uuid primary key default gen_random_uuid(),
 token uuid not null unique default gen_random_uuid(),
 name text not null check (char_length(btrim(name)) between 1 and 100),
 max_guests integer not null default 2 check (max_guests between 1 and 10),
 active boolean not null default true,
 created_at timestamptz not null default now()
);
create table if not exists public.wedding_rsvps (
 guest_id uuid primary key references public.wedding_guests(id) on delete cascade,
 attendance text not null check (attendance in ('Hadir','Tidak dapat hadir','Belum dapat memastikan')),
 guests integer not null check (guests between 0 and 10),
 message text not null default '' check (char_length(message)<=1000),
 publish_consent boolean not null default false,
 approved boolean not null default false,
 updated_at timestamptz not null default now()
);
alter table public.wedding_guests enable row level security;
alter table public.wedding_rsvps enable row level security;
revoke all on public.wedding_guests, public.wedding_rsvps from anon, authenticated;
-- Tidak ada policy baca/tulis publik pada tabel; akses terbatas melalui RPC berikut.
create or replace function public.wedding_invitation(p_token uuid)
returns table(guest_name text, guest_limit integer, attendance text, guests integer)
language sql security definer set search_path = '' as $$
 select g.name,g.max_guests,r.attendance,r.guests
 from public.wedding_guests g left join public.wedding_rsvps r on r.guest_id=g.id
 where g.token=p_token and g.active;
$$;
create or replace function public.wedding_submit(p_token uuid,p_attendance text,p_guests integer,p_message text,p_publish boolean)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare g public.wedding_guests%rowtype; last_update timestamptz;
begin
 -- Lock satu tamu agar kirim bersamaan tidak melewati cooldown.
 select * into g from public.wedding_guests where token=p_token and active for update;
 if not found then raise exception 'Tautan tamu tidak valid'; end if;
 if p_attendance is null or p_attendance not in ('Hadir','Tidak dapat hadir','Belum dapat memastikan') then raise exception 'Kehadiran tidak valid'; end if;
 if p_guests is null or p_guests < 0 or p_guests > g.max_guests then raise exception 'Jumlah tamu melebihi undangan'; end if;
 if p_attendance='Hadir' and p_guests<1 then raise exception 'Jumlah tamu minimal satu'; end if;
 if p_message is null or char_length(p_message)>1000 or p_publish is null then raise exception 'Ucapan tidak valid'; end if;
 select updated_at into last_update from public.wedding_rsvps where guest_id=g.id;
 if last_update > now()-interval '60 seconds' then raise exception 'Tunggu 60 detik sebelum memperbarui konfirmasi'; end if;
 insert into public.wedding_rsvps(guest_id,attendance,guests,message,publish_consent,approved,updated_at)
 values(g.id,p_attendance,case when p_attendance='Tidak dapat hadir' then 0 else p_guests end,btrim(p_message),p_publish,false,now())
 on conflict(guest_id) do update set attendance=excluded.attendance,guests=excluded.guests,message=excluded.message,publish_consent=excluded.publish_consent,approved=false,updated_at=now();
 return jsonb_build_object('saved',true);
end; $$;
create or replace function public.wedding_wishes()
returns table(guest_name text,message text,created_at timestamptz)
language sql security definer set search_path = '' as $$
 select g.name,r.message,r.updated_at from public.wedding_rsvps r
 join public.wedding_guests g on g.id=r.guest_id
 where r.approved and r.publish_consent and g.active and btrim(r.message)<>''
 order by r.updated_at desc limit 50;
$$;
revoke all on function public.wedding_invitation(uuid) from public,anon,authenticated;
revoke all on function public.wedding_submit(uuid,text,integer,text,boolean) from public,anon,authenticated;
revoke all on function public.wedding_wishes() from public,anon,authenticated;
grant execute on function public.wedding_invitation(uuid) to anon;
grant execute on function public.wedding_submit(uuid,text,integer,text,boolean) to anon;
grant execute on function public.wedding_wishes() to anon;
-- Bucket khusus media undangan. URL publik berarti file dapat dilihat siapa pun.
-- Upload/hapus dilakukan pemilik lewat Dashboard; tidak ada policy upload publik.
insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
values('wedding-media','wedding-media',true,20971520,array['image/jpeg','image/png','image/webp','video/mp4','audio/mpeg'])
on conflict(id) do nothing;
commit;
-- Tambahkan tamu lewat Table Editor wedding_guests; token dibuat otomatis.
-- Contoh opsional (jangan jalankan sebelum mengganti nama):
-- insert into public.wedding_guests(name,max_guests) values ('Nama Tamu',2) returning name,token;
-- Moderasi ucapan: ubah approved=true lewat Table Editor wedding_rsvps setelah ditinjau.
