# HouseClash — Flutter App

Mobile frontend for **HouseClash**, a gamified application for household task management.

## Tech Stack
- **Flutter 3.x**
- **Riverpod** (State management)
- **go_router** (Navigation)
- **Dio** (HTTP client)
- **flutter_secure_storage** (Token storage)

## Requirements
- **Flutter** >= 3.19.0
- **Dart** >= 3.3.0

## Setup
1. Copy `.env.example` to `.env` and fill in the variables.
2. Run `flutter pub get` to install dependencies.
3. Run `flutter run` to launch the application.

## Project Structure
The project is located in the `/lib` directory and follows a **feature-driven architecture** with the following layers:
- **Data:** Repositories and data sources.
- **Domain:** Entities and business logic.
- **Presentation:** UI widgets and state providers.