# LEARN-App

**LEARN-App** is an iOS application designed to help German elementary school teachers easily integrate computer science (CS) activities into their regular classes. The app provides a user-friendly, step-based planning wizard and comprehensive search functionality to discover suitable educational materials tailored to specific classroom needs.

---


## 🧠 Introduction

LEARNApp addresses the challenge of finding and integrating appropriate computer science activities for elementary school classrooms. The app simplifies lesson planning by providing:

- **Personalized Recommendations**: Get activity suggestions based on grade level, available time, devices, and topics
- **Easy Discovery**: Browse and search through a curated library of CS activities
- **Streamlined Planning**: Use an intuitive step-by-step wizard to specify your requirements
- **Organized Access**: Save favorites and track your search history

The app is designed specifically for German elementary school teachers, with a simple, German-language interface that requires no technical expertise. Whether you're planning a quick 15-minute activity or a full lesson, LEARNApp helps you find the right materials quickly and efficiently.

---

## 💾 Installation

### Requirements

- macOS with Xcode 15.0 or later
- iOS 17.0 or later
- Swift 5.9+

### Steps

1. Clone the repository:

   ```bash
   git clone https://github.com/your-org/LEARN-App.git
   ```

2. Open the project in Xcode:

   ```bash
   open LEARNApp.xcodeproj
   ```

3. Choose an iPhone simulator or physical device (iOS 17+), then build and run the app.

---

## 🛠 Development

### Architecture Overview

LEARNApp uses a **SwiftUI-native architecture** with clear separation of concerns:

- **Views**: SwiftUI views that manage local state with `@State` and `@StateObject`
- **Global State**: `AppState` as an `ObservableObject` for app-wide authentication and user state
- **Models**: Domain models and data transfer objects (DTOs) for API communication
- **Services**: API clients and business logic services
- **Storage**: Local persistence for favorites, search history, and authentication tokens

This approach leverages SwiftUI's built-in reactive state management while maintaining organized, maintainable code structure.

### Code Structure

```
LEARNApp/
├── Core/
│   ├── Auth/              # Authentication storage and services
│   ├── Config/            # App configuration
│   ├── DesignSystem/      # Reusable UI components, styles, and design tokens
│   └── Networking/        # API clients and network services
├── Data/
│   ├── DTOs/              # Data transfer objects for API responses
│   ├── Mappers/           # Model mapping between DTOs and domain models
│   ├── Models/            # Local data models (favorites, search history)
│   ├── Persistence/       # Local storage implementations
│   └── Storage/           # Storage abstractions
├── Domain/
│   └── Models/            # Domain models (Device, Topic, Grade, etc.)
├── Views/                 # SwiftUI views and screens
└── Utilities/             # Helper functions and extensions
```

### Key Components

| Component | Description |
|-----------|-------------|
| **Views** | SwiftUI screens and UI components |
| `/PlanningView` | Multi-step wizard coordinator |
| `/SearchView` | Search and filter interface |
| `/FavoritesView` | Favorites management |
| `/ProfileView` | User profile and settings |
| **Services** | |
| `/APIClient` | Core networking layer |
| `/ActivitiesAPI` | Activities and recommendations API |
| `/AuthAPI` | Authentication and user management |
| **Models** | |
| `/Recommendation` | Personalized activity recommendations |
| `/Material` | Activity materials and resources |
| `/AppState` | Global app state management |
| **Storage** | |
| `/FavoritesStore` | Local favorites persistence |
| `/LessonPlanStorage` | Search history storage |
| `/AuthStorage` | Authentication token management |

### Design System

The app uses a consistent design system with:

- **Components**: Reusable UI elements (Chip, FilterPicker, MaterialCardView, etc.)
- **Styles**: Button styles and other UI style definitions
- **Tokens**: Design tokens for colors, spacing, and typography

### Key Features Implementation

- **Multi-step Wizard**: `PlanningView` coordinates step navigation with `StepProgressBar` for visual feedback
- **API Integration**: RESTful API communication through `APIClient` with DTO mapping
- **Offline Support**: Local storage for favorites and search history
- **Authentication**: Token-based auth with refresh capabilities
- **State Management**: Views use `@State` and `@StateObject` for local state, while `AppState` (`ObservableObject`) manages global authentication and user state accessible via `@EnvironmentObject`

---

## 📝 Notes

- The app is designed specifically for German elementary school teachers (grades 1-4)
- All user-facing text is in German
- Some features (favorites, search history) require user registration
- The app works with a backend API for activity data and recommendations
