# Cookly

Cookly is an AI cooking assistant. It looks at what's in your pantry, picks a meal that fits your goals and taste, and writes a step-by-step recipe for it, streaming each stage to the app as it happens.

The backend is a .NET 10 API that runs three AI agents in a handoff workflow on Azure AI Foundry. The client is a Flutter app for iOS and Android.

## How it works

A meal plan request goes through three agents in order:

| Agent | What it does |
| --- | --- |
| **InventoryAgent** | Reads the pantry, flags expired and expiring-soon items, and asks the user a question if it needs one. This is the only step that waits for user input. |
| **NutritionAgent** | Chooses a dish for the requested meal type (breakfast, lunch or dinner) using the pantry, the user's goal and taste preferences, and recent dish history to avoid repeats. If the pantry can't support a new meal, the run ends with a refill message and a list of suggested items. |
| **CookAgent** | Writes the ingredients and step-by-step instructions, and saves the dish to the user's history. |

The app follows the run over Server-Sent Events (`run`, `phase`, `activity`, `input_required`, `refill_required`, `completed`, `error`), so the user can watch it move from "Checking your pantry" to "Recipe written and saved".

### Pantry expiry

When an item is added without an expiry date, the API queues a background job (Coravel) to estimate one:

1. The item name is normalised (descriptors stripped, singularised) and looked up in a seeded shelf-life table.
2. If there's no match, the AI estimates the shelf life and the result is saved to the table for next time.
3. The new expiry date is pushed to the app over SSE (`GET /api/inventory/events`), and the "Estimating expiry…" badge on the item updates.

## Features

- Google sign-in, with JWT sessions stored securely on the device
- Home dashboard with a time-based greeting, recent dishes, search by name, ingredient or meal type, and **Cook Again**
- Pantry management: add, update quantity, delete, and automatic expiry estimates
- Live meal-plan timeline, then a recipe and preparation guide
- Profile with dishes cooked, pantry item count, taste preferences and culinary goal, which NutritionAgent uses on the next plan

## Tech stack

| Layer | Technology |
| --- | --- |
| API | ASP.NET Core (.NET 10), minimal APIs and MVC controllers, JWT bearer auth, OpenAPI with Scalar |
| AI | Microsoft Agent Framework (`Microsoft.Agents.AI`, `Microsoft.Agents.AI.Workflows`), Azure AI Foundry, `gpt-4.1-mini` |
| Data | Entity Framework Core 10, SQL Server |
| Background jobs | Coravel queue |
| Client | Flutter (Dart 3.11), `http`, `google_sign_in`, `flutter_secure_storage`, `google_fonts` |
| Design | Google Stitch |

## Repository layout

```
COOKLY/
├── COOKLY.sln
├── Dockerfile              # Builds and runs Cookly.Api
├── Cookly.Api/             # Endpoints, DI setup, background jobs, SSE
├── Cookly.Agents/          # Inventory, Nutrition and Cook agents and their tools
├── Cookly.Business/        # Services: auth, inventory, dishes, profile, shelf life, AI
├── Cookly.Data/            # DbContext, models, DTOs, migrations, shelf-life seed
└── Client/Cookly.App/      # Flutter app
    └── lib/
        ├── config/         # API base URL, Google OAuth client IDs
        ├── models/
        ├── screens/        # home, pantry, meal_plan, profile, sign_in, splash
        ├── services/       # API clients
        ├── theme/
        └── widgets/
```

## Getting started

### Prerequisites

- [.NET 10 SDK](https://dotnet.microsoft.com/download)
- [Docker](https://www.docker.com/) for SQL Server
- [Flutter](https://docs.flutter.dev/get-started/install) (Dart 3.11 or later), plus Xcode and/or Android Studio
- An Azure AI Foundry project with a `gpt-4.1-mini` deployment, and the [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli)
- `dotnet-ef`: `dotnet tool install --global dotnet-ef`

### 1. Start SQL Server

```bash
docker run -d --name sql_server_container \
  -e "ACCEPT_EULA=Y" -e "MSSQL_SA_PASSWORD=<your-strong-password>" \
  -p 1433:1433 mcr.microsoft.com/mssql/server:2022-latest
```

### 2. Configure the API

Keep secrets out of `appsettings.json`. Use user secrets for local development:

```bash
cd Cookly.Api
dotnet user-secrets set "ConnectionStrings:DefaultConnection" "Server=localhost,1433;Database=Cookly;User Id=sa;Password=<your-strong-password>;TrustServerCertificate=True"
dotnet user-secrets set "JwtSettings:Issuer" "cookly-api"
dotnet user-secrets set "JwtSettings:Audience" "cookly-app"
dotnet user-secrets set "JwtSettings:Key" "<a random key of at least 32 characters>"
dotnet user-secrets set "AzureAIFoundry:Endpoint" "https://<your-resource>.services.ai.azure.com/api/projects/<your-project>"
dotnet user-secrets set "AzureAIFoundry:DeploymentName" "gpt-4.1-mini"
```

The API signs in to Azure with `DefaultAzureCredential`, so run `az login` with an account that has access to the Foundry project.

| Key | Purpose |
| --- | --- |
| `ConnectionStrings:DefaultConnection` | SQL Server connection string |
| `JwtSettings:Issuer`, `JwtSettings:Audience`, `JwtSettings:Key` | JWT signing and validation |
| `AzureAIFoundry:Endpoint`, `AzureAIFoundry:DeploymentName` | Model used by the agents |
| `Coravel:Queue:ConsummationDelay` | Seconds between background queue checks (default in repo: `1`) |

### 3. Create the database

```bash
dotnet ef database update --project Cookly.Data --startup-project Cookly.Api
```

The shelf-life table is seeded on startup from `Cookly.Data/Seed/shelf_life_seed.json`. Only missing rows are added, so it's safe to run more than once.

### 4. Run the API

```bash
dotnet run --project Cookly.Api --launch-profile http
```

The API listens on `http://localhost:5087`. In Development, the interactive API reference is at `http://localhost:5087/scalar/v1`.

To run it in Docker instead:

```bash
docker build -t cookly-api .
docker run -p 8080:8080 --env-file cookly.env cookly-api
```

Pass the configuration as environment variables, using `__` for nesting (for example `JwtSettings__Key`).

### 5. Run the Flutter app

```bash
cd Client/Cookly.App
flutter pub get
flutter run
```

- The API base URL is in `lib/config/api_config.dart`. It uses `localhost:5087` on the iOS simulator and `10.0.2.2:5087` on the Android emulator. A physical device needs your machine's LAN IP.
- Google sign-in needs your own OAuth client IDs in `lib/config/google_auth_config.dart`, and the iOS client ID (plus its reversed URL scheme) in `ios/Runner/Info.plist`.

## API reference

All endpoints except login need an `Authorization: Bearer <token>` header. Responses use one envelope:

```json
{ "data": { }, "success": true, "message": null, "messageKey": null }
```

| Method | Path | Description |
| --- | --- | --- |
| `POST` | `/api/auth/login` | Signs in with the Google account details and returns a JWT |
| `GET` | `/api/profile` | Name, email, member-since date, goal, preferences, dish count and pantry item count |
| `PUT` | `/api/profile/preferences` | Updates the goal and taste preferences (max 350 characters each) |
| `POST` | `/api/inventory/add-item` | Adds a pantry item; expiry is estimated in the background if not given |
| `GET` | `/api/inventory/list-item` | Lists pantry items |
| `PATCH` | `/api/inventory/update-quantity` | Updates an item's quantity |
| `DELETE` | `/api/inventory/delete-item/{itemId}` | Deletes an item |
| `GET` | `/api/inventory/events` | SSE stream of pantry updates, such as expiry estimates |
| `GET` | `/api/dishes/history` | The user's dish history with ingredients and instructions |
| `POST` | `/meal-plan/stream/start` | Starts a meal-plan run and streams its progress over SSE |
| `POST` | `/meal-plan/stream/{runId}/respond` | Answers InventoryAgent's question and resumes the stream |
| `POST` | `/meal-plan/start` | Non-streaming version of the meal-plan run |
| `POST` | `/meal-plan/{runId}/respond` | Non-streaming response to an agent question |

## Testing

```bash
# Backend
dotnet build COOKLY.sln

# Flutter
cd Client/Cookly.App
flutter analyze
flutter test
```

## Known limitations

- Workflow checkpoints, run state, the background queue and the pantry event hub are held in memory. Restarting the API loses in-progress runs and queued expiry jobs, and it only works on a single instance.
- `/api/auth/login` doesn't verify a Google ID token yet; it trusts the email it's sent.
- "Dishes Cooked" counts dishes Cookly has suggested, since the app doesn't track whether a dish was actually cooked.
- Dish names have a unique index across all users (`IX_Dishes_Name`), so saving a dish with an existing name fails.
- An AI shelf-life estimate for an unknown item can take up to about 30 seconds.
