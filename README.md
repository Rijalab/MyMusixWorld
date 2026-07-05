🎵 MyMusixWorld

Your Music. Your World. Anywhere.

MyMusixWorld is a cross-platform personal music streaming application that allows users to stream and manage their own music library stored in cloud storage. The first version uses Google Drive as the primary storage provider, with a modular architecture that supports additional providers in the future.

Unlike commercial streaming services, MyMusixWorld does not provide or distribute music. It is designed to help users organize, stream, and enjoy their own music collection in a clean, ad-free experience.

⸻

✨ Features

* 🎵 Stream personal music directly from Google Drive
* 📱 Cross-platform support
    * Android
    * iOS
    * iPadOS
    * macOS
    * Windows
* 🔍 Instant search
* ❤️ Favorites
* 📂 Browse by Albums, Artists, Genres & Folders
* 📃 Playlist management
* ⬇️ Offline downloads
* 🎧 Background playback
* 🎨 Light & Dark themes
* ⚡ Fast local indexing using SQLite
* 🔄 Automatic library synchronization
* 📶 Smart caching for smooth streaming

⸻

🚀 Vision

MyMusixWorld aims to provide a modern, lightweight, privacy-focused music player that gives users complete ownership of their music library without advertisements, subscriptions, or unnecessary online services.

The application is built around the concept of “Bring Your Own Music”, allowing users to connect their preferred cloud storage and enjoy their collection across multiple devices.

⸻

🏗 Architecture

Flutter Application
│
├── Presentation Layer
├── Business Logic Layer
├── Repository Layer
├── Storage Provider Layer
├── Database Layer
└── Audio Playback Layer

⸻

📦 Technology Stack

* Flutter
* Dart
* Riverpod
* SQLite
* Google Drive API
* OAuth 2.0
* Clean Architecture
* MVVM Pattern

⸻

☁️ Storage Providers

Current

* Google Drive

Planned

* OneDrive
* Dropbox
* iCloud Drive
* Local Folder
* NAS
* SMB
* WebDAV
* Jellyfin
* Plex

The application is designed around a StorageProvider abstraction, allowing additional storage providers to be added without changing the core application.

⸻

📁 Expected Google Drive Structure

MyMusic/
├── Tamil/
│   ├── Artist/
│   │   ├── Album/
│   │   │   ├── Song1.mp3
│   │   │   └── Song2.flac
│
├── English/
├── Hindi/
├── Instrumental/
├── Playlists/
└── Artwork/

The application recursively scans this folder, extracts metadata, and creates a fast local searchable library.

⸻

🎼 Supported Audio Formats

* MP3
* AAC
* M4A
* FLAC
* WAV
* OGG

⸻

📚 Library

* Songs
* Albums
* Artists
* Genres
* Folder View
* Favorites
* Downloads
* Playlists
* Recently Played

⸻

▶️ Playback Features

* Play / Pause
* Previous / Next
* Shuffle
* Repeat
* Queue
* Sleep Timer
* Playback Speed
* Background Playback
* Lock Screen Controls
* Album Artwork
* Offline Playback

⸻

🔍 Search

Search by:

* Song
* Artist
* Album
* Genre
* Folder
* Filename

⸻

🔄 Synchronization

On startup, MyMusixWorld:

1. Authenticates with Google.
2. Scans the configured MyMusic folder.
3. Detects new, updated, or removed songs.
4. Updates the local SQLite database.
5. Refreshes the music library automatically.

⸻

📌 Project Status

🚧 Under Active Development

Current focus:

* Flutter project setup
* Google Drive integration
* Music library indexing
* Audio playback engine
* Local database
* Cross-platform user interface

⸻

🛣 Roadmap

Phase 1

* Flutter project setup
* Google OAuth integration
* Google Drive API
* Music scanning
* SQLite database
* Basic music player

Phase 2

* Albums
* Artists
* Genres
* Search
* Favorites
* Playlists

Phase 3

* Offline downloads
* Smart cache
* Background synchronization
* Performance optimization

Phase 4

* Lyrics
* Equalizer
* Chromecast
* AirPlay
* Themes
* Sleep Timer

Phase 5

* Additional storage providers
* AI-powered playlists
* Voice search
* Desktop widgets

⸻

🤝 Contributing

MyMusixWorld is currently a personal project. Feature suggestions and improvements are always welcome as the project evolves.

⸻

📄 License

MyMusixWorld is a personal cloud music player.

The application does not host, distribute, or provide copyrighted music. Users are responsible for ensuring they have the legal rights to store and stream any content they access through the application.

⸻

❤️ Philosophy

Your Music. Your Cloud. Your World.

Simple. Fast. Ad-Free.