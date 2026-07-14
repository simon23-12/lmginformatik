-- LMG Informatik Curriculum: Grundschema
-- Ausführen im Supabase SQL Editor

-- 1. Klassen (z.B. "6a", Schuljahr 2026/27)
create table classes (
  id uuid primary key default gen_random_uuid(),
  name text not null,          -- z.B. "6a"
  grade smallint not null,     -- 6, 9, 10
  school_year text not null,   -- z.B. "2026/27"
  created_at timestamptz default now()
);

-- 2. Schüler, verknüpft mit Supabase Auth User (login via mueller.j@lmg.local)
create table students (
  id uuid primary key references auth.users(id) on delete cascade,
  class_id uuid references classes(id) on delete set null,
  display_name text not null,  -- z.B. "Jonas Müller"
  username text unique not null, -- z.B. "mueller.j"
  created_at timestamptz default now()
);

-- 3. Themen/Kapitel des Curriculums (Struktur des Buchs)
create table topics (
  id uuid primary key default gen_random_uuid(),
  grade smallint not null,
  order_index int not null,
  title text not null,
  description text,
  created_at timestamptz default now()
);

-- 4. Aufgaben pro Thema
create table tasks (
  id uuid primary key default gen_random_uuid(),
  topic_id uuid references topics(id) on delete cascade,
  order_index int not null,
  title text not null,
  content text not null,        -- Aufgabentext
  task_type text not null default 'text', -- 'text', 'multiple_choice', ...
  page_number int,              -- Buchseite, für Sortierung/Planung im Lehrer-Bereich
  section_title text,           -- Überschrift des Buchabschnitts (z.B. "Informatiksysteme")
  difficulty smallint check (difficulty in (1,2,3)), -- 1=leicht, 2=mittel, 3=schwer (Kreis-Symbol im Buch)
  published boolean not null default true, -- Lehrer schaltet Aufgaben passend zur Unterrichtsplanung frei
  created_at timestamptz default now()
);

-- 5. Antworten der Schüler
create table submissions (
  id uuid primary key default gen_random_uuid(),
  student_id uuid references students(id) on delete cascade,
  task_id uuid references tasks(id) on delete cascade,
  answer_text text,
  status text not null default 'submitted', -- 'submitted', 'graded'
  evaluation text check (evaluation in ('green','yellow','red')),
  feedback text,
  submitted_at timestamptz default now(),
  graded_at timestamptz,
  unique (student_id, task_id)
);

-- Row Level Security aktivieren
alter table classes enable row level security;
alter table students enable row level security;
alter table topics enable row level security;
alter table tasks enable row level security;
alter table submissions enable row level security;

-- Schüler dürfen Themen lesen (angemeldet)
create policy "authenticated read topics" on topics
  for select to authenticated using (true);

-- Aufgaben: Schüler sehen nur freigeschaltete (published), Lehrer sehen/ändern alles
create policy "read tasks" on tasks
  for select to authenticated using (
    published = true or exists (select 1 from teachers t where t.id = auth.uid())
  );
create policy "teachers update tasks" on tasks
  for update to authenticated
  using (exists (select 1 from teachers t where t.id = auth.uid()))
  with check (exists (select 1 from teachers t where t.id = auth.uid()));

-- Schüler sehen nur ihren eigenen Datensatz
create policy "own student row" on students
  for select using (auth.uid() = id);

-- Schüler sehen/erstellen/ändern nur ihre eigenen Antworten
create policy "own submissions select" on submissions
  for select using (auth.uid() = student_id);
create policy "own submissions insert" on submissions
  for insert with check (auth.uid() = student_id);
create policy "own submissions update" on submissions
  for update using (auth.uid() = student_id);

-- Hinweis: Als Lehrer greifst du über den service_role Key zu (umgeht RLS
-- komplett) für dein eigenes Grading-Tool. Diesen Key niemals im Frontend
-- verwenden, nur in einem privaten Backend/Skript.

-- Keepalive-Heartbeat: dient nur dem externen Cronjob (cron-job.org), der
-- alle 3 Tage die DB anpingt, damit sie im Free-Tier nicht wegen
-- Inaktivität pausiert wird. Einzige Tabelle mit anon-Leserechten, bewusst
-- ohne echte Daten.
create table public._keepalive (
  id smallint primary key default 1,
  pinged_at timestamptz not null default now(),
  constraint _keepalive_singleton check (id = 1)
);
insert into public._keepalive (id) values (1) on conflict (id) do nothing;
alter table public._keepalive enable row level security;
create policy "keepalive_public_read" on public._keepalive
  for select to anon
  using (true);
grant select on public._keepalive to anon;
