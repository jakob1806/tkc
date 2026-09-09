# Supabase Team-Sync – Setup

Die App funktioniert komplett offline mit SwiftData. Team-Sync ist optional und pusht
Konzerte + Content-Einträge zusätzlich in ein Supabase-Projekt, damit mehrere Personen
auf denselben Stand zugreifen können.

## 1. Supabase-Projekt anlegen

Auf [supabase.com](https://supabase.com) ein neues Projekt erstellen. Danach unter
**Project Settings → API** die **Project URL** und den **anon public key** kopieren –
beide kommen in der App unter **Mehr → Einstellungen → Team-Sync** rein.

## 2. Tabellen anlegen

Im Supabase SQL Editor ausführen:

```sql
create table if not exists concerts (
  external_id text primary key,
  title text not null,
  date timestamptz not null,
  venue text not null,
  city text not null,
  address text,
  ticket_url text,
  source_url text,
  tickets_sold int,
  venue_capacity int,
  updated_at timestamptz not null default now()
);

create table if not exists content_items (
  id text primary key,
  title text not null,
  date timestamptz not null,
  publish_time timestamptz,
  platform text not null,
  content_type text not null,
  status text not null,
  concert_external_id text references concerts(external_id) on delete set null,
  assignee text,
  caption text,
  updated_at timestamptz not null default now()
);

-- Zeilensicherheit aktivieren, aber für den Anfang allen eingeloggten Team-Mitgliedern
-- volle Lese-/Schreibrechte geben. Für produktiven Einsatz später auf echte
-- Supabase-Auth-Accounts + granularere Policies umstellen.
alter table concerts enable row level security;
alter table content_items enable row level security;

create policy "Team hat vollen Zugriff auf concerts"
  on concerts for all
  using (true)
  with check (true);

create policy "Team hat vollen Zugriff auf content_items"
  on content_items for all
  using (true)
  with check (true);
```

## 3. In der App aktivieren

**Mehr → Einstellungen → Team-Sync (Supabase)**:
1. "Team-Sync aktivieren" umschalten
2. Project URL und Anon Key einfügen
3. "Jetzt synchronisieren" tippen

## Aktueller Stand vs. Ausbaustufe

Was jetzt funktioniert: ein manueller **Push** (lokale Konzerte/Content-Einträge →
Supabase, per Upsert über `external_id`/`id`, ohne Datenverlust bei erneutem Sync).

Was für echten Team-Betrieb noch fehlt und die nächsten sinnvollen Schritte wären:
- **Pull**: Änderungen von Supabase zurück in den lokalen SwiftData-Store holen
- **Supabase Auth** statt der aktuell rein clientseitigen Rolle (`AppRole` in
  `AppSettings`), damit Rollen serverseitig durchgesetzt werden
- **Realtime-Subscriptions**, damit Änderungen anderer Team-Mitglieder live ankommen
  statt nur bei manuellem Sync
- **Konflikterkennung** (aktuell gewinnt bei gleichzeitiger Bearbeitung schlicht der
  letzte Push, `updated_at` wird mitgeschickt, aber nicht ausgewertet)
- Assets (Fotos/Videos) landen aktuell nur als Link in SwiftData - für echten
  Team-Zugriff auf Dateien wäre **Supabase Storage** der nächste Schritt
