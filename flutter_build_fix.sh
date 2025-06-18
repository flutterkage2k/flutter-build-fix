#!/usr/bin/env bash

# =============================================================================
# Flutter Gradle & JDK Build Error 해결 스크립트 (Flutter 3.32.4 최적화 버전)
#
# 사용법:
#   ./flutter_build_fix.sh [옵션]
#
# 옵션:
#   --full       모든 단계 실행 (기본값)
#   --android    Android 관련만
#   --ios        iOS 관련만
#   --build      빌드까지 실행 (선택)
#   --help       도움말 표시
#
# 예시:
#   ./flutter_build_fix.sh --full --build
#   ./flutter_build_fix.sh --android
# =============================================================================

set -e

# 색상 설정
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

FAILED_COMMANDS=()
TOTAL_STEPS=0
CURRENT_STEP=0
BUILD=false

log_info()    { echo -e "${BLUE}ℹ️  $1${NC}"; }
log_success() { echo -e "${GREEN}✅ $1${NC}"; }
log_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
log_error()   { echo -e "${RED}❌ $1${NC}"; }
log_step() {
    CURRENT_STEP=$((CURRENT_STEP + 1))
    echo ""
    echo -e "${BLUE}🔧 [STEP $CURRENT_STEP/$TOTAL_STEPS] $1${NC}"
}
try_or_remind() {
    local CMD="$1"
    local DESC="${2:-$1}"
    echo "➡️  실행 중: $DESC"
    if bash -c "$CMD"; then
        log_success "완료: $DESC"
    else
        log_warning "실패: $DESC"
        FAILED_COMMANDS+=("$CMD")
    fi
}
detect_os() {
    case "$(uname -s)" in
        Darwin) echo "macos" ;;
        Linux) echo "linux" ;;
        *) echo "unknown" ;;
    esac
}
check_flutter_project() {
    if [ ! -f "pubspec.yaml" ]; then
        log_error "Flutter 프로젝트 루트가 아닙니다."
        exit 1
    fi
}

# Flutter 버전 체크
check_flutter_version() {
    local FLUTTER_VERSION=$(flutter --version | grep "Flutter" | cut -d' ' -f2)
    log_info "Flutter 버전: $FLUTTER_VERSION"
    
    # 3.32.x 이상 권장
    if [ "$FLUTTER_VERSION" \< "3.32.0" ]; then
        log_warning "Flutter 3.32.0 이상을 권장합니다. 현재: $FLUTTER_VERSION"
    fi
}

setup_java17() {
    log_step "Java 17 설정"
    local OS=$(detect_os)
    if [ "$OS" == "macos" ]; then
        JDK17_PATH=$(/usr/libexec/java_home -v17 2>/dev/null || true)
        if [ -z "$JDK17_PATH" ]; then
            if [ -d "/opt/homebrew/opt/openjdk@17" ]; then
                export JAVA_HOME="/opt/homebrew/opt/openjdk@17"
            elif [ -d "/usr/local/opt/openjdk@17" ]; then
                export JAVA_HOME="/usr/local/opt/openjdk@17"
            else
                log_error "Java 17 설치 필요: brew install openjdk@17"
                exit 1
            fi
        else
            export JAVA_HOME="$JDK17_PATH"
        fi
        export PATH="$JAVA_HOME/bin:$PATH"
        
        # Flutter config에도 Java path 설정
        try_or_remind "flutter config --jdk-dir \"$JAVA_HOME\""
        
        java -version
        log_success "JAVA_HOME 설정 완료: $JAVA_HOME"
        log_success "Flutter JDK 설정 완료"
    else
        log_warning "Java 설정은 macOS만 지원됩니다."
        log_info "Linux에서는 수동으로 flutter config --jdk-dir 명령을 실행하세요."
    fi
}

clean_flutter() {
    log_step "Flutter Clean & Pub Get"
    try_or_remind "flutter clean"
    try_or_remind "flutter pub get"
}

# Gradle 프로퍼티 최적화 (Flutter 3.32+ 최적화)
setup_gradle_properties() {
    local GP="android/gradle.properties"
    if [ -f "$GP" ]; then cp "$GP" "${GP}.backup"; fi
    cat > "$GP" << 'EOF'
# Gradle 성능 최적화 (Flutter 3.32+ 최적화)
org.gradle.jvmargs=-Xmx4096M -Dfile.encoding=UTF-8 -XX:+UseG1GC
org.gradle.daemon=true
org.gradle.parallel=true
org.gradle.caching=true
org.gradle.configuration-cache=true
org.gradle.configuration-cache.problems=warn

# Android 설정
android.useAndroidX=true
android.enableJetifier=true
flutter.minSdkVersion=24

# Flutter 3.32+ 관련
android.experimental.enableScreenshotTest=true
android.enableR8.fullMode=true
EOF
    log_success "gradle.properties 최적화 완료 (Flutter 3.32+ 설정 적용)"
}

# Kotlin DSL 지원 확인
check_kotlin_dsl() {
    local WRAPPER="android/gradle/wrapper/gradle-wrapper.properties"
    local BUILD_GRADLE="android/build.gradle"
    local BUILD_GRADLE_KTS="android/build.gradle.kts"
    
    if [ -f "$BUILD_GRADLE_KTS" ]; then
        log_info "Kotlin DSL 감지됨 (build.gradle.kts)"
        return 0
    elif [ -f "$BUILD_GRADLE" ]; then
        log_info "Groovy DSL 감지됨 (build.gradle)"
        log_warning "Flutter 3.29+에서는 Kotlin DSL 사용을 권장합니다."
        return 1
    fi
    return 1
}

clean_android_gradle() {
    log_step "Android Gradle 정리"
    
    # Kotlin DSL 체크
    check_kotlin_dsl
    
    local WRAPPER="android/gradle/wrapper/gradle-wrapper.properties"
    if [ -f "$WRAPPER" ]; then
        cp "$WRAPPER" "${WRAPPER}.backup"
        # Gradle 8.6으로 업데이트 (Flutter 3.32+ 호환)
        sed -i.bak 's/gradle-.*-all.zip/gradle-8.6-all.zip/g' "$WRAPPER"
        log_info "Gradle 버전 8.6으로 업데이트 완료"
    fi
    
    cd android
    try_or_remind "./gradlew clean"
    try_or_remind "./gradlew --stop"
    cd ..
    
    try_or_remind "pkill -f gradle || true"
    try_or_remind "rm -rf \$HOME/.gradle/caches/ \$HOME/.gradle/daemon/ android/.gradle/ android/build/"
    
    setup_gradle_properties
    
    cd android
    try_or_remind "./gradlew wrapper --gradle-version=8.6 --distribution-type=all"
    cd ..
}

clean_ios() {
    log_step "iOS 정리"
    try_or_remind "rm -rf ios/Pods ios/.symlinks ios/Flutter/Flutter.framework ios/Podfile.lock"
    
    if command -v pod &> /dev/null; then
        try_or_remind "pod cache clean --all"
        cd ios
        try_or_remind "pod deintegrate"
        
        # 일반적인 경우는 --repo-update 없이 시도
        echo "➡️  pod install 시도 중..."
        if ! pod install; then
            log_warning "일반 pod install 실패. --repo-update로 재시도합니다..."
            log_info "⏱️  시간이 오래 걸릴 수 있습니다 (3-10분)"
            try_or_remind "pod install --repo-update"
        else
            log_success "pod install 성공"
        fi
        cd ..
    else
        log_warning "CocoaPods 미설치"
    fi
}

clean_xcode() {
    if [ "$(detect_os)" == "macos" ]; then
        log_step "Xcode DerivedData 정리"
        try_or_remind "rm -rf ~/Library/Developer/Xcode/DerivedData/*"
        # Xcode 캐시도 정리
        try_or_remind "rm -rf ~/Library/Caches/com.apple.dt.Xcode/*"
    fi
}

# 호환성 체크 추가
check_compatibility() {
    log_step "호환성 검사"
    
    # Flutter analyze로 호환성 체크
    try_or_remind "flutter analyze --suggestions"
    
    # Doctor 실행
    flutter doctor -v
}

clean_android_full() {
    setup_java17
    clean_android_gradle
    check_compatibility
    $BUILD && try_or_remind "flutter build apk --warning-mode=none"
}

clean_ios_full() {
    clean_ios
    clean_xcode
    $BUILD && try_or_remind "flutter build ios --no-codesign"
}

show_summary() {
    echo ""
    log_success "✅ 정리 완료!"
    
    if [ ${#FAILED_COMMANDS[@]} -gt 0 ]; then
        log_warning "⚠️ 실패 명령 목록:"
        for cmd in "${FAILED_COMMANDS[@]}"; do echo "  - $cmd"; done
        echo ""
        log_info "💡 실패한 명령들은 수동으로 실행해보세요."
    fi
    
    echo ""
    log_info "🚀 Flutter 3.32.4 최적화 팁:"
    echo "  - 새 프로젝트는 Kotlin DSL 사용을 권장합니다"
    echo "  - flutter analyze --suggestions로 정기적으로 체크하세요"
    echo "  - flutter doctor -v로 환경을 확인하세요"
}

show_help() {
    echo "Flutter 3.32.4 최적화 빌드 수정 스크립트"
    echo ""
    echo "사용법: $0 [--full|--android|--ios] [--build]"
    echo "  --full       전체 정리 (기본)"
    echo "  --android    Android 전용"
    echo "  --ios        iOS 전용"
    echo "  --build      빌드까지 실행"
    echo "  --help       도움말"
    echo ""
    echo "Flutter 3.32.4 주요 개선사항:"
    echo "  • Gradle 8.6+ 지원"
    echo "  • Kotlin DSL 권장"
    echo "  • 향상된 성능 최적화"
    echo "  • 개선된 호환성 검사"
}

main() {
    MODE="full"
    while [[ $# -gt 0 ]]; do
        case $1 in
            --full) MODE="full" ;;
            --android) MODE="android" ;;
            --ios) MODE="ios" ;;
            --build) BUILD=true ;;
            --help|-h) show_help; exit 0 ;;
            *) log_error "알 수 없는 옵션: $1"; show_help; exit 1 ;;
        esac
        shift
    done
    
    log_info "🚀 Flutter 3.32.4 최적화 빌드 수정 스크립트 시작"
    
    check_flutter_project
    check_flutter_version
    clean_flutter
    
    case $MODE in
        full) clean_android_full; clean_ios_full ;;
        android) clean_android_full ;;
        ios) clean_ios_full ;;
    esac
    
    show_summary
}

main "$@"