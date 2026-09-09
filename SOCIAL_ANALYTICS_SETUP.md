# Social Analytics – Backend-Setup

Die App enthält **keine API-Secrets**. Die vier Connectoren
(`InstagramAnalyticsProvider`, `FacebookAnalyticsProvider`, `TikTokAnalyticsProvider`,
`YouTubeAnalyticsProvider` in `SocialMediaTKC/Services/SocialAnalytics/`) sind aktuell
Stubs, die `SocialAnalyticsProviderError.notConnected` werfen. Damit ist die App voll
nutzbar (manuelle Erfassung von Accounts/Posts/Snapshots über die UI), aber ohne
automatischen Abruf von den Plattformen.

## Zielarchitektur

```
SwiftUI App → eigenes Backend → Social API Connector → Instagram/Facebook/TikTok/YouTube
```

Die App ruft nie direkt Meta/TikTok/Google auf. Ein eigenes Backend (empfohlen: Supabase
Edge Functions, da das Projekt bereits Supabase für Team-Sync nutzt) hält die OAuth-Tokens
und stellt der App normalisierte Endpunkte bereit.

## Warum ein Backend nötig ist

- **Instagram/Facebook (Meta Graph API):** Access Tokens sind langlebig, aber
  App-Review-pflichtig für `instagram_manage_insights`/`read_insights`. Tokens dürfen nicht
  im Client liegen (Reverse-Engineering-Risiko, App-Store-Review).
- **TikTok:** OAuth2-Flow mit Redirect-URI, die serverseitig validiert werden muss;
  Content-Posting/Display-API-Zugriff erfordert eine von TikTok freigegebene App.
- **YouTube:** Google-OAuth-Refresh-Tokens dürfen laut Google-Richtlinien nicht im Client
  gespeichert werden, wenn mehrere Personen/Geräte denselben Kanal verwalten.

## Was pro Plattform zu tun ist

| Plattform | Voraussetzung | Wichtigste Scopes |
|---|---|---|
| Instagram | Facebook Business-Verifizierung, Instagram-Business-Account | `instagram_basic`, `instagram_manage_insights` |
| Facebook | Facebook-Seite mit Admin-Zugriff | `pages_read_engagement`, `read_insights` |
| TikTok | TikTok for Developers Account, App-Freigabe | Login Kit + Display API Scopes |
| YouTube | Google Cloud Projekt, OAuth-Consent-Screen | `youtube.readonly`, `yt-analytics.readonly` |

## Backend-Endpunkte, die die App erwartet

Die App ruft (sobald `AppSettings.socialAnalyticsBackendURL` gesetzt ist) folgende
normalisierte Endpunkte auf - das Backend übersetzt sie in die jeweilige Plattform-API:

```
GET  /accounts/{platform}/{externalAccountId}          → RemoteAccountData
GET  /accounts/{platform}/{externalAccountId}/posts     → [RemotePostData]
GET  /posts/{platform}/{externalPostId}/snapshot        → RemoteSnapshotData
```

Die genauen Typen stehen in `SocialAnalyticsProvider.swift`. Ein Backend-Team muss nur
die vier Provider-Dateien mit echten `URLSession`-Calls gegen diese Endpunkte füllen -
Datenmodell, Sync-Kadenz und UI ändern sich dadurch nicht.

## Sync-Kadenz

Konfigurierbar unter Einstellungen → Social Analytics (Default wie im Konzept
vorgegeben): unter 48h alle 2h, 2-7 Tage alle 6h, 7-30 Tage täglich, über 30 Tage alle
3 Tage. `SocialAnalyticsSyncScheduler.syncAll` entscheidet je Post anhand
`SocialPost.ageInHours`, ob ein neuer Snapshot fällig ist.

## Ohne Backend nutzbar

Auch ohne Backend ist das Modul voll funktionsfähig für manuell gepflegte Daten:
Accounts anlegen (Mehr/Analytics → Social Accounts), Posts erfassen, Snapshots über die
Zeit von Hand nachtragen. Das ist z.B. sinnvoll, um Kennzahlen aus den nativen
Insights-Apps der Plattformen manuell zu übertragen, bis ein Backend steht.
