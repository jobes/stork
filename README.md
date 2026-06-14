# Stork

Stork is a high-performance aeronautical navigation application built with Flutter. It provides pilots and aviation enthusiasts with a robust tool for map visualization, offline map management, and aeronautical data integration.

## 🚀 Key Features

- **Vector Map Visualization**: Seamless map experience powered by MapLibre.
- **Offline Maps (PMTiles)**: Advanced offline map support using the PMTiles format for efficient storage and retrieval.
- **Robust Download System**: Reliable background downloading of map regions with progress tracking and fault tolerance.
- **openAIP Integration**: Seamless integration with openAIP for up-to-date airspaces, airports, and other aeronautical metadata.
- **Dynamic Country Detection**: Automatic identification of countries within downloaded map tiles.
- **SQLite Metadata Sync**: Persistent local storage for aeronautical features and metadata.
- **Multi-language Support**: Available in English and Slovak.

## 🛠️ Tech Stack

- **Framework**: [Flutter](https://flutter.dev)
- **State Management**: [Riverpod](https://riverpod.dev) (with code generation)
- **Navigation**: [GoRouter](https://pub.dev/packages/go_router)
- **Database**: [SQLite](https://pub.dev/packages/sqlite3)
- **Maps**: [MapLibre](https://pub.dev/packages/maplibre), [PMTiles](https://pub.dev/packages/pmtiles)
- **Styling**: MapLibre vector styles with OpenAIP assets.

## ⚙️ Getting Started

### Prerequisites

- Flutter SDK (latest stable version recommended)
- Android Studio / VS Code with Flutter extensions

### Environment Setup

1.  **Environment Variables**:
    Create a `.env` file in the root directory (you can use `.env.example` as a template):
    ```bash
    cp .env.example .env
    ```
2.  **API Keys**:
    Set your `OPENAIP_API_KEY` in the `.env` file. This key is required to fetch aeronautical data and map styles.
    ```env
    OPENAIP_API_KEY=your_api_key_here
    ```

### Native Dependencies

This project uses `libcanard` as a Git submodule for handling CAN frames via the `cannelloni` bridge. When cloning the repository for the first time, you must initialize the submodules:
```bash
git submodule update --init --recursive
```

### Installation & Running

1.  **Fetch dependencies**:
    ```bash
    flutter pub get
    ```
2.  **Generate code** (for Riverpod and other generators):
    ```bash
    dart run build_runner build --delete-conflicting-outputs
    ```
3.  **Run the application**:
    ```bash
    flutter run
    ```

## 📂 Project Structure

- `lib/core`: Core utilities, themes, and routing.
- `lib/features/map`: Map visualization logic and providers.
- `lib/features/offline_maps`: Offline region management and download services.
- `lib/core/services/database`: SQLite database implementation and DAOs.
- `assets/openaip`: Vector styles and sprites for aeronautical visualization.

## 📄 License

This project is private and intended for personal use or specific distribution. See `pubspec.yaml` for package details.
