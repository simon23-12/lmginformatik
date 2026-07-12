# SwitchPC — Stand für Weiterarbeit am Laptop

Letzter Stand: 2026-07-12, Desktop-PC. Repo ist gepusht, alles unten Beschriebene ist live in Supabase und auf GitHub.

## Projekt in einem Satz
Digitalisierung des Informatik-Curriculums (Klasse 6, 9, 10) am LMG Düsseldorf: Schüler bearbeiten Aufgaben online, Lehrer (Herr Fuhs) sieht Fortschritt und bewertet Einreichungen mit Ampel (grün/gelb/rot) statt Noten.

## Repo & Deployment
- GitHub: https://github.com/simon23-12/lmginformatik (Branch `main`, **öffentlich**)
- Statische Seite, kein Build-Step, kein Framework — reines HTML/JS mit ES-Modulen
- Live via **GitHub Pages**: https://simon23-12.github.io/lmginformatik/ (auto-deploy bei jedem Push auf `main`, dauert ~1-2 Min)
- **Vercel ist bewusst noch nicht eingerichtet** ("kommt später") — wenn es soweit ist: vercel.com/new, Repo importieren, Framework "Other"
- Lokal testen: `.claude/launch.json` startet `python -m http.server 5500` (Browser-Tool nutzt das automatisch). ES-Modules brauchen `http://`, nicht `file://`.

## Supabase-Projekt
- Name: LMG INFORMATIK, Projekt-Ref `mdwsojyxklocyhiavkex`, Region **Frankfurt (eu-central-1)** — bewusst EU wegen Schülerdaten/DSGVO
- URL: `https://mdwsojyxklocyhiavkex.supabase.co`
- Anon/Publishable Key liegt (bewusst, sicher) direkt im Code: [assets/supabase-client.js](assets/supabase-client.js) — Sicherheit kommt über RLS, nicht über Geheimhaltung des Keys
- MCP-Verbindung für Claude Code liegt in `.mcp.json` (im Repo-Root, **gitignored**, enthält Personal Access Token `sbp_...`). **Muss auf dem Laptop manuell neu angelegt werden** (nicht in Git) — siehe Abschnitt unten "Was NICHT im Git liegt".

## Datenbank-Schema (aktueller Stand)
- `classes`: id, name (z.B. "6a" oder "Kurs 9"), grade (6/9/10), school_year, **type** ('klasse'|'kurs'), **capacity** (32 für Klassen, 30 für Kurse), created_at
- `students`: id (= auth.users.id), class_id, display_name, username, created_at — Login läuft über internen Fake-E-Mail-Trick: `{username}@lmg.local`
- `teachers`: id (= auth.users.id), display_name, created_at — Rolle mit Vollzugriff (lesen) auf alle Klassen/Schüler/Einreichungen
- `topics`: id, grade, order_index, title, description, created_at — Kapitel des Curriculums
- `tasks`: id, topic_id, order_index, title, content, task_type ('text'), created_at
- `submissions`: id, student_id, task_id, answer_text, status ('submitted'|'graded'), **evaluation** ('green'|'yellow'|'red'), feedback, submitted_at, graded_at — **kein Notenfeld mehr**, wurde durch Ampel ersetzt

### ⚠️ Wichtige Falle bei neuen Tabellen
Im Supabase-Projekt ist "Automatically expose new tables" **deaktiviert**. Das heißt: RLS-Policies allein reichen nicht — jede neue Tabelle braucht zusätzlich explizite `GRANT SELECT/INSERT/UPDATE ... TO authenticated;`, sonst gibt's einen 403 "permission denied", obwohl die RLS-Policy korrekt wäre. Ist uns schon einmal passiert (hat den kompletten Login blockiert). Beim Anlegen neuer Tabellen IMMER dran denken.

## Seed-/Testdaten (aktuell in der DB)
- Klasse **6a** (grade 6, Schuljahr 2026/27, Kapazität 32)
- Lehrer-Account: Benutzername `fuhs`
- Schüler-Accounts: `mustermann.m` (Max Mustermann), `musterfrau.e` (Erika Musterfrau) — beide in 6a
- 6 Kapitel für Klasse 6 angelegt (Titel s.u.), nur Kapitel 1 hat 2 Test-Aufgaben ("Was ist ein Algorithmus?", "Daten vs. Informationen"). Kapitel 2–6 sind leer, Inhalte kommen noch.
- **Passwörter bewusst nicht hier** (Repo ist öffentlich) — liegen separat bei dir. Nur Test-Zugänge, vor echtem Rollout ersetzen/rotieren.

### Die 6 Kapitel Klasse 6 (offizielle Reihenfolge/Titel)
1. Informatik - Was ist das?
2. Daten - Rohstoffe der Informatik
3. Algorithmen
4. Programmieren
5. Kryptologie
6. Informatik - Möglichkeiten und Grenzen

## Frontend-Struktur
- [index.html](index.html) — Landingpage mit 3D-Platinen-Logo (Three.js) + Login-Formular (Benutzername/Passwort)
- [assets/supabase-client.js](assets/supabase-client.js) — gemeinsamer Supabase-Client, Login-Helper, Rollen-Erkennung, Redirect-Logik
  - **`SITE_ROOT`** wird relativ zur eigenen Modul-URL berechnet (`import.meta.url`), NICHT hartcodiert als `/`. Grund: GitHub Pages hostet unter `/lmginformatik/`-Unterpfad, Vercel später unter Root. Bei neuen Seiten/Links immer `SITE_ROOT` verwenden, nie `/pfad` hartcodieren.
- [dashboard/index.html](dashboard/index.html) — Schüler-Dashboard: Kapitelübersicht (Gesamt- + Einzel-Fortschrittsbalken) → Klick auf Kapitel → Aufgabenliste mit Textantwort-Feld, Status-Badge (Offen/Eingereicht/Richtig/Teilweise richtig/Nicht richtig)
- [admin/index.html](admin/index.html) — Lehrer-Dashboard: Klassen 6 / Kurs 9 / Kurs 10 → Klassen-/Kursliste → Klassendetail (Schülerfortschritt-Tabelle + offene Einreichungen mit Grün/Gelb/Rot-Buttons, Feedback ist Pflichtfeld vor dem Bewerten)

## Was NICHT im Git liegt (auf Laptop manuell einrichten)
1. **`.mcp.json`** — Supabase-MCP-Verbindung für Claude Code. Auf dem Laptop neu anlegen:
   ```json
   {
     "mcpServers": {
       "supabase": {
         "command": "npx",
         "args": ["-y", "@supabase/mcp-server-supabase@latest", "--project-ref=mdwsojyxklocyhiavkex", "--access-token=DEIN_TOKEN"]
       }
     }
   }
   ```
   Token holen: Supabase Dashboard → Account → Access Tokens (neuen erstellen oder bestehenden wiederverwenden).
2. **`Klasse 6 Buch/`** (und künftige `Klasse 9/10 Buch/`) — eingescannte Schulbuchseiten, urheberrechtlich geschützt, deshalb dauerhaft in `.gitignore`. Diese Ordner musst du separat (USB-Stick/Cloud-eigener, nicht Git) auf den Laptop bringen, falls du dort weiter digitalisieren willst.
3. `gh` CLI Login — auf dem Laptop ggf. `gh auth login` nötig, um zu pushen (oder normaler `git push` mit HTTPS-Credentials).

## Offene To-dos für die Weiterarbeit
- Inhalte/Aufgaben für Kapitel 1 (Rest) bis 6 aus dem Klasse-6-Buch digitalisieren und in `topics`/`tasks` eintragen
- Kurs 9 / Kurs 10: Klassen-Zeilen anlegen (`type='kurs'`, `capacity=30`) + eigenes Curriculum (`topics` für grade 9/10) — Schema unterstützt das bereits vollständig
- Vercel-Deployment einrichten, sobald gewünscht
- Später evtl.: Self-Service-Account-Erstellung für Schüler über eine Edge Function (aktuell lege ich Accounts manuell per SQL an)
- Test-Zugangsdaten vor echtem Einsatz rotieren
- Optional/niedrige Priorität: Supabase-Security-Advisor-Warnungen (rls_auto_enable() als SECURITY DEFINER, Leaked-Password-Protection deaktiviert)
