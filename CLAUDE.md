# LMG Informatik — Projektnotizen für Claude

Schul-Curriculum-Plattform (Klasse 6, 9, 10) mit Schüler-/Lehrer-Accounts. Statische Seite (kein Build), Backend ist Supabase.

## Stack
- Reines HTML/JS mit ES-Modulen, kein Bundler. Deploy = `git push` (GitHub Pages, später zusätzlich Vercel).
- Supabase: Auth + Postgres + RLS. MCP-Server verbunden (Tools `mcp__supabase__*`) für Migrationen/SQL/Logs — `.mcp.json` muss auf jedem Rechner separat angelegt werden (gitignored, siehe SwitchPC.md).
- Lokal testen: `.claude/launch.json` → `python3 -m http.server 5500` (nicht `python` — auf macOS oft nicht vorhanden). ES-Module brauchen `http://`, nicht `file://`.

## Wichtige Regeln
- **Neue Tabellen brauchen immer explizite `GRANT ... TO authenticated`** zusätzlich zur RLS-Policy (Projekt hat "auto-expose new tables" deaktiviert) — sonst 403 trotz korrekter Policy.
- **Nie `/pfad` hartcodieren** für Redirects/Links. Immer `SITE_ROOT` aus [assets/supabase-client.js](assets/supabase-client.js) verwenden (relativ zu `import.meta.url` berechnet) — die Seite läuft sowohl unter GitHub-Pages-Unterpfad (`/lmginformatik/`) als auch später auf Vercel-Root.
- Login läuft über Benutzername, nicht E-Mail: intern wird `{username}@lmg.local` an Supabase Auth durchgereicht.
- Bewertung ist Ampel (`green`/`yellow`/`red` in `submissions.evaluation`), **keine Noten**. Feedback ist beim Bewerten Pflicht.
- **Aufgaben werden pro Klasse einzeln freigeschaltet** (Tabelle `class_task_status`, nicht das alte `tasks.published`), da Klassen unterschiedlich schnell vorankommen. Schüler sehen eine Aufgabe nur, wenn für ihre `class_id` ein Eintrag mit `published=true` existiert (RLS-Policy auf `tasks` prüft das per Subquery).
- **Buchseiten-Fotos** (`Kapitel */`, `Klasse 6/9/10 Buch/`) sind urheberrechtlich geschützte Scans — dauerhaft in `.gitignore`, nie committen. Digitalisierte **Aufgabentexte** (nur die Aufgaben, nicht ganze Seiten) dürfen dagegen ins Repo/in Migrations-SQL — das hat der Nutzer (hat die digitale Schulbuch-Lizenz) explizit freigegeben, da die Daten selbst hinter Login/RLS liegen.
- `.mcp.json` und `Testaccounts.rtf` enthalten Secrets/Zugangsdaten — bleiben gitignored.
- Bei neuen, voneinander unabhängigen Supabase-Queries **`Promise.all` statt sequenzieller `await`s** verwenden (Ladezeiten) — nur wenn eine Query wirklich von einer anderen abhängt (z. B. IDs aus Query A für den Filter von Query B), sequenziell bleiben.
- Repo ist **öffentlich** — bei jeder Änderung kurz prüfen, dass keine Secrets reinrutschen.
- Das Repo-`.git` liegt direkt in `LMGINFORMATIK/` (nicht im Home-Verzeichnis!) — das war früher einmal versehentlich anders, falls das auf einem neuen Rechner wieder auftaucht: `git rev-parse --show-toplevel` prüfen, bevor committet wird.
- **Supabase-Keepalive**: läuft über einen externen Cronjob bei cron-job.org (alle 3 Tage, Titel "lmginformatik" im dortigen Account), nicht über GitHub Actions — GitHub deaktiviert scheduled Workflows nach 60 Tagen Repo-Inaktivität, das wäre ein Single Point of Failure. Der Cronjob ruft `GET /rest/v1/_keepalive?select=id&limit=1` mit Header `apikey: <publishable key>` auf. Die Tabelle `public._keepalive` ist eine eigens dafür angelegte leere Ein-Zeilen-Tabelle mit `GRANT SELECT TO anon` — bewusst die einzige Tabelle mit anon-Zugriff, da alle anderen Tabellen laut Regel oben nur `authenticated` gewähren.

## Struktur
- `index.html` — Login/Landingpage
- `dashboard/` — Schüler-Dashboard (Kapitelübersicht + Aufgaben, mit Schwierigkeitsanzeige)
- `admin/` — Lehrer-Dashboard: flache Klassen-/Kursübersicht (6a–6d, Kurs 9, Kurs 10) → pro Klasse eigener Aufgabenplaner (Kapitel-Dropdown → Aufgaben nach Seite gruppiert, Live-Schalter pro Klasse) + Fortschritt/Bewertung (nur freigeschaltete Aufgaben, nach Kapitel gruppiert, Ampel-Punkte pro Schüler)
- `assets/supabase-client.js` — gemeinsamer Client, Login-/Rollen-/Redirect-Logik
- `supabase_schema.sql` — Referenz-Schema (nicht automatisch ausgeführt, dient als Doku)
- `migration_task_planning.sql` — enthält digitalisierte Aufgabentexte, gitignored (siehe Regel oben), manuell im SQL-Editor auszuführen

## Skills
- `grade-submissions` (in `.claude/skills/` hier im Repo **und** account-weit unter `~/.claude/skills/`): korrigiert Einreichungen batch-weise direkt gegen Supabase. Bei Anpassungen erst hier lokal ändern, dann bei Bewährung nach `~/.claude/skills/grade-submissions/` kopieren.

Für den vollständigen aktuellen Stand (Seed-Daten, Testzugänge, offene To-dos) siehe [SwitchPC.md](SwitchPC.md).
