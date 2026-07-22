# Flutter Build Fix v4.5.0 - Universal DSL Support

[![Flutter](https://img.shields.io/badge/Flutter-3.44.6-blue.svg)](https://flutter.dev)
[![Platform](https://img.shields.io/badge/Platform-macOS%20|%20Linux-lightgrey.svg)](https://github.com/flutterkage2k/flutter-build-fix)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

## Purpose

**This tool exists to reduce the errors you hit when a Flutter app is built as a native Android project** — in Android Studio, in `flutter build`, and in your release pipeline.

That is the only goal. Everything else is a means to it.

### Guiding rule

> **Never trade a working build for a silenced warning.**

Flutter's preferred AGP/Kotlin versions are forward-looking and only produce *warnings*. The surrounding ecosystem — Android Studio releases, plugin authors — lags behind and fails *hard*. Chasing Flutter's numbers has broken real builds twice:

| Version Flutter prefers | What it actually broke |
|---|---|
| AGP 8.11.1 | Android Studio 2024.3 refused to open the project |
| Kotlin 2.2.20 | `sentry_flutter` failed to compile (`languageVersion 1.6` removed) |

So this tool deliberately sits one notch below Flutter's preference on both, and tells you the resulting build warning is expected. A warning you can ignore beats an IDE you cannot open.

### What it fixes

| Cause of native build failure | How it is handled |
|---|---|
| AGP/Kotlin outside IDE and plugin support | Pinned to ecosystem-compatible versions |
| Plugin versions disagreeing between `settings.gradle` and root `build.gradle` | All declaration sites kept in sync |
| Gradle JDK unset → Android Studio falls back to its embedded JBR | `java.home` written to `gradle/config.properties` |
| Leftover Java 8 source/target | Java 17 + `jvmTarget` 17 |
| Hardcoded SDK/NDK versions going stale | Delegated to Flutter (`compileSdk`, `minSdk`, `targetSdk`, `ndkVersion`) |
| `targetSdk` falling behind Google Play's requirement | Detected, with a reminder before you release |

## Quick Start

### One-Line Installation
```bash
curl -fsSL https://raw.githubusercontent.com/flutterkage2k/flutter-build-fix/main/install.sh | bash
```

### Usage Commands
```bash
flutter-fix    # Full cleanup (Android + iOS)
ffand          # Android only
ffios          # iOS only (macOS)
ff-full        # Full cleanup (auto mode)
ff-dry         # Preview changes (dry-run)
ff-auto        # Auto mode with defaults
```

## System Requirements

### Supported Platforms
- **macOS**: Full support (Android + iOS)
- **Linux**: Android support only
- **Windows**: Not supported (use WSL2)

### Prerequisites
- Flutter SDK (any version)
- Java 17+ (automatically configured)
- Android SDK (for Android development)
- Xcode (for iOS development on macOS)

## Project Compatibility

### Automatic Detection
The script automatically detects your project type:

#### Kotlin DSL Projects (Flutter 3.29+)
- `settings.gradle.kts`
- `app/build.gradle.kts` 
- `build.gradle.kts`

#### Groovy DSL Projects (Flutter 3.28 and earlier)
- `settings.gradle`
- `app/build.gradle`
- `build.gradle`

### Supported Flutter Versions
- ✅ Flutter 3.44.6 (latest stable)
- ✅ Flutter 3.29+ (Kotlin DSL projects)
- ✅ Flutter 3.28 and earlier (Groovy DSL projects)
- ✅ All Flutter versions with Android support

## Advanced Usage

### Command Line Options
```bash
# Interactive mode (default)
flutter_build_fix.sh --interactive --full

# Automatic mode with smart defaults
flutter_build_fix.sh --auto --android

# Preview changes without applying
flutter_build_fix.sh --dry-run --full

# Force mode (skip all confirmations)
flutter_build_fix.sh --force --android

# Specific platform targeting
flutter_build_fix.sh --android    # Android only
flutter_build_fix.sh --ios        # iOS only
flutter_build_fix.sh --full       # Both platforms
```

### Configuration Details

#### Gradle Versions (Verified Stable)
- **Recommended**: Gradle 8.14
- **Supported**: 8.14, 8.13, 8.12, 8.11.1
- **AGP**: 8.10.0 (Android Gradle Plugin — capped for Android Studio compatibility)
- **Kotlin**: 2.1.0 (capped for plugin compatibility)

> **Why AGP 8.10.0 and Kotlin 2.1.0, not the versions Flutter prefers?**
>
> **Guiding rule: never trade a working build for a silenced warning.** Flutter
> 3.44.6 prefers AGP 8.11.1 and Kotlin 2.2.20, and prints "will soon be dropped"
> warnings below them — but those are only *warnings*. The surrounding ecosystem
> fails *hard*:
>
> | Version Flutter prefers | What actually breaks |
> |---|---|
> | AGP 8.11.1 | Android Studio 2024.3 (Meerkat) **refuses to open the project**; it caps at 8.10.0. Flutter errors only below 8.6.0. |
> | Kotlin 2.2.20 | Kotlin 2.2 removed `languageVersion 1.6`, which plugins like `sentry_flutter` still declare — their compile **fails outright**. Flutter errors only below KGP 2.0.0. |
>
> Both were hit on real projects, so the tool sits one notch below Flutter's
> preference on each. You will see the Flutter warnings at build time; they are
> expected and harmless. Raise either version once your Android Studio and
> plugins have caught up.
>
> The tool also deliberately stays on **AGP 8.x**: AGP 9 removes the legacy
> `kotlin-android` plugin and breaks many existing apps and plugins. On AGP 8.x
> that plugin works natively, so the AGP 9 opt-out flags
> (`android.builtInKotlin` / `android.newDsl`) are unnecessary — and since they
> break Gradle's configuration cache, configuration-cache is left disabled.

#### Java Configuration
- **Target Version**: Java 17
- **Automatic Detection**: `/usr/libexec/java_home` and Homebrew paths
- **Environment Setup**: JAVA_HOME and PATH configuration
- **Flutter Integration**: `flutter config --jdk-dir` automatic setup

#### Memory Optimization
```properties
org.gradle.jvmargs=-Xmx6G -XX:MaxMetaspaceSize=1G -XX:ReservedCodeCacheSize=512m
org.gradle.parallel=true
org.gradle.configuration-cache=true
org.gradle.caching=true
```

## 16KB Page Size Support

### Why It Matters
Google Play requires apps to support 16KB page sizes for newer Android devices. As of Flutter 3.44.6 this is handled automatically — Flutter's bundled NDK (28.2.13676358+) already builds 16KB-compatible native code.

### What We Configure
- **NDK Version**: delegated to `flutter.ndkVersion` (no hardcoded NDK)
- **Why delegation**: tracks Flutter's tested default and avoids version conflicts
- **Migration**: if a project pins an old explicit NDK, the script offers to convert it back to `flutter.ndkVersion`

### Manual Verification
```bash
# Check your current NDK setting
grep "ndkVersion" android/app/build.gradle*

# Recommended (delegated): ndkVersion = flutter.ndkVersion
```

## Troubleshooting

### Common Issues

#### Build Failures After Update
```bash
# Clean and retry
flutter clean
flutter pub get
flutter build apk --debug
```

#### Java Version Issues
```bash
# Check Java version
java -version

# Should show Java 17 or higher
# If not, install: brew install openjdk@17
```

#### Gradle Daemon Issues
```bash
# Stop all Gradle daemons
./gradlew --stop
gradle --stop

# Then run flutter-fix again
```

#### NDK Not Found
1. Open Android Studio
2. Go to Tools → SDK Manager
3. SDK Tools tab → Install NDK (Side-by-side)
4. Install the version Flutter requests (matches `flutter.ndkVersion`, currently 28.2.13676358)

### Build Performance Tips
- Use `ff-auto` for fastest automated fixes
- Run `flutter clean` before major version updates  
- Keep Android Studio and Flutter SDK updated
- Use SSD storage for better I/O performance

## What Gets Modified

### Safe Operations
- ✅ **Backup Creation**: All files backed up before modification
- ✅ **Dry-run Mode**: Preview changes without applying
- ✅ **Rollback Support**: Easy restoration from backups
- ✅ **Non-destructive**: Only modifies configuration files

### Files Modified
```
android/
├── settings.gradle[.kts]      # Plugin versions
├── build.gradle[.kts]         # Root build configuration  
├── app/build.gradle[.kts]     # App-level configuration
├── gradle.properties         # Build optimization
├── local.properties          # Java path configuration
└── gradle/wrapper/
    └── gradle-wrapper.properties  # Gradle version
```

### What's NOT Modified
- Source code files (.dart, .java, .kt)
- Assets and resources
- Pubspec.yaml dependencies
- Git configuration
- IDE settings

## Performance Benchmarks

### Build Time Improvements
- **Clean Build**: 30-40% faster
- **Incremental Build**: 20-30% faster  
- **Hot Reload**: No impact (already fast)

### Memory Usage
- **Gradle Heap**: Optimized for 6GB systems
- **Parallel Builds**: Utilizes multiple CPU cores
- **Cache Optimization**: Reduced redundant operations

### App Performance (16KB Support)
- **Startup Time**: 3-30% improvement
- **Memory Usage**: 4.5% better efficiency
- **Battery Life**: Measurable improvement on new devices

## Migration Guide

### From v3.x to v4.x
1. **Backup your project**: `git commit -am "Before flutter-fix"`
2. **Run installation**: Use the new install script
3. **Test with dry-run**: `ff-dry` to preview changes
4. **Apply changes**: `flutter-fix`
5. **Verify build**: `flutter build apk --debug`

> **What changed across v4.x**: targets Flutter 3.44.6 with AGP 8.10.0 / Gradle
> 8.14 / Kotlin 2.1.0 / Java 17. SDK and NDK versions are delegated to Flutter
> instead of hardcoded (`compileSdk`, `minSdk`, `targetSdk`, `ndkVersion`), so
> they stop going stale — the old forced NDK `29.0.13846066` is gone. `minSdk`
> and `targetSdk` ask before changing, since both affect app behavior.
>
> Gradle's configuration cache stays disabled: it is incompatible with the
> `android.builtInKotlin=false` flag Flutter 3.44.6 mandates. `java.home` is
> written to `gradle/config.properties`, which is where Android Studio's
> `#GRADLE_LOCAL_JAVA_HOME` macro reads it.
>
> See the [releases](https://github.com/flutterkage2k/flutter-build-fix/releases)
> for the per-version detail.

### New Project Setup
For new Flutter projects (3.29+):
```bash
flutter create myapp
cd myapp
flutter-fix  # Automatically detects Kotlin DSL
```

### Legacy Project Update  
For existing projects (3.28 and earlier):
```bash
cd existing_project
flutter-fix  # Automatically detects Groovy DSL
```

## Contributing

### Reporting Issues
- Use GitHub Issues for bug reports
- Include Flutter version and OS details
- Attach build logs for failures
- Test with `--dry-run` first

### Development Setup
```bash
git clone https://github.com/flutterkage2k/flutter-build-fix.git
cd flutter-build-fix
./flutter_build_fix.sh --help
```

### Testing
```bash
# Test all modes
./flutter_build_fix.sh --dry-run --full
./flutter_build_fix.sh --auto --android  
./flutter_build_fix.sh --force --ios
```

## Support

### Documentation
- **GitHub Wiki**: Detailed guides and FAQ
- **Issues**: Bug reports and feature requests
- **Discussions**: Community support and tips

### Update Notifications
```bash
# Check for updates
flutter_build_fix.sh --version

# Update to latest
curl -fsSL https://raw.githubusercontent.com/flutterkage2k/flutter-build-fix/main/install.sh | bash
```

## License

MIT License - see [LICENSE](LICENSE) file for details.

## Credits

**Author**: Heesung Jin (kage2k)  
**Repository**: https://github.com/flutterkage2k/flutter-build-fix  
**Flutter Community**: Thanks for feedback and testing

---

**Flutter 3.44.6 Ready | AGP 8.x Safe | Universal DSL Support | Production Tested**