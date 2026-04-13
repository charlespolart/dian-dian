# Dian Dian (点点)

A visual year tracker where you color-code each day of the year on a 12-month x 31-day grid. Built with a pixel art aesthetic and a cozy book-style design.

**Live:** [mydiandian.app](https://mydiandian.app)

## Features

- **Year grid** -- 12 months x 31 days, color each day with a pastel palette + custom colors
- **Multiple pages** -- Create separate trackers (mood, reading, exercise, sleep, period, etc.)
- **Legends** -- Label colors with custom descriptions, drag-to-reorder
- **Quick fill** -- Select a legend from the sidebar, then tap cells to fill instantly
- **Cell editor** -- Tap a cell to assign a legend color and add a comment
- **Stats** -- Days filled, best streak, yearly percentage, distribution, monthly progress, day-of-week breakdown
- **Global stats** -- Cross-tracker overview with most active tracker and per-tracker dot counts
- **Export** -- Share any tracker as a PNG image
- **Themes** -- 7 themes including Sakura, Forest, Midnight dark mode, and more
- **Animated cursors** -- Fun cursor companions (premium)
- **Premium** -- In-App Purchase (lifetime + subscriptions) with AdMob banner for free users
- **Onboarding** -- Interactive walkthrough for new users
- **Real-time sync** -- WebSocket-based, changes sync instantly across devices
- **Multi-language** -- French, English, Simplified Chinese, Traditional Chinese (auto-detects device language)
- **Cross-platform** -- Web, iOS, Android via Flutter
- **Responsive** -- Adapts to phone, tablet, and desktop in portrait and landscape

## Tech Stack

| Layer | Tech |
|-------|------|
| Frontend | Flutter (Dart) |
| Backend | Express, TypeScript |
| Database | PostgreSQL, Drizzle ORM |
| Auth | JWT (access + refresh token rotation), argon2id |
| Real-time | WebSocket (ws) |
| Fonts | Silkscreen, DotGothic16 (bundled) |
| Deploy | Nginx, systemd, Let's Encrypt |

## Project Structure

```
dian-dian/
├── backend/
│   ├── src/
│   │   ├── db/           # Schema & database connection
│   │   ├── lib/          # JWT, env, WebSocket, email
│   │   ├── middleware/    # Auth, validation
│   │   └── routes/       # Auth, pages, cells, legends, legal
│   ├── drizzle/          # SQL migrations
│   └── tsconfig.json
├── flutter_app/
│   ├── lib/
│   │   ├── models/       # PageModel, CellModel, LegendModel
│   │   ├── providers/    # Auth, Pages, Cells, Legends, Language, Premium, Theme
│   │   ├── screens/      # Login, Register, PageList, Tracker, Settings
│   │   ├── services/     # API, WebSocket, Storage
│   │   ├── theme/        # Colors, fonts, theme
│   │   └── widgets/      # Grid, dialogs, shared components
│   ├── assets/           # Icons, fonts, sounds, cursors, images
│   └── pubspec.yaml
├── nginx.conf
└── deploy.sh
```

## Development

### Prerequisites

- Node.js 22+
- PostgreSQL
- Flutter SDK

### Backend

```bash
cd backend
cp .env.example .env  # Edit with your database credentials
npm install
npx drizzle-kit migrate
npm run dev            # Starts on http://localhost:3001
```

### Flutter App

```bash
cd flutter_app
flutter pub get
flutter run -d chrome --web-port=8081   # Web dev
flutter run -d ios                       # iOS simulator
flutter run -d android                   # Android emulator
```

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `DATABASE_URL` | PostgreSQL connection string | required |
| `JWT_SECRET` | Secret for signing JWTs | required |
| `PORT` | Backend port | `3001` |
| `CORS_ORIGIN` | Allowed frontend origin | `http://localhost:8081` |

## Deployment

The app is designed to run on a single VPS with Nginx as a reverse proxy.

```bash
# On the server
git clone git@github.com:charlespolart/dian-dian.git
cd dian-dian

# Create production .env
nano backend/.env

# Setup Nginx
cp nginx.conf /etc/nginx/sites-available/diandian
ln -s /etc/nginx/sites-available/diandian /etc/nginx/sites-enabled/
certbot --nginx -d mydiandian.app
nginx -t && systemctl restart nginx

# Deploy (requires Flutter SDK on server)
chmod +x deploy.sh
./deploy.sh
```

The deploy script builds the backend, runs migrations, builds Flutter for web, and starts the systemd service.

## License

All rights reserved.
