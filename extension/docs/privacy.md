# Privacy and permissions

| Permission / host           | Why                                                           | When requested                 |
| --------------------------- | ------------------------------------------------------------- | ------------------------------ |
| `sidePanel`                 | Show the panel                                                | Always                         |
| `activeTab`, `scripting`    | Inject the adapter into the tab the lecturer is reading       | Always                         |
| `storage`                   | Session-only lecturer and Google tokens                       | Always                         |
| Fixture origins             | Read and fill the synthetic `mock-fap-v2` page                | Always (from env)              |
| `file:///*`                 | Read and fill a saved lecturer HTML (user must also allow it) | Always                         |
| Firebase Auth + Firestore   | Hereby lecturer sign-in, read own closed slots (REST)         | When `VITE_HEREBY_API_KEY` set |
| `identity`, Sheets API host | Read-only Google Sheets import                                | When Google client ID set      |

Data handling:

- Student rows are read from the open tab and kept in panel memory only. Nothing is persisted.
- Passwords are sent once over HTTPS and never stored. The Hereby ID/refresh tokens and the Google
  access token live in `chrome.storage.session` and disappear when the browser closes.
- Imported files are parsed locally; nothing is uploaded. Google Sheets access is read-only.
- No analytics, no remote code, no cookie access, no access to live FAP.
