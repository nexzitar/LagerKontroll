# Complete Project Directory Structure

## Full Directory Tree

```
LagerKontroll/
├── android/                          # Android platform files
├── ios/                              # iOS platform files
├── lib/
│   ├── main.dart                     # Entry point
│   ├── app.dart                      # Root widget
│   │
│   ├── core/
│   │   ├── config/
│   │   │   ├── app_config.dart
│   │   │   ├── env_config.dart
│   │   │   └── routes.dart
│   │   │
│   │   ├── constants/
│   │   │   ├── api_constants.dart
│   │   │   ├── ui_constants.dart
│   │   │   └── asset_constants.dart
│   │   │
│   │   ├── theme/
│   │   │   ├── app_theme.dart
│   │   │   ├── app_colors.dart
│   │   │   └── app_text_styles.dart
│   │   │
│   │   ├── utils/
│   │   │   ├── logger.dart
│   │   │   ├── validators.dart
│   │   │   ├── formatters.dart
│   │   │   └── extensions/
│   │   │       ├── string_extensions.dart
│   │   │       ├── date_extensions.dart
│   │   │       └── context_extensions.dart
│   │   │
│   │   ├── errors/
│   │   │   ├── failures.dart
│   │   │   └── exceptions.dart
│   │   │
│   │   └── network/
│   │       ├── api_client.dart
│   │       ├── api_interceptor.dart
│   │       ├── network_info.dart
│   │       └── endpoints.dart
│   │
│   ├── features/
│   │   │
│   │   ├── capture/
│   │   │   ├── data/
│   │   │   │   ├── models/
│   │   │   │   │   ├── trailer_capture_model.dart
│   │   │   │   │   ├── trailer_capture_model.g.dart
│   │   │   │   │   ├── terminal_model.dart
│   │   │   │   │   ├── terminal_model.g.dart
│   │   │   │   │   ├── location_model.dart
│   │   │   │   │   └── location_model.g.dart
│   │   │   │   │
│   │   │   │   ├── repositories/
│   │   │   │   │   └── capture_repository_impl.dart
│   │   │   │   │
│   │   │   │   └── datasources/
│   │   │   │       ├── capture_remote_datasource.dart
│   │   │   │       └── capture_local_datasource.dart
│   │   │   │
│   │   │   ├── domain/
│   │   │   │   ├── entities/
│   │   │   │   │   ├── trailer_capture.dart
│   │   │   │   │   ├── terminal.dart
│   │   │   │   │   └── location.dart
│   │   │   │   │
│   │   │   │   ├── repositories/
│   │   │   │   │   └── capture_repository.dart
│   │   │   │   │
│   │   │   │   └── usecases/
│   │   │   │       ├── capture_trailer.dart
│   │   │   │       ├── capture_location.dart
│   │   │   │       ├── upload_images.dart
│   │   │   │       └── validate_license_plate.dart
│   │   │   │
│   │   │   └── presentation/
│   │   │       ├── providers/
│   │   │       │   ├── capture_provider.dart
│   │   │       │   ├── capture_provider.g.dart
│   │   │       │   ├── camera_provider.dart
│   │   │       │   ├── camera_provider.g.dart
│   │   │       │   ├── location_provider.dart
│   │   │       │   └── location_provider.g.dart
│   │   │       │
│   │   │       ├── screens/
│   │   │       │   └── capture_screen.dart
│   │   │       │
│   │   │       └── widgets/
│   │   │           ├── camera_view.dart
│   │   │           ├── terminal_selector.dart
│   │   │           ├── license_plate_input.dart
│   │   │           ├── location_display.dart
│   │   │           └── empty_checkbox.dart
│   │   │
│   │   ├── browse/
│   │   │   ├── data/
│   │   │   │   ├── models/
│   │   │   │   │   ├── trailer_model.dart
│   │   │   │   │   ├── trailer_model.g.dart
│   │   │   │   │   ├── filter_options_model.dart
│   │   │   │   │   └── sort_options_model.dart
│   │   │   │   │
│   │   │   │   ├── repositories/
│   │   │   │   │   └── browse_repository_impl.dart
│   │   │   │   │
│   │   │   │   └── datasources/
│   │   │   │       ├── browse_remote_datasource.dart
│   │   │   │       └── browse_local_datasource.dart
│   │   │   │
│   │   │   ├── domain/
│   │   │   │   ├── entities/
│   │   │   │   │   ├── trailer.dart
│   │   │   │   │   ├── trailer_status.dart
│   │   │   │   │   ├── filter_options.dart
│   │   │   │   │   └── sort_options.dart
│   │   │   │   │
│   │   │   │   ├── repositories/
│   │   │   │   │   └── browse_repository.dart
│   │   │   │   │
│   │   │   │   └── usecases/
│   │   │   │       ├── get_trailers.dart
│   │   │   │       ├── filter_trailers.dart
│   │   │   │       ├── sort_trailers.dart
│   │   │   │       └── search_trailers.dart
│   │   │   │
│   │   │   └── presentation/
│   │   │       ├── providers/
│   │   │       │   ├── browse_provider.dart
│   │   │       │   ├── browse_provider.g.dart
│   │   │       │   ├── filter_provider.dart
│   │   │       │   ├── filter_provider.g.dart
│   │   │       │   ├── sort_provider.dart
│   │   │       │   └── sort_provider.g.dart
│   │   │       │
│   │   │       ├── screens/
│   │   │       │   └── browse_screen.dart
│   │   │       │
│   │   │       └── widgets/
│   │   │           ├── trailer_list_item.dart
│   │   │           ├── filter_bottom_sheet.dart
│   │   │           ├── sort_menu.dart
│   │   │           └── search_bar.dart
│   │   │
│   │   ├── detail/
│   │   │   ├── data/
│   │   │   │   ├── models/
│   │   │   │   │   ├── trailer_detail_model.dart
│   │   │   │   │   ├── trailer_detail_model.g.dart
│   │   │   │   │   ├── history_entry_model.dart
│   │   │   │   │   └── history_entry_model.g.dart
│   │   │   │   │
│   │   │   │   ├── repositories/
│   │   │   │   │   └── detail_repository_impl.dart
│   │   │   │   │
│   │   │   │   └── datasources/
│   │   │   │       ├── detail_remote_datasource.dart
│   │   │   │       └── detail_local_datasource.dart
│   │   │   │
│   │   │   ├── domain/
│   │   │   │   ├── entities/
│   │   │   │   │   ├── trailer_detail.dart
│   │   │   │   │   └── history_entry.dart
│   │   │   │   │
│   │   │   │   ├── repositories/
│   │   │   │   │   └── detail_repository.dart
│   │   │   │   │
│   │   │   │   └── usecases/
│   │   │   │       ├── get_trailer_detail.dart
│   │   │   │       ├── get_trailer_history.dart
│   │   │   │       ├── mark_trailer_empty.dart
│   │   │   │       └── update_trailer_location.dart
│   │   │   │
│   │   │   └── presentation/
│   │   │       ├── providers/
│   │   │       │   ├── detail_provider.dart
│   │   │       │   ├── detail_provider.g.dart
│   │   │       │   ├── history_provider.dart
│   │   │       │   └── history_provider.g.dart
│   │   │       │
│   │   │       ├── screens/
│   │   │       │   └── detail_screen.dart
│   │   │       │
│   │   │       └── widgets/
│   │   │           ├── trailer_photo_viewer.dart
│   │   │           ├── location_map.dart
│   │   │           ├── history_list.dart
│   │   │           ├── history_list_item.dart
│   │   │           ├── action_buttons.dart
│   │   │           └── trailer_info_card.dart
│   │   │
│   │   └── settings/
│   │       ├── data/
│   │       │   ├── models/
│   │       │   │   ├── settings_model.dart
│   │       │   │   └── settings_model.g.dart
│   │       │   │
│   │       │   ├── repositories/
│   │       │   │   └── settings_repository_impl.dart
│   │       │   │
│   │       │   └── datasources/
│   │       │       └── settings_local_datasource.dart
│   │       │
│   │       ├── domain/
│   │       │   ├── entities/
│   │       │   │   └── app_settings.dart
│   │       │   │
│   │       │   ├── repositories/
│   │       │   │   └── settings_repository.dart
│   │       │   │
│   │       │   └── usecases/
│   │       │       ├── get_settings.dart
│   │       │       ├── update_settings.dart
│   │       │       └── reset_settings.dart
│   │       │
│   │       └── presentation/
│   │           ├── providers/
│   │           │   ├── settings_provider.dart
│   │           │   └── settings_provider.g.dart
│   │           │
│   │           ├── screens/
│   │           │   └── settings_screen.dart
│   │           │
│   │           └── widgets/
│   │               ├── settings_section.dart
│   │               ├── settings_item.dart
│   │               └── settings_slider.dart
│   │
│   └── shared/
│       ├── widgets/
│       │   ├── loading_indicator.dart
│       │   ├── error_view.dart
│       │   ├── empty_state.dart
│       │   ├── custom_button.dart
│       │   ├── custom_text_field.dart
│       │   └── app_bar_with_title.dart
│       │
│       └── dialogs/
│           ├── confirmation_dialog.dart
│           ├── error_dialog.dart
│           └── info_dialog.dart
│
├── test/
│   ├── fixtures/
│   │   ├── trailer_capture.json
│   │   ├── trailer_list.json
│   │   └── trailer_detail.json
│   │
│   ├── helpers/
│   │   ├── test_helper.dart
│   │   └── pump_app.dart
│   │
│   ├── unit/
│   │   ├── core/
│   │   │   ├── network/
│   │   │   │   └── network_info_test.dart
│   │   │   └── utils/
│   │   │       └── validators_test.dart
│   │   │
│   │   └── features/
│   │       ├── capture/
│   │       │   ├── data/
│   │       │   │   ├── models/
│   │       │   │   │   └── trailer_capture_model_test.dart
│   │       │   │   └── repositories/
│   │       │   │       └── capture_repository_impl_test.dart
│   │       │   └── domain/
│   │       │       └── usecases/
│   │       │           └── capture_trailer_test.dart
│   │       │
│   │       ├── browse/
│   │       │   └── domain/
│   │       │       └── usecases/
│   │       │           └── get_trailers_test.dart
│   │       │
│   │       └── detail/
│   │           └── domain/
│   │               └── usecases/
│   │                   └── get_trailer_detail_test.dart
│   │
│   ├── widget/
│   │   └── features/
│   │       ├── capture/
│   │       │   └── screens/
│   │       │       └── capture_screen_test.dart
│   │       │
│   │       └── browse/
│   │           └── screens/
│   │               └── browse_screen_test.dart
│   │
│   └── integration/
│       └── app_test.dart
│
├── assets/
│   ├── images/
│   │   ├── logo.png
│   │   ├── placeholder.png
│   │   └── empty_state.svg
│   │
│   ├── icons/
│   │   └── app_icon.png
│   │
│   └── fonts/
│       └── (custom fonts if needed)
│
├── shorebird.yaml                    # Shorebird configuration
├── pubspec.yaml                      # Dependencies
├── analysis_options.yaml             # Linting rules
├── README.md                         # Project documentation
├── ARCHITECTURE.md                   # This file
└── .env                              # Environment variables (gitignored)
```

## File Count Summary

- **Core files**: ~20 files
- **Features** (4 features × ~25 files): ~100 files
- **Shared components**: ~10 files
- **Tests**: ~50 files
- **Total Dart files**: ~180 files

## Key Directories Explained

### `/lib/core/`
Cross-cutting concerns that are used across all features:
- Configuration and constants
- Theme and styling
- Utilities and extensions
- Error handling
- Network setup

### `/lib/features/{feature}/`
Each feature is self-contained with three layers:

1. **data/**: Implementation details
   - Models with JSON serialization
   - Repository implementations
   - Data sources (remote API, local cache)

2. **domain/**: Business logic (pure Dart)
   - Entities (business objects)
   - Repository interfaces
   - Use cases (business operations)

3. **presentation/**: UI layer
   - Providers (state management)
   - Screens (full pages)
   - Widgets (reusable UI components)

### `/lib/shared/`
Reusable UI components that aren't specific to any feature

### `/test/`
Mirrors the `/lib/` structure with:
- Unit tests for business logic
- Widget tests for UI components
- Integration tests for full app flows

## Generated Files

Files ending in `.g.dart` are auto-generated by build_runner:
- JSON serialization code
- Riverpod providers
- Hive type adapters

Generate them with:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

## Naming Conventions

### Files
- `snake_case` for all file names
- `{name}_model.dart` for data models
- `{name}_provider.dart` for Riverpod providers
- `{name}_screen.dart` for full-page screens
- `{name}_test.dart` for test files

### Classes
- `PascalCase` for all class names
- `{Name}Model` for data models
- `{Name}Provider` for Riverpod providers
- `{Name}Screen` for screens
- `{Name}Repository` for repositories
- `{Name}DataSource` for data sources

### Variables
- `camelCase` for variable names
- `SCREAMING_SNAKE_CASE` for constants
- Prefix private members with `_`

## Import Organization

```dart
// Dart SDK
import 'dart:async';
import 'dart:io';

// Flutter framework
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Third-party packages
import 'package:riverpod/riverpod.dart';
import 'package:dio/dio.dart';

// Your app imports
import 'package:your_app/core/config/app_config.dart';
import 'package:your_app/features/capture/domain/entities/trailer.dart';

// Relative imports (within same feature)
import '../models/trailer_model.dart';
import 'capture_provider.dart';
```

## Assets Organization

```yaml
# pubspec.yaml
flutter:
  assets:
    - assets/images/
    - assets/icons/

  fonts:
    - family: CustomFont
      fonts:
        - asset: assets/fonts/CustomFont-Regular.ttf
        - asset: assets/fonts/CustomFont-Bold.ttf
          weight: 700
```

Access via constants:
```dart
// core/constants/asset_constants.dart
class AssetConstants {
  static const String logo = 'assets/images/logo.png';
  static const String placeholder = 'assets/images/placeholder.png';
  static const String emptyState = 'assets/images/empty_state.svg';
}
```
