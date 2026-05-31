# Color Configuration System

## Overview
The app now uses a **centralized color configuration system** to ensure consistency across all platforms (Flutter app, icons, assets, etc.).

## File Structure

```
lib/config/
├── app_color_config.dart    # Dart color definitions & theme
└── colors.json              # JSON color data (used by Python scripts & documentation)
```

## Usage

### In Dart/Flutter
```dart
import 'package:permission_scanner/config/app_color_config.dart';

// Use the new AppColorConfig class for primary colors
Color green = AppColorConfig.primaryMain;       // #0E7B72
Color darkGreen = AppColorConfig.primaryDark;   // #0A5D56
Color lightGreen = AppColorConfig.primaryLight; // #95CBC5

// Backward compatibility - AppColors still works
Color primary = AppColors.primary;              // Same as above
```

### In Python (Icon Generation)
The `generate_icon.py` script automatically loads colors from `lib/config/colors.json`:

```bash
python3 generate_icon.py
```

Colors are loaded dynamically, so any changes to `lib/config/colors.json` will be reflected in newly generated icons.

## Color Palette

| Color | Hex | Usage |
|-------|-----|-------|
| Primary Main | `#0E7B72` | Logo, badges, accents |
| Primary Dark | `#0A5D56` | Gradients, backgrounds |
| Primary Light | `#95CBC5` | Highlights, hover states |
| Secondary | `#95CBC5` | Secondary accents |
| Safe (Green) | `#16A34A` | Secure permissions |
| Medium (Amber) | `#F59E0B` | Caution warnings |
| Dangerous (Red) | `#DC2626` | Dangerous permissions |
| Critical (Dark Red) | `#7F1D1D` | Critical risks |

## Adding New Colors

When adding a new color:
1. Add it to `lib/config/colors.json`
2. Add it to `lib/config/app_color_config.dart` (AppColorConfig class)
3. Update the AppColors alias if needed for backward compatibility

## Migration Notes

- The original `lib/utils/app_colors.dart` still works (backward compatible)
- New code should use `AppColorConfig` from `lib/config/app_color_config.dart`
- The `AppColors` alias ensures existing code doesn't break
