# Flutter User Management App

A Flutter application that demonstrates user management using the BLoC pattern, API integration, and clean code practices.

## Project Overview

This application fetches user data from the DummyJSON API and displays it in a list with infinite scrolling. Users can search for specific users, view user details, and create posts. The app follows the BLoC pattern for state management and is organized using a clean architecture approach.

## Demo Video

[![App Demo](https://img.youtube.com/vi/9h2uv17lDbM/0.jpg)](https://www.youtube.com/watch?v=9h2uv17lDbM)

## Features

- **User List**: Displays users with avatars, names, and emails
- **Infinite Scrolling**: Loads more users as you scroll
- **Search Functionality**: Search users by name in real-time
- **User Details**: View detailed information about a user
- **Posts and Todos**: View posts and todos for each user
- **Create Posts**: Add new posts locally
- **Pull-to-Refresh**: Refresh user data
- **Error Handling**: Proper error handling and loading indicators

## Architecture

The project follows a clean architecture approach with the following components:

### Folder Structure

\`\`\`
lib/
├── core/
│   ├── api/
│   ├── theme/
│   └── utils/
├── features/
│   ├── users/
│   │   ├── bloc/
│   │   ├── models/
│   │   ├── repositories/
│   │   ├── screens/
│   │   └── widgets/
│   ├── posts/
│   │   ├── bloc/
│   │   ├── models/
│   │   ├── repositories/
│   │   ├── screens/
│   │   └── widgets/
│   └── todos/
│       ├── bloc/
│       ├── models/
│       ├── repositories/
│       └── widgets/
├── app.dart
└── main.dart
\`\`\`

### BLoC Pattern

The application uses the BLoC (Business Logic Component) pattern to separate business logic from the UI. Each feature has its own BLoC that handles events and emits states.

- **Events**: Represent user actions or system events
- **States**: Represent the UI state at a given point in time
- **BLoC**: Processes events and emits states

### Repository Pattern

The repository pattern is used to abstract the data sources. Each feature has its own repository that handles data fetching and manipulation.

## Setup Instructions

1. Clone the repository:
   \`\`\`
   git clone https://github.com/yourusername/flutter_user_management.git
   \`\`\`

2. Navigate to the project directory:
   \`\`\`
   cd flutter_user_management
   \`\`\`

3. Install dependencies:
   \`\`\`
   flutter pub get
   \`\`\`

4. Run the app:
   \`\`\`
   flutter run
   \`\`\`

## API Integration

The app integrates with the DummyJSON API:

- Users API: https://dummyjson.com/users
- Posts API: https://dummyjson.com/posts/user/{userId}
- Todos API: https://dummyjson.com/todos/user/{userId}

## Dependencies

- **flutter_bloc**: For state management
- **equatable**: For comparing objects
- **http**: For making API requests
- **shared_preferences**: For local storage (used for offline post)

## Future Improvements

- Implement offline caching with local storage

