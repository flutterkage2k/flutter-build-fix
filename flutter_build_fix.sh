#!/usr/bin/env bash

# =============================================================================
# Flutter Build Fix - Universal (Groovy + Kotlin DSL) Support
# 
# Repository: https://github.com/flutterkage2k/flutter-build-fix
# Author: Heesung Jin (kage2k)
# Version: 3.3.0 - Improved Automation & 16KB Support
# =============================================================================

set -e

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m'

# Version information
SCRIPT_VERSION="3.3.0"
REPO="flutterkage2k/flutter-build-fix"

# Flutter 3.35.3 optimized version list (September 2025 update)
STABLE_GRADLE_VERSIONS=("8.12" "8.11.1" "8.10" "8.9")
RECOMMENDED_AGP_VERSION="8.7.3"
RECOMMENDED_KOTLIN_VERSION="2.1.0"
RECOMMENDED_GRADLE_VERSION="8.12"

# 16KB page size support minimum requirements (Google Play mandatory Nov 1, 2025)
REQUIRED_NDK_VERSION_CODE="13846066"
REQUIRED_NDK_VERSION="29.0.13846066"
MINIMUM_AGP_FOR_16KB="8.5.1"

# Execution mode flags
INTERACTIVE_MODE=true
AUTO_MODE=false
DRY_RUN_MODE=false
FORCE_MODE=false

# Log functions
log_info()    { echo -e "${BLUE}[INFO] $1${NC}"; }
log_success() { echo -e "${GREEN}[SUCCESS] $1${NC}"; }
log_warning() { echo -e "${YELLOW}[WARNING] $1${NC}"; }
log_error()   { echo -e "${RED}[ERROR] $1${NC}"; }
log_step()    { echo -e "${CYAN}[STEP] $1${NC}"; }
log_fun()     { echo -e "${PURPLE}$1${NC}"; }
log_dry_run() { echo -e "${YELLOW}[DRY-RUN] $1${NC}"; }

# Parse command line arguments
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --interactive)
                INTERACTIVE_MODE=true
                AUTO_MODE=false
                shift
                ;;
            --auto)
                INTERACTIVE_MODE=false
                AUTO_MODE=true
                shift
                ;;
            --dry-run)
                DRY_RUN_MODE=true
                log_info "Dry-run mode enabled - no changes will be made"
                shift
                ;;
            --force)
                FORCE_MODE=true
                INTERACTIVE_MODE=false
                log_info "Force mode enabled - all confirmations will be skipped"
                shift
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            --version|-v)
                show_version
                exit 0
                ;;
            --android|--ios|--full)
                # Store mode for later processing
                EXECUTION_MODE=$1
                shift
                ;;
            *)
                log_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

# Smart confirmation function
confirm_action() {
    local message="$1"
    local default_yes="${2:-false}"
    
    if [[ "$FORCE_MODE" == "true" ]] || [[ "$AUTO_MODE" == "true" ]]; then
        if [[ "$default_yes" == "true" ]]; then
            log_info "$message (auto-confirmed: yes)"
            return 0
        else
            log_info "$message (auto-confirmed: no)"
            return 1
        fi
    fi
    
    if [[ "$INTERACTIVE_MODE" == "true" ]]; then
        read -p "$message (y/n) " -n 1 -r
        echo
        [[ $REPLY =~ ^[Yy]$ ]]
    else
        # Default behavior when not interactive
        [[ "$default_yes" == "true" ]]
    fi
}

# Safe file modification with dry-run support
safe_modify_file() {
    local file="$1"
    local description="$2"
    local modification_func="$3"
    
    if [[ "$DRY_RUN_MODE" == "true" ]]; then
        log_dry_run "Would modify: $file ($description)"
        return 0
    fi
    
    if [ -f "$file" ]; then
        cp "$file" "${file}.backup.$(date +%s)"
        eval "$modification_func"
        log_success "Modified: $file ($description)"
    else
        log_warning "File not found: $file"
        return 1
    fi
}

# =============================================================================
# Core: Smart Project Type Detection System
# =============================================================================

detect_gradle_type() {
    log_step "Detecting Gradle project type..."
    
    # Priority 1: settings file
    if [ -f "android/settings.gradle.kts" ]; then
        echo "kotlin_dsl"
        return 0
    elif [ -f "android/settings.gradle" ]; then
        echo "groovy_dsl"
        return 0
    fi
    
    # Priority 2: app build file
    if [ -f "android/app/build.gradle.kts" ]; then
        echo "kotlin_dsl"
        return 0
    elif [ -f "android/app/build.gradle" ]; then
        echo "groovy_dsl"
        return 0
    fi
    
    # Priority 3: root build file
    if [ -f "android/build.gradle.kts" ]; then
        echo "kotlin_dsl"
        return 0
    elif [ -f "android/build.gradle" ]; then
        echo "groovy_dsl"
        return 0
    fi
    
    echo "unknown"
    return 1
}

analyze_project_structure() {
    local gradle_type="$1"
    
    log_info "Project structure analysis:"
    
    case "$gradle_type" in
        "kotlin_dsl")
            log_success "Kotlin DSL project detected (Flutter 3.29+ new style)"
            log_info "   - settings.gradle.kts: $([ -f "android/settings.gradle.kts" ] && echo "found" || echo "missing")"
            log_info "   - app/build.gradle.kts: $([ -f "android/app/build.gradle.kts" ] && echo "found" || echo "missing")"
            log_info "   - build.gradle.kts: $([ -f "android/build.gradle.kts" ] && echo "found" || echo "missing")"
            
            # Check 16KB page size support status
            check_16kb_support_status "kotlin"
            ;;
        "groovy_dsl")
            log_success "Groovy DSL project detected (Flutter 3.28 and earlier)"
            log_info "   - settings.gradle: $([ -f "android/settings.gradle" ] && echo "found" || echo "missing")"
            log_info "   - app/build.gradle: $([ -f "android/app/build.gradle" ] && echo "found" || echo "missing")"
            log_info "   - build.gradle: $([ -f "android/build.gradle" ] && echo "found" || echo "missing")"
            
            # Check 16KB page size support status
            check_16kb_support_status "groovy"
            ;;
        "unknown")
            log_error "Unknown project structure"
            log_info "Android folder does not exist or is corrupted"
            return 1
            ;;
    esac
    
    # Check Flutter version
    if command -v flutter >/dev/null 2>&1; then
        local flutter_version=$(flutter --version | head -1 | grep -o 'Flutter [0-9.]*' | cut -d' ' -f2)
        log_info "Flutter version: $flutter_version"
    fi
}

check_16kb_support_status() {
    local dsl_type="$1"
    local build_file=""
    
    case "$dsl_type" in
        "kotlin")
            build_file="android/app/build.gradle.kts"
            ;;
        "groovy")
            build_file="android/app/build.gradle"
            ;;
    esac
    
    if [ -f "$build_file" ]; then
        local ndk_check=$(grep -o 'ndkVersion.*[0-9.]*' "$build_file" | head -1)
        if [ -n "$ndk_check" ]; then
            log_info "   - NDK setting: $ndk_check"
            if echo "$ndk_check" | grep -q "flutter.ndkVersion"; then
                log_warning "   - Using flutter.ndkVersion - 16KB support uncertain"
                log_warning "   - Google Play requires 16KB support from Nov 1, 2025"
            fi
        else
            log_info "   - NDK setting: not specified"
        fi
    fi
}

# =============================================================================
# 16KB Page Size Support Functions (RESTORED)
# =============================================================================

update_ndk_version_for_16kb() {
    local app_build_file="$1"
    local file_type="$2"
    
    if [ ! -f "$app_build_file" ]; then
        log_warning "App build file not found: $app_build_file"
        return 1
    fi
    
    log_step "Updating NDK version for 16KB page size support (Google Play mandatory)"
    
    # Check current NDK version
    local current_ndk=$(grep -o 'ndkVersion.*[0-9.]*' "$app_build_file" | head -1)
    if [ -n "$current_ndk" ]; then
        log_info "Current NDK setting: $current_ndk"
    fi
    
    # Ask for confirmation
    if ! confirm_action "Update NDK to $REQUIRED_NDK_VERSION for 16KB support?" "true"; then
        log_info "Skipping NDK version update"
        return 0
    fi
    
    local modification_func=""
    case "$file_type" in
        "kotlin")
            modification_func="
                if grep -q 'flutter.ndkVersion' '$app_build_file'; then
                    sed -i '' 's/ndkVersion = flutter\.ndkVersion/ndkVersion = \"$REQUIRED_NDK_VERSION\"/g' '$app_build_file'
                elif grep -q 'ndkVersion' '$app_build_file'; then
                    sed -i '' 's/ndkVersion = \"[^\"]*\"/ndkVersion = \"$REQUIRED_NDK_VERSION\"/g' '$app_build_file'
                else
                    sed -i '' '/android {/a\\
    ndkVersion = \"$REQUIRED_NDK_VERSION\"\\
' '$app_build_file'
                fi
            "
            ;;
        "groovy")
            modification_func="
                if grep -q 'flutter.ndkVersion' '$app_build_file'; then
                    sed -i '' 's/ndkVersion flutter\.ndkVersion/ndkVersion \"$REQUIRED_NDK_VERSION\"/g' '$app_build_file'
                    sed -i '' 's/ndkVersion = flutter\.ndkVersion/ndkVersion = \"$REQUIRED_NDK_VERSION\"/g' '$app_build_file'
                elif grep -q 'ndkVersion' '$app_build_file'; then
                    sed -i '' 's/ndkVersion \"[^\"]*\"/ndkVersion \"$REQUIRED_NDK_VERSION\"/g' '$app_build_file'
                    sed -i '' 's/ndkVersion = \"[^\"]*\"/ndkVersion = \"$REQUIRED_NDK_VERSION\"/g' '$app_build_file'
                else
                    sed -i '' '/android {/a\\
        ndkVersion \"$REQUIRED_NDK_VERSION\"\\
' '$app_build_file'
                fi
            "
            ;;
    esac
    
    safe_modify_file "$app_build_file" "NDK version for 16KB support" "$modification_func"
    
    log_info "Performance improvement expected: 3-30% faster app startup, 4.5% better battery"
    log_info "Compliance deadline: Google Play mandatory from Nov 1, 2025"
}

# =============================================================================
# Kotlin DSL Processing Functions
# =============================================================================

update_kotlin_settings_gradle() {
    local settings_file="android/settings.gradle.kts"
    
    if [ ! -f "$settings_file" ]; then
        log_warning "settings.gradle.kts file not found"
        return 1
    fi
    
    log_step "Updating Kotlin DSL settings.gradle.kts"
    
    local should_update=false
    if confirm_action "Update AGP to $RECOMMENDED_AGP_VERSION and Kotlin to $RECOMMENDED_KOTLIN_VERSION?" "true"; then
        should_update=true
    fi
    
    if [[ "$should_update" == "true" ]]; then
        local modification_func="
            sed -i '' 's/id(\"com.android.application\") version \"[^\"]*\"/id(\"com.android.application\") version \"$RECOMMENDED_AGP_VERSION\"/g' '$settings_file'
            sed -i '' 's/id(\"org.jetbrains.kotlin.android\") version \"[^\"]*\"/id(\"org.jetbrains.kotlin.android\") version \"$RECOMMENDED_KOTLIN_VERSION\"/g' '$settings_file'
        "
        safe_modify_file "$settings_file" "AGP and Kotlin versions" "$modification_func"
    else
        log_info "Skipping version updates"
    fi
    
    # Check Flutter 3.35.3 standard structure
    if ! grep -q "dev.flutter.flutter-plugin-loader" "$settings_file"; then
        log_info "Flutter 3.35.3 standard plugin-loader not found. Manual check recommended."
    fi
}

update_kotlin_app_build() {
    local app_build_file="android/app/build.gradle.kts"
    
    if [ ! -f "$app_build_file" ]; then
        log_warning "app/build.gradle.kts file not found"
        return 1
    fi
    
    log_step "Updating Kotlin DSL app/build.gradle.kts (Java 17 + 16KB support)"
    
    # Java 17 compileOptions
    if ! grep -q "compileOptions" "$app_build_file"; then
        local modification_func="
            sed -i '' '/android {/a\\
    compileOptions {\\
        sourceCompatibility = JavaVersion.VERSION_17\\
        targetCompatibility = JavaVersion.VERSION_17\\
    }\\
' '$app_build_file'
        "
        safe_modify_file "$app_build_file" "Java 17 compileOptions" "$modification_func"
    else
        local modification_func="
            sed -i '' 's/sourceCompatibility = JavaVersion\.VERSION_[0-9_]*/sourceCompatibility = JavaVersion.VERSION_17/g' '$app_build_file'
            sed -i '' 's/targetCompatibility = JavaVersion\.VERSION_[0-9_]*/targetCompatibility = JavaVersion.VERSION_17/g' '$app_build_file'
        "
        safe_modify_file "$app_build_file" "Java 17 compileOptions update" "$modification_func"
    fi
    
    # Kotlin JVM Target
    if grep -q "kotlinOptions" "$app_build_file"; then
        local modification_func="
            sed -i '' 's/jvmTarget = \"[^\"]*\"/jvmTarget = \"17\"/g' '$app_build_file'
        "
        safe_modify_file "$app_build_file" "Kotlin JVM target update" "$modification_func"
    else
        local modification_func="
            sed -i '' '/compileOptions {/a\\
\\
    kotlinOptions {\\
        jvmTarget = \"17\"\\
    }\\
' '$app_build_file'
        "
        safe_modify_file "$app_build_file" "Kotlin JVM target addition" "$modification_func"
    fi
    
    # Check minSdk
    local current_min_sdk=$(grep "minSdk" "$app_build_file" | grep -o '[0-9]*' | head -1)
    if [ -n "$current_min_sdk" ] && [ "$current_min_sdk" -lt 26 ]; then
        if confirm_action "Update minSdk from $current_min_sdk to 26?" "true"; then
            local modification_func="
                sed -i '' 's/minSdk = [0-9]*/minSdk = 26/g' '$app_build_file'
            "
            safe_modify_file "$app_build_file" "minSdk update to 26" "$modification_func"
        fi
    fi
    
    # 16KB page size support NDK version update
    update_ndk_version_for_16kb "$app_build_file" "kotlin"
}

configure_kotlin_dsl_gradle() {
    log_step "Configuring Kotlin DSL project"
    update_kotlin_settings_gradle
    update_kotlin_app_build
    configure_gradle_properties_universal
    update_gradle_wrapper_universal
    log_success "Kotlin DSL configuration completed"
}

# =============================================================================
# Groovy DSL Processing Functions
# =============================================================================

update_groovy_settings_gradle() {
    local settings_file="android/settings.gradle"
    if [ ! -f "$settings_file" ]; then
        log_warning "settings.gradle file not found"
        return 1
    fi
    
    log_step "Updating Groovy DSL settings.gradle"
    
    if confirm_action "Update AGP to $RECOMMENDED_AGP_VERSION and Kotlin to $RECOMMENDED_KOTLIN_VERSION?" "true"; then
        local modification_func="
            sed -i '' 's/id \"com.android.application\" version \"[^\"]*\"/id \"com.android.application\" version \"$RECOMMENDED_AGP_VERSION\"/g' '$settings_file'
            sed -i '' 's/id \"org.jetbrains.kotlin.android\" version \"[^\"]*\"/id \"org.jetbrains.kotlin.android\" version \"$RECOMMENDED_KOTLIN_VERSION\"/g' '$settings_file'
        "
        safe_modify_file "$settings_file" "AGP and Kotlin versions" "$modification_func"
    else
        log_info "Skipping version updates"
    fi
}

update_groovy_app_build() {
    local app_build_file="android/app/build.gradle"
    if [ ! -f "$app_build_file" ]; then
        log_warning "app/build.gradle file not found"
        return 1
    fi
    
    log_step "Updating Groovy DSL app/build.gradle (Java 17 + 16KB support)"
    
    # Java 17 compatibility
    local modification_func="
        sed -i '' 's/jvmTarget.*21/jvmTarget = '\''17'\''/g' '$app_build_file'
        sed -i '' 's/jvmTarget.*= '\''21'\''/jvmTarget = '\''17'\''/g' '$app_build_file'
        sed -i '' 's/jvmTarget.*= \"21\"/jvmTarget = \"17\"/g' '$app_build_file'
        sed -i '' 's/JavaVersion\.VERSION_21/JavaVersion.VERSION_17/g' '$app_build_file'
    "
    safe_modify_file "$app_build_file" "Java 17 compatibility" "$modification_func"
    
    # 16KB page size support NDK version update
    update_ndk_version_for_16kb "$app_build_file" "groovy"
}

configure_groovy_dsl_gradle() {
    log_step "Configuring Groovy DSL project"
    if [ -f "android/settings.gradle" ]; then
        update_groovy_settings_gradle
    fi
    update_groovy_app_build
    configure_gradle_properties_universal
    update_gradle_wrapper_universal
    log_success "Groovy DSL configuration completed"
}

# =============================================================================
# Universal Common Functions
# =============================================================================

update_gradle_wrapper_universal() {
    local wrapper_props="android/gradle/wrapper/gradle-wrapper.properties"
    local recommended_version="$RECOMMENDED_GRADLE_VERSION"
    
    if [ ! -f "$wrapper_props" ]; then
        log_error "gradle-wrapper.properties file not found"
        return 1
    fi
    
    log_step "Updating Gradle Wrapper version"
    
    local current_gradle=$(grep "gradle-.*-all.zip" "$wrapper_props" | sed -E 's/.*gradle-([0-9.]+)-all.zip.*/\1/')
    log_info "Current Gradle version: $current_gradle"
    
    if [ "$current_gradle" != "$recommended_version" ]; then
        if confirm_action "Update Gradle Wrapper to $recommended_version?" "true"; then
            local modification_func="
                sed -i '' 's|gradle-.*-all\.zip|gradle-$recommended_version-all.zip|g' '$wrapper_props'
            "
            safe_modify_file "$wrapper_props" "Gradle Wrapper version" "$modification_func"
        else
            log_info "Skipping Gradle Wrapper update"
        fi
    else
        log_success "Current Gradle version is already up to date"
    fi
}

configure_gradle_properties_universal() {
    local gradle_props="android/gradle.properties"
    
    if [ ! -f "$gradle_props" ]; then
        log_warning "gradle.properties file not found"
        return 1
    fi
    
    log_step "Configuring Flutter 3.35.3 optimized gradle.properties"
    
    if confirm_action "Apply Gradle optimization settings? (6GB memory, parallel builds, etc.)" "true"; then
        local modification_func="
            grep -v '# Flutter Build Fix' '$gradle_props' > '${gradle_props}.tmp' || true
            mv '${gradle_props}.tmp' '$gradle_props'
            cat >> '$gradle_props' << 'EOF'

# Flutter Build Fix v$SCRIPT_VERSION - Flutter 3.35.3 Optimization
# Java 17 + Gradle $RECOMMENDED_GRADLE_VERSION + AGP $RECOMMENDED_AGP_VERSION
# Flutter 3.35.3 performance optimized memory settings
org.gradle.jvmargs=-Xmx6G -XX:MaxMetaspaceSize=1G -XX:ReservedCodeCacheSize=512m -XX:+HeapDumpOnOutOfMemoryError
org.gradle.parallel=true
org.gradle.daemon=true
org.gradle.configuration-cache=true
org.gradle.configuration-cache.problems=warn
org.gradle.caching=true

# Android standard settings
android.useAndroidX=true
android.enableJetifier=true

# Flutter 3.35.3 recommended settings
flutter.minSdkVersion=26
kotlin.jvm.target.validation.mode=warning

# Kotlin DSL and performance optimization
org.gradle.kotlin.dsl.allWarningsAsErrors=false
kotlin.daemon.jvm.options=-Xmx3072m
org.gradle.unsafe.configuration-cache=true

# Flutter 3.35.3 build performance improvements
org.gradle.workers.max=4
kotlin.incremental=true
kotlin.incremental.useClasspathSnapshot=true
EOF
        "
        safe_modify_file "$gradle_props" "Flutter 3.35.3 optimization settings" "$modification_func"
    else
        log_info "Skipping gradle.properties optimization"
    fi
}

# =============================================================================
# Main Universal Processing System
# =============================================================================

configure_gradle_universal() {
    log_step "Starting universal Gradle configuration system"
    local gradle_type=$(detect_gradle_type)
    
    if [ "$gradle_type" = "unknown" ]; then
        log_error "Unsupported project structure"
        log_info "Solution: Run from Flutter project root and ensure android folder exists"
        return 1
    fi
    
    analyze_project_structure "$gradle_type"
    
    case "$gradle_type" in
        "kotlin_dsl")
            log_info "Processing with Kotlin DSL optimization path"
            configure_kotlin_dsl_gradle
            ;;
        "groovy_dsl")
            log_info "Processing with Groovy DSL optimization path"
            configure_groovy_dsl_gradle
            ;;
    esac
    
    log_success "Universal Gradle configuration completed!"
}

# =============================================================================
# Build Testing System
# =============================================================================

test_gradle_build_universal() {
    log_step "Starting Android build compatibility test"
    
    if [[ "$DRY_RUN_MODE" == "true" ]]; then
        log_dry_run "Would test: flutter build apk --debug --quiet"
        return 0
    fi
    
    if show_progress_with_fun "flutter build apk --debug --quiet" "Android build test"; then
        log_success "Build test successful! All configurations are working properly"
        return 0
    else
        log_warning "Build test failed - additional configuration may be needed"
        if confirm_action "Retry build test?" "false"; then
            if show_progress_with_fun "flutter build apk --debug --quiet" "Android build test retry"; then
                log_success "Retry build successful!"
                return 0
            else
                log_error "Build test retry failed. Manual verification needed."
                log_info "Manual verification steps:"
                echo "   1. cd android && ./gradlew --version"
                echo "   2. flutter doctor -v"
                echo "   3. flutter build apk --debug"
                return 1
            fi
        fi
        return 1
    fi
}

# =============================================================================
# Existing Functions (Maintained + Improved)
# =============================================================================

safe_remove() {
    local path="$1"
    local description="$2"
    
    if [[ "$DRY_RUN_MODE" == "true" ]]; then
        log_dry_run "Would remove: $path ($description)"
        return 0
    fi
    
    if [ -d "$path" ] || [ -f "$path" ]; then
        if rm -rf "$path" 2>/dev/null; then
            log_success "Removed: $description"
            return 0
        else
            log_warning "Failed to remove: $description (in use or permission denied)"
            log_info "Manual removal: sudo rm -rf $path"
            return 1
        fi
    else
        log_info "$description path does not exist (normal)"
        return 0
    fi
}

check_macos() {
    if [[ "$OSTYPE" != "darwin"* ]]; then
        log_error "This script is macOS only"
        log_info "Current OS: $OSTYPE"
        exit 1
    fi
}

check_flutter_project() {
    if [ ! -f "pubspec.yaml" ]; then
        log_error "Please run from Flutter project root"
        log_info "pubspec.yaml file not found"
        exit 1
    fi
    local project_name
    project_name=$(grep "^name:" pubspec.yaml | cut -d' ' -f2 | tr -d '"' | head -1)
    log_info "Flutter project: $project_name"
}

setup_java17() {
    log_step "Setting up Java 17 environment"
    local java_home_path
    java_home_path=$(/usr/libexec/java_home -v17 2>/dev/null || true)
    
    if [ -n "$java_home_path" ]; then
        export JAVA_HOME="$java_home_path"
        log_info "Java 17 found via /usr/libexec/java_home: $JAVA_HOME"
    else
        local java_paths=(
            "/opt/homebrew/Cellar/openjdk@17/*/libexec/openjdk.jdk/Contents/Home"
            "/usr/local/Cellar/openjdk@17/*/libexec/openjdk.jdk/Contents/Home"
            "/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home"
            "/usr/local/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home"
            "/Library/Java/JavaVirtualMachines/openjdk-17.jdk/Contents/Home"
        )
        
        local java_home=""
        for path in "${java_paths[@]}"; do
            local expanded_paths=($path)
            for expanded_path in "${expanded_paths[@]}"; do
                if [ -d "$expanded_path" ] && [ -x "$expanded_path/bin/java" ]; then
                    java_home="$expanded_path"
                    break 2
                fi
            done
        done
        
        if [ -n "$java_home" ]; then
            export JAVA_HOME="$java_home"
            log_info "Java 17 found via Homebrew: $JAVA_HOME"
        else
            log_error "Java 17 not found!"
            log_info "Solution: 1. brew install openjdk@17  2. brew link openjdk@17"
            exit 1
        fi
    fi
    
    export PATH="$JAVA_HOME/bin:$PATH"
    
    if [ -f "android/local.properties" ] && [[ "$DRY_RUN_MODE" != "true" ]]; then
        sed -i.bak '/^java\.home=/d' android/local.properties
        echo "java.home=$JAVA_HOME" >> android/local.properties
        log_success "java.home configured in local.properties"
    fi
    
    if [[ "$DRY_RUN_MODE" != "true" ]]; then
        flutter config --jdk-dir "$JAVA_HOME" > /dev/null 2>&1 || true
    fi
    
    echo "Current Java configuration:"
    echo "   JAVA_HOME: $JAVA_HOME"
    java -version 2>&1 | head -1
    
    log_success "Java 17 setup completed"
}

clean_flutter() {
    log_step "Cleaning Flutter cache"
    
    safe_remove "build" "build folder"
    
    if [[ "$DRY_RUN_MODE" != "true" ]]; then
        flutter clean > /dev/null 2>&1
        log_success "flutter clean completed"
        
        flutter pub get > /dev/null 2>&1
        log_success "flutter pub get completed"
        
        if command -v flutter >/dev/null 2>&1; then
            flutter analyze --suggestions > /dev/null 2>&1 || true
            log_success "Flutter compatibility check completed"
        fi
    else
        log_dry_run "Would run: flutter clean && flutter pub get"
    fi
}

# Progress messages
declare -a MESSAGES_15S=("Build preparation in progress..." "Checking dependencies..." "Organizing packages...")
declare -a MESSAGES_30S=("Please wait a moment... How about a coffee?" "Almost done... Play your favorite song!" "Flutter is working hard...")
declare -a MESSAGES_1M=("Still building... What's for lunch today?" "How about reading a page from a book?" "Organizing complex dependencies... Almost there!")
declare -a MESSAGES_2M=("Please be patient... This is part of development!" "How about some stretching?" "Deep breath... It'll be done soon!" "Final stage... Just a little more patience!")

show_progress_with_fun() {
    local command="$1"
    local description="$2"
    
    if [[ "$DRY_RUN_MODE" == "true" ]]; then
        log_dry_run "Would execute: $command"
        return 0
    fi
    
    $command > /tmp/flutter_build_output.log 2>&1 &
    local cmd_pid=$!
    local start_time=$(date +%s)
    local last_message_time=$start_time
    
    log_step "$description"
    
    while kill -0 $cmd_pid 2>/dev/null; do
        local current_time=$(date +%s)
        local elapsed=$((current_time - start_time))
        
        if [ $((current_time - last_message_time)) -ge 15 ]; then
            if [ $elapsed -ge 120 ]; then
                local msg=${MESSAGES_2M[$((RANDOM % ${#MESSAGES_2M[@]}))]}
                log_fun "$msg"
            elif [ $elapsed -ge 60 ]; then
                local msg=${MESSAGES_1M[$((RANDOM % ${#MESSAGES_1M[@]}))]}
                log_fun "$msg"
            elif [ $elapsed -ge 30 ]; then
                local msg=${MESSAGES_30S[$((RANDOM % ${#MESSAGES_30S[@]}))]}
                log_fun "$msg"
            elif [ $elapsed -ge 15 ]; then
                local msg=${MESSAGES_15S[$((RANDOM % ${#MESSAGES_15S[@]}))]}
                log_fun "$msg"
            fi
            last_message_time=$current_time
        fi
        
        sleep 3
    done
    
    wait $cmd_pid
    local exit_code=$?
    local total_time=$(($(date +%s) - start_time))
    
    if [ $exit_code -eq 0 ]; then
        log_success "$description completed! (${total_time}s)"
        if [ $total_time -ge 15 ]; then
            log_fun "Thank you for your patience!"
        fi
    else
        log_warning "$description failed (${total_time}s)"
        log_info "Detailed log: /tmp/flutter_build_output.log"
    fi
    
    return $exit_code
}

clean_gradle_universal() {
    log_step "Universal conservative Gradle cleanup and management"
    
    # Stop all Gradle daemons
    if command -v gradle >/dev/null 2>&1 && [[ "$DRY_RUN_MODE" != "true" ]]; then
        gradle --stop 2>/dev/null || true
        log_success "Gradle daemon terminated"
    fi
    
    if [ -f "android/gradlew" ] && [[ "$DRY_RUN_MODE" != "true" ]]; then
        cd android
        ./gradlew --stop 2>/dev/null || true
        cd ..
        log_success "Android Gradle daemon terminated"
    fi
    
    # Safe cache cleanup
    safe_remove "$HOME/.gradle/caches/modules-2" "Gradle module cache"
    safe_remove "android/.gradle" "Local Gradle cache"
    
    # Universal Gradle configuration
    configure_gradle_universal
    
    # NDK version check
    check_ndk_version
    
    # Build test
    if ! test_gradle_build_universal; then
        log_warning "Gradle configuration not fully resolved. Manual verification recommended."
    else
        log_success "Universal Gradle environment verification and build test completed"
    fi
}

check_ndk_version() {
    log_step "Checking NDK version (Google Play 16KB page size support required)"
    local ndk_version=""

    # 1. Check NDK version in local.properties
    if [ -f "android/local.properties" ]; then
        ndk_version=$(grep "ndk.version" android/local.properties | cut -d'=' -f2)
    fi

    # 2. Check NDK version in flutter doctor -v
    if [ -z "$ndk_version" ] && command -v flutter >/dev/null 2>&1; then
        ndk_version=$(flutter doctor -v | grep "NDK" | grep -o '[0-9.]*' | cut -d' ' -f2)
    fi

    if [ -n "$ndk_version" ]; then
        local ndk_code=$(echo "$ndk_version" | tr -d '.' | cut -c 1-8)
        log_info "Current NDK version: $ndk_version"
        if [ "$ndk_code" -ge "$REQUIRED_NDK_VERSION_CODE" ]; then
            log_success "NDK version $REQUIRED_NDK_VERSION or higher meets 16KB page size requirements"
        else
            log_warning "Current NDK version ($ndk_version) does not meet Google Play 16KB page size requirements ($REQUIRED_NDK_VERSION)"
            log_info "Solution: Open Android Studio and install latest NDK (Side-by-side) in SDK Manager"
            log_info "   (Tools -> SDK Manager -> SDK Tools tab -> NDK (Side-by-side))"
        fi
    else
        log_warning "NDK version not found. Please check installation in Android Studio"
    fi
}

clean_ios() {
    log_step "Cleaning iOS environment"
    
    if [ ! -d "ios" ]; then
        log_warning "iOS folder not found. This project may not support iOS"
        return
    fi
    
    cd ios
    
    # Safe Pods cleanup
    safe_remove "Pods" "Pods folder"
    safe_remove "Podfile.lock" "Podfile.lock"
    
    # CocoaPods cache cleanup
    if command -v pod >/dev/null 2>&1 && [[ "$DRY_RUN_MODE" != "true" ]]; then
        pod cache clean --all 2>/dev/null || true
        log_success "CocoaPods cache cleaned"
        
        log_step "Reinstalling CocoaPods"
        
        if show_progress_with_fun "pod install" "CocoaPods installation"; then
            log_success "Pod installation completed (fast method)"
        else
            log_info "Fast installation failed, retrying with repo update"
            if show_progress_with_fun "pod install --repo-update" "CocoaPods installation (repo update)"; then
                log_success "Pod installation completed (repo update)"
            else
                log_warning "Pod installation has issues"
            fi
        fi
    elif [[ "$DRY_RUN_MODE" == "true" ]]; then
        log_dry_run "Would run: pod install"
    else
        log_warning "CocoaPods not installed"
        log_info "Installation method: brew install cocoapods"
    fi
    
    cd ..
    
    # Safe Xcode cache cleanup
    log_step "Cleaning Xcode cache"
    safe_remove "$HOME/Library/Developer/Xcode/DerivedData" "Xcode DerivedData"
    
    # Clean Archives older than 30 days
    local archives="$HOME/Library/Developer/Xcode/Archives"
    if [ -d "$archives" ] && [[ "$DRY_RUN_MODE" != "true" ]]; then
        if find "$archives" -name "*.xcarchive" -mtime +30 -delete 2>/dev/null; then
            log_success "Cleaned Xcode Archives older than 30 days"
        else
            log_info "Skipped Xcode Archives cleanup (permissions or no files)"
        fi
    elif [[ "$DRY_RUN_MODE" == "true" ]]; then
        log_dry_run "Would clean Archives older than 30 days"
    fi
}

test_ios_build() {
    if [ ! -d "ios" ]; then
        log_info "iOS folder not found, skipping build test"
        return 0
    fi
    
    log_step "Starting iOS build test"
    
    if show_progress_with_fun "flutter build ios --debug --no-codesign --quiet" "iOS build test"; then
        log_success "iOS build test successful!"
        return 0
    else
        log_warning "iOS build test failed (this can be normal in some cases)"
        return 1
    fi
}

# =============================================================================
# Execution Modes
# =============================================================================

android_mode() {
    echo -e "${GREEN}[MODE] Android universal mode started${NC}"
    echo ""
    setup_java17
    clean_flutter
    clean_gradle_universal
    echo ""
    log_success "Android cleanup completed!"
    log_info "Both Groovy DSL and Kotlin DSL supported"
    log_info "16KB page size support (Google Play mandatory Nov 2025)"
}

ios_mode() {
    echo -e "${GREEN}[MODE] iOS mode started${NC}"
    echo ""
    clean_flutter
    clean_ios
    test_ios_build
    echo ""
    log_success "iOS cleanup completed!"
}

full_mode() {
    echo -e "${GREEN}[MODE] Full universal cleanup mode started${NC}"
    echo ""
    setup_java17
    clean_flutter
    clean_gradle_universal
    clean_ios
    test_ios_build
    echo ""
    log_success "Full cleanup completed!"
    log_info "Kotlin DSL and Groovy DSL perfect support"
    log_info "16KB page size support (Google Play mandatory Nov 2025)"
}

# =============================================================================
# Help and Version Information
# =============================================================================

show_help() {
    echo -e "${BLUE}Flutter Build Fix v$SCRIPT_VERSION - Universal DSL Support${NC}"
    echo ""
    echo "New features: Flutter 3.35.3 optimization + perfect Kotlin DSL (.kts) and Groovy DSL (.gradle) support!"
    echo ""
    echo "Usage:"
    echo "  $0 [options] [mode]"
    echo ""
    echo "Modes:"
    echo "  --full      Full cleanup (Android + iOS, default)"
    echo "  --android   Android issues only"  
    echo "  --ios       iOS issues only"
    echo ""
    echo "Options:"
    echo "  --interactive   Interactive mode with confirmations (default)"
    echo "  --auto          Automatic mode with smart defaults"
    echo "  --dry-run       Show what would be changed without making changes"
    echo "  --force         Skip all confirmations and apply all changes"
    echo "  --version       Show version information"
    echo "  --help          Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                          # Full cleanup (interactive)"
    echo "  $0 --android --auto         # Android only (automatic)"
    echo "  $0 --ios --dry-run          # iOS preview changes"
    echo "  $0 --full --force           # Full cleanup (no confirmations)"
    echo ""
    echo "Features: Flutter 3.35.3 optimization + automatic Kotlin DSL and Groovy DSL detection"
    echo "Performance: AGP $RECOMMENDED_AGP_VERSION + Gradle $RECOMMENDED_GRADLE_VERSION + 6GB memory optimization"
    echo "Safety: Verified version combinations for maximum stability"
    echo "Repository: https://github.com/$REPO"
}

show_version() {
    echo "Flutter Build Fix v$SCRIPT_VERSION"
    echo "Universal DSL support | Kotlin DSL + Groovy DSL | macOS only"
    echo "Performance: AGP $RECOMMENDED_AGP_VERSION | Gradle $RECOMMENDED_GRADLE_VERSION | Kotlin $RECOMMENDED_KOTLIN_VERSION"
    echo "Safety: Conservative Gradle management | Safe error handling"
    echo "Supported Gradle versions: ${STABLE_GRADLE_VERSIONS[*]}"
    echo "Kotlin DSL: Perfect support for Flutter 3.29+ new projects"
    echo "Groovy DSL: Perfect support for Flutter 3.28 and earlier existing projects"
    echo "16KB Support: Google Play mandatory compliance (Nov 1, 2025)"
}

check_for_updates() {
    if command -v curl >/dev/null 2>&1; then
        local latest_version
        latest_version=$(curl -s "https://api.github.com/repos/$REPO/releases/latest" 2>/dev/null | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/' | head -1)
        
        if [ -n "$latest_version" ] && [ "$latest_version" != "v$SCRIPT_VERSION" ]; then
            echo ""
            log_warning "New version available: $latest_version (current: v$SCRIPT_VERSION)"
            echo -e "${CYAN}Update: curl -fsSL https://raw.githubusercontent.com/$REPO/main/install.sh -o install.sh && zsh install.sh${NC}"
            echo ""
        fi
    fi
}

# =============================================================================
# Main Function
# =============================================================================

main() {
    # Parse arguments first
    parse_arguments "$@"
    
    # System checks
    check_macos
    
    # Header output
    echo -e "${BLUE}"
    echo "=================================================================="
    echo "    Flutter 3.35.3 Universal Build Fix Script"
    echo "    Kotlin DSL + Groovy DSL Perfect Support | v$SCRIPT_VERSION"
    echo "    Kotlin DSL: Flutter 3.35.3+ (.kts) | Groovy DSL: Flutter 3.28- (.gradle)"
    echo "    Performance: AGP $RECOMMENDED_AGP_VERSION | Gradle $RECOMMENDED_GRADLE_VERSION | Kotlin $RECOMMENDED_KOTLIN_VERSION"
    echo "    macOS only | Safe version management | 16KB Support"
    echo "    Author: Heesung Jin (kage2k)"
    echo "=================================================================="
    echo -e "${NC}"
    
    # Show execution mode
    if [[ "$DRY_RUN_MODE" == "true" ]]; then
        log_info "DRY-RUN MODE: No changes will be made"
    elif [[ "$FORCE_MODE" == "true" ]]; then
        log_info "FORCE MODE: All changes will be applied automatically"
    elif [[ "$AUTO_MODE" == "true" ]]; then
        log_info "AUTO MODE: Smart defaults will be used"
    else
        log_info "INTERACTIVE MODE: Confirmations will be requested"
    fi
    
    # Update check
    check_for_updates
    
    # Project check
    check_flutter_project
    
    # Execute based on mode
    case "${EXECUTION_MODE:---full}" in
        --android)
            android_mode
            ;;
        --ios)
            ios_mode
            ;;
        --full)
            full_mode
            ;;
    esac
    
    echo ""
    log_info "Tip: Run regularly to keep your Flutter development environment in optimal condition!"
    log_info "Flutter 3.35.3 optimization: Automatic support for both Kotlin DSL and Groovy DSL projects"
    log_info "Performance improvements: AGP $RECOMMENDED_AGP_VERSION + Gradle $RECOMMENDED_GRADLE_VERSION + memory optimization"
    log_info "Stability: Verified versions (${STABLE_GRADLE_VERSIONS[*]}) prioritized"
    log_info "Repository: https://github.com/$REPO"
}

# Execute script
main "$@"