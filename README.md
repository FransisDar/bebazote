# Bebazote

Ride-hailing prototype built with Flutter, Mapbox, a Go backend, and a temporary hardcoded login that mirrors where Supabase auth will plug in later.

## Demo Login

- Email: `rider@bebazote.app`
- Password: `demo123`

## Flutter App

Install packages:

```sh
flutter pub get
```

Android builds also need a private Mapbox downloads token so Gradle can fetch the
Mapbox SDK artifacts. Add it to your user Gradle properties file so it stays out
of source control:

```properties
# C:\Users\DELL\.gradle\gradle.properties
MAPBOX_DOWNLOADS_TOKEN=YOUR_SECRET_MAPBOX_DOWNLOADS_TOKEN
```

Run with Mapbox enabled:

```sh
flutter run --dart-define=MAPBOX_ACCESS_TOKEN=YOUR_MAPBOX_TOKEN
```

Optional backend URL override:

```sh
flutter run --dart-define=MAPBOX_ACCESS_TOKEN=YOUR_MAPBOX_TOKEN --dart-define=API_BASE_URL=http://localhost:8080
```

If `MAPBOX_ACCESS_TOKEN` is missing, the app shows a local map-style fallback so the rest of the ride booking UI can still be tested.

## Go Backend

Run the placeholder API:

```sh
cd backend
go run .
```

Endpoints:

- `GET /health`
- `POST /quotes`
- `POST /rides`

The current Flutter UI uses local quote/request state while the backend contract is in place for the next integration step.
