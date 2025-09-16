# Flutter Build Fix v3.3.0 - Universal DSL Support

[![Flutter](https://img.shields.io/badge/Flutter-3.35.3-blue.svg)](https://flutter.dev)
[![Platform](https://img.shields.io/badge/Platform-macOS%20|%20Linux-lightgrey.svg)](https://github.com/flutterkage2k/flutter-build-fix)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

**The most comprehensive Flutter build environment fix script with universal Kotlin DSL and Groovy DSL support.**

co

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
- ✅ Flutter 3.35.3 (latest stable)
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
- **Recommended**: Gradle 8.12
- **Supported**: 8.12, 8.11.1, 8.10, 8.9
- **AGP**: 8.7.3 (Android Gradle Plugin)
- **Kotlin**: 2.1.0

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
Starting November 1, 2025, Google Play requires apps to support 16KB page sizes for improved performance on newer Android devices.

### What We Configure
- **NDK Version**: 29.0.13846066 (minimum required)
- **Performance Gains**: 3-30% faster startup, 4.5% better battery
- **Compatibility**: Maintains backward compatibility with existing devices

### Manual Verification
```bash
# Check your current NDK version
grep "ndkVersion" android/app/build.gradle*

# Should show: ndkVersion = "29.0.13846066" or higher
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
4. Select version 29.0.13846066 or higher

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

### From v2.x to v3.3.0
1. **Backup your project**: `git commit -am "Before flutter-fix v3.3.0"`
2. **Run installation**: Use the new install script
3. **Test with dry-run**: `ff-dry` to preview changes
4. **Apply changes**: `flutter-fix`
5. **Verify build**: `flutter build apk --debug`

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

**Ready for Google Play 2025 | Universal DSL Support | Production Tested**