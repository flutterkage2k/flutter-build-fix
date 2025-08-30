#!/usr/bin/env bash

# =============================================================================
# Flutter Build Fix - Universal (Groovy + Kotlin DSL) 지원
# 
# Repository: https://github.com/flutterkage2k/flutter-build-fix
# Author: Heesung Jin (kage2k)
# Version: 3.0.0 - Universal DSL Support
# =============================================================================

set -e

# 색상 설정
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m'

# 버전 정보
SCRIPT_VERSION="3.0.0"
REPO="flutterkage2k/flutter-build-fix"

# 안정적인 Gradle 버전 목록 (2025년 8월 업데이트)
STABLE_GRADLE_VERSIONS=("8.11.1" "8.10" "8.9" "8.6")

# 로그 함수들
log_info()    { echo -e "${BLUE}ℹ️  $1${NC}"; }
log_success() { echo -e "${GREEN}✅ $1${NC}"; }
log_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
log_error()   { echo -e "${RED}❌ $1${NC}"; }
log_step()    { echo -e "${CYAN}🔧 $1${NC}"; }
log_fun()     { echo -e "${PURPLE}$1${NC}"; }

# =============================================================================
# 🎯 핵심: 프로젝트 타입 스마트 감지 시스템
# =============================================================================

# 프로젝트 타입 감지 (Kotlin DSL vs Groovy DSL)
detect_gradle_type() {
    log_step "Gradle 프로젝트 타입 자동 감지 중..."
    
    # 1순위: settings 파일로 판단
    if [ -f "android/settings.gradle.kts" ]; then
        echo "kotlin_dsl"
        return 0
    elif [ -f "android/settings.gradle" ]; then
        echo "groovy_dsl"
        return 0
    fi
    
    # 2순위: app build 파일로 판단
    if [ -f "android/app/build.gradle.kts" ]; then
        echo "kotlin_dsl"
        return 0
    elif [ -f "android/app/build.gradle" ]; then
        echo "groovy_dsl"
        return 0
    fi
    
    # 3순위: 루트 build 파일로 판단
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

# 프로젝트 구조 상세 분석
analyze_project_structure() {
    local gradle_type="$1"
    
    log_info "📊 프로젝트 구조 분석 결과:"
    
    case "$gradle_type" in
        "kotlin_dsl")
            log_success "🔷 Kotlin DSL 프로젝트 감지 (Flutter 3.29+ 신규 방식)"
            log_info "   └─ settings.gradle.kts: $([ -f "android/settings.gradle.kts" ] && echo "✅" || echo "❌")"
            log_info "   └─ app/build.gradle.kts: $([ -f "android/app/build.gradle.kts" ] && echo "✅" || echo "❌")"
            log_info "   └─ build.gradle.kts: $([ -f "android/build.gradle.kts" ] && echo "✅" || echo "❌")"
            ;;
        "groovy_dsl")
            log_success "🟢 Groovy DSL 프로젝트 감지 (Flutter 3.28 이하 기존 방식)"
            log_info "   └─ settings.gradle: $([ -f "android/settings.gradle" ] && echo "✅" || echo "❌")"
            log_info "   └─ app/build.gradle: $([ -f "android/app/build.gradle" ] && echo "✅" || echo "❌")"
            log_info "   └─ build.gradle: $([ -f "android/build.gradle" ] && echo "✅" || echo "❌")"
            ;;
        "unknown")
            log_error "❓ 알 수 없는 프로젝트 구조"
            log_info "Android 폴더가 존재하지 않거나 손상된 것 같습니다"
            return 1
            ;;
    esac
    
    # Flutter 버전 확인
    if command -v flutter >/dev/null 2>&1; then
        local flutter_version=$(flutter --version | head -1 | grep -o 'Flutter [0-9.]*' | cut -d' ' -f2)
        log_info "🎯 Flutter 버전: $flutter_version"
    fi
}

# =============================================================================
# 🔧 Kotlin DSL 전용 처리 함수들
# =============================================================================

# Kotlin DSL settings.gradle.kts 업데이트
update_kotlin_settings_gradle() {
    local settings_file="android/settings.gradle.kts"
    
    if [ ! -f "$settings_file" ]; then
        log_warning "settings.gradle.kts 파일을 찾을 수 없습니다"
        return 1
    fi
    
    log_step "Kotlin DSL settings.gradle.kts 업데이트"
    
    # 백업 생성
    cp "$settings_file" "${settings_file}.backup"
    
    # AGP 버전 업데이트 (Kotlin DSL 문법)
    sed -i '' 's/id("com.android.application") version "[^"]*"/id("com.android.application") version "8.6.0"/g' "$settings_file"
    
    # Kotlin 버전 업데이트 (2025년 권장)
    sed -i '' 's/id("org.jetbrains.kotlin.android") version "[^"]*"/id("org.jetbrains.kotlin.android") version "2.0.20"/g' "$settings_file"
    
    log_success "settings.gradle.kts AGP 8.6.0, Kotlin 2.0.20으로 업데이트"
}

# Kotlin DSL app/build.gradle.kts 업데이트
update_kotlin_app_build() {
    local app_build_file="android/app/build.gradle.kts"
    
    if [ ! -f "$app_build_file" ]; then
        log_warning "app/build.gradle.kts 파일을 찾을 수 없습니다"
        return 1
    fi
    
    log_step "Kotlin DSL app/build.gradle.kts Java 17 호환성 설정"
    
    # 백업 생성
    cp "$app_build_file" "${app_build_file}.backup"
    
    # Java 17 compileOptions 확인 및 추가
    if ! grep -q "compileOptions" "$app_build_file"; then
        # android 블록 안에 compileOptions 추가
        sed -i '' '/android {/a\
    compileOptions {\
        sourceCompatibility = JavaVersion.VERSION_17\
        targetCompatibility = JavaVersion.VERSION_17\
    }\
' "$app_build_file"
        log_success "Java 17 compileOptions 추가됨"
    else
        # 기존 compileOptions 업데이트
        sed -i '' 's/sourceCompatibility = JavaVersion\.VERSION_[0-9_]*/sourceCompatibility = JavaVersion.VERSION_17/g' "$app_build_file"
        sed -i '' 's/targetCompatibility = JavaVersion\.VERSION_[0-9_]*/targetCompatibility = JavaVersion.VERSION_17/g' "$app_build_file"
        log_success "기존 compileOptions Java 17로 업데이트"
    fi
    
    # Kotlin JVM Target 확인 및 설정
    if grep -q "kotlinOptions" "$app_build_file"; then
        # 기존 kotlinOptions 업데이트
        sed -i '' 's/jvmTarget = "[^"]*"/jvmTarget = "17"/g' "$app_build_file"
        log_success "kotlinOptions jvmTarget 17로 업데이트"
    else
        # kotlinOptions 새로 추가
        sed -i '' '/compileOptions {/a\
\
    kotlinOptions {\
        jvmTarget = "17"\
    }\
' "$app_build_file"
        log_success "kotlinOptions jvmTarget 17 추가됨"
    fi
    
    # minSdk 26 이상 확인 (2025년 권장)
    if grep -q "minSdk" "$app_build_file"; then
        # minSdk 값 확인
        local current_min_sdk=$(grep "minSdk" "$app_build_file" | grep -o '[0-9]*' | head -1)
        if [ -n "$current_min_sdk" ] && [ "$current_min_sdk" -lt 26 ]; then
            sed -i '' "s/minSdk = [0-9]*/minSdk = 26/g" "$app_build_file"
            log_success "minSdk를 26으로 업데이트 (이전: $current_min_sdk)"
        fi
    fi
}

# Kotlin DSL 전용 Gradle 설정
configure_kotlin_dsl_gradle() {
    log_step "🔷 Kotlin DSL 프로젝트 설정 시작"
    
    # 1. settings.gradle.kts 업데이트
    update_kotlin_settings_gradle
    
    # 2. app/build.gradle.kts 업데이트
    update_kotlin_app_build
    
    # 3. gradle.properties 설정 (공통)
    configure_gradle_properties_universal
    
    # 4. Gradle Wrapper 업데이트 (공통)
    update_gradle_wrapper_universal
    
    log_success "🔷 Kotlin DSL 설정 완료"
}

# =============================================================================
# 🔧 Groovy DSL 전용 처리 함수들 (기존 + 개선)
# =============================================================================

# Groovy DSL settings.gradle 업데이트
update_groovy_settings_gradle() {
    local settings_file="android/settings.gradle"
    
    if [ ! -f "$settings_file" ]; then
        log_warning "settings.gradle 파일을 찾을 수 없습니다"
        return 1
    fi
    
    log_step "Groovy DSL settings.gradle 업데이트"
    
    # 백업 생성
    cp "$settings_file" "${settings_file}.backup"
    
    # AGP 버전 업데이트 (Groovy DSL 문법)
    sed -i '' 's/id "com.android.application" version "[^"]*"/id "com.android.application" version "8.6.0"/g' "$settings_file"
    
    # Kotlin 버전 업데이트
    sed -i '' 's/id "org.jetbrains.kotlin.android" version "[^"]*"/id "org.jetbrains.kotlin.android" version "2.0.20"/g' "$settings_file"
    
    log_success "settings.gradle AGP 8.6.0, Kotlin 2.0.20으로 업데이트"
}

# Groovy DSL app/build.gradle 업데이트 (기존 함수 개선)
update_groovy_app_build() {
    local app_build_file="android/app/build.gradle"
    
    if [ ! -f "$app_build_file" ]; then
        log_warning "app/build.gradle 파일을 찾을 수 없습니다"
        return 1
    fi
    
    log_step "Groovy DSL app/build.gradle Java 17 호환성 설정"
    
    # 백업 생성
    cp "$app_build_file" "${app_build_file}.backup"
    
    # Kotlin JVM target 수정 (Groovy 문법)
    sed -i '' 's/jvmTarget.*21/jvmTarget = '\''17'\''/g' "$app_build_file"
    sed -i '' 's/jvmTarget.*= '\''21'\''/jvmTarget = '\''17'\''/g' "$app_build_file"
    sed -i '' 's/jvmTarget.*= "21"/jvmTarget = "17"/g' "$app_build_file"
    
    # Java 호환성도 17로 설정
    sed -i '' 's/JavaVersion\.VERSION_21/JavaVersion.VERSION_17/g' "$app_build_file"
    
    log_success "Groovy DSL Java 17 호환성 설정 완료"
}

# Groovy DSL 전용 Gradle 설정
configure_groovy_dsl_gradle() {
    log_step "🟢 Groovy DSL 프로젝트 설정 시작"
    
    # 1. settings.gradle 업데이트 (있는 경우)
    if [ -f "android/settings.gradle" ]; then
        update_groovy_settings_gradle
    fi
    
    # 2. app/build.gradle 업데이트
    update_groovy_app_build
    
    # 3. gradle.properties 설정 (공통)
    configure_gradle_properties_universal
    
    # 4. Gradle Wrapper 업데이트 (공통)
    update_gradle_wrapper_universal
    
    log_success "🟢 Groovy DSL 설정 완료"
}

# =============================================================================
# 🌐 범용 공통 함수들
# =============================================================================

# 범용 Gradle Wrapper 업데이트 (DSL 타입 무관)
update_gradle_wrapper_universal() {
    local wrapper_props="android/gradle/wrapper/gradle-wrapper.properties"
    local recommended_version="8.11.1"
    
    if [ ! -f "$wrapper_props" ]; then
        log_error "gradle-wrapper.properties 파일을 찾을 수 없습니다"
        return 1
    fi
    
    log_step "Gradle Wrapper 버전 업데이트"
    
    # 현재 버전 확인
    local current_gradle=$(grep "gradle-.*-all.zip" "$wrapper_props" | sed -E 's/.*gradle-([0-9.]+)-all.zip.*/\1/')
    log_info "현재 Gradle 버전: $current_gradle"
    log_info "권장 Gradle 버전: $recommended_version"
    
    if [ "$current_gradle" != "$recommended_version" ]; then
        # 백업 생성
        cp "$wrapper_props" "${wrapper_props}.backup"
        
        # 안전한 버전으로 업데이트
        sed -i '' "s|gradle-.*-all\.zip|gradle-${recommended_version}-all.zip|g" "$wrapper_props"
        log_success "Gradle $recommended_version로 업데이트됨"
    else
        log_success "현재 Gradle 버전이 이미 최적입니다"
    fi
}

# 범용 gradle.properties 설정 (DSL 타입 무관)
configure_gradle_properties_universal() {
    local gradle_props="android/gradle.properties"
    
    if [ ! -f "$gradle_props" ]; then
        log_warning "gradle.properties 파일을 찾을 수 없습니다"
        return 1
    fi
    
    log_step "범용 gradle.properties 최적화 설정"
    
    # 백업 생성
    cp "$gradle_props" "${gradle_props}.backup"
    
    # 기존 Flutter Build Fix 설정 제거
    grep -v "# Flutter Build Fix" "$gradle_props" > "${gradle_props}.tmp" || true
    mv "${gradle_props}.tmp" "$gradle_props"
    
    # 2025년 최적화된 설정 추가
    {
        echo ""
        echo "# Flutter Build Fix 범용 설정 v$SCRIPT_VERSION"
        echo "# Java 17 + Gradle 8.11.1 최적화"
        echo "org.gradle.jvmargs=-Xmx4096m -XX:MaxMetaspaceSize=768m"
        echo "org.gradle.parallel=true"
        echo "org.gradle.daemon=true"
        echo "org.gradle.configuration-cache=true"
        echo "org.gradle.configuration-cache.problems=warn"
        echo "org.gradle.caching=true"
        echo ""
        echo "# Android 표준 설정"
        echo "android.useAndroidX=true"
        echo "android.enableJetifier=true"
        echo ""
        echo "# 2025년 권장 설정"
        echo "flutter.minSdkVersion=26"
        echo "kotlin.jvm.target.validation.mode=warning"
        echo ""
        echo "# Kotlin DSL 호환성"
        echo "org.gradle.kotlin.dsl.allWarningsAsErrors=false"
        echo "kotlin.daemon.jvm.options=-Xmx2048m"
    } >> "$gradle_props"
    
    log_success "범용 gradle.properties 설정 완료"
}

# =============================================================================
# 🎯 메인 범용 처리 시스템
# =============================================================================

# 범용 Gradle 설정 (스마트 분기)
configure_gradle_universal() {
    log_step "🌟 범용 Gradle 설정 시스템 시작"
    
    # 1단계: 프로젝트 타입 감지
    local gradle_type=$(detect_gradle_type)
    
    if [ "$gradle_type" = "unknown" ]; then
        log_error "지원하지 않는 프로젝트 구조입니다"
        log_info "💡 해결 방법:"
        echo "   1. Flutter 프로젝트 루트에서 실행하세요"
        echo "   2. android 폴더가 존재하는지 확인하세요"
        echo "   3. flutter create로 새 프로젝트를 만들어보세요"
        return 1
    fi
    
    # 2단계: 프로젝트 구조 분석
    analyze_project_structure "$gradle_type"
    
    # 3단계: 타입별 분기 처리
    case "$gradle_type" in
        "kotlin_dsl")
            log_info "🚀 Kotlin DSL 최적화 경로로 진행합니다"
            configure_kotlin_dsl_gradle
            ;;
        "groovy_dsl")
            log_info "🚀 Groovy DSL 최적화 경로로 진행합니다"
            configure_groovy_dsl_gradle
            ;;
    esac
    
    log_success "🌟 범용 Gradle 설정 완료!"
}

# =============================================================================
# 🧪 범용 빌드 테스트 시스템
# =============================================================================

# 범용 Gradle 검증 (DSL 타입 무관)
validate_gradle_universal() {
    log_step "🧪 범용 Gradle 환경 검증"
    
    if [ ! -f "android/gradlew" ]; then
        log_error "gradlew 파일을 찾을 수 없습니다"
        return 1
    fi
    
    cd android
    
    # 1단계: 기본 Gradle 작동 확인
    if ./gradlew projects --quiet > /dev/null 2>&1; then
        log_success "Gradle 기본 설정 정상"
        cd ..
        return 0
    else
        log_info "Gradle 기본 설정 확인 중..."
        cd ..
        return 1
    fi
}

# 범용 빌드 테스트
test_gradle_build_universal() {
    # 1단계: 안전 검증
    if ! validate_gradle_universal; then
        log_warning "Gradle 기본 설정에 문제가 있습니다"
        return 1
    fi
    
    # 2단계: 실제 빌드 테스트
    log_step "🏗️ Android 빌드 호환성 테스트 시작"
    
    if show_progress_with_fun "flutter build apk --debug --quiet" "Android 빌드 테스트"; then
        log_success "빌드 테스트 성공! 모든 설정이 정상입니다 🎉"
        return 0
    else
        log_warning "빌드 테스트 실패 - 추가 설정이 필요할 수 있습니다"
        log_info "💡 수동 확인 방법:"
        echo "   1. cd android && ./gradlew --version"
        echo "   2. flutter doctor -v"
        echo "   3. flutter build apk --debug"
        return 1
    fi
}

# =============================================================================
# 📊 기존 함수들 (유지 + 개선)
# =============================================================================

# 안전한 삭제 함수 (기존 유지)
safe_remove() {
    local path="$1"
    local description="$2"
    
    if [ -d "$path" ] || [ -f "$path" ]; then
        if rm -rf "$path" 2>/dev/null; then
            log_success "$description 삭제됨"
            return 0
        else
            log_warning "$description 삭제 실패 (사용 중이거나 권한 부족)"
            log_info "💡 수동 삭제 방법: sudo rm -rf $path"
            return 1
        fi
    else
        log_info "$description 경로가 존재하지 않음 (정상)"
        return 0
    fi
}

# macOS 체크 (기존 유지)
check_macos() {
    if [[ "$OSTYPE" != "darwin"* ]]; then
        log_error "이 스크립트는 macOS 전용입니다"
        log_info "현재 OS: $OSTYPE"
        exit 1
    fi
}

# Flutter 프로젝트 체크 (기존 유지)
check_flutter_project() {
    if [ ! -f "pubspec.yaml" ]; then
        log_error "Flutter 프로젝트 루트에서 실행해주세요"
        log_info "pubspec.yaml 파일을 찾을 수 없습니다"
        exit 1
    fi
    
    local project_name
    project_name=$(grep "^name:" pubspec.yaml | cut -d' ' -f2 | tr -d '"' | head -1)
    log_info "Flutter 프로젝트: $project_name"
}

# Java 17 설정 (기존 유지)
setup_java17() {
    log_step "Java 17 환경 설정"
    
    # /usr/libexec/java_home 우선 사용
    local java_home_path
    java_home_path=$(/usr/libexec/java_home -v17 2>/dev/null || true)
    
    if [ -n "$java_home_path" ]; then
        export JAVA_HOME="$java_home_path"
        log_info "✅ /usr/libexec/java_home으로 Java 17 발견: $JAVA_HOME"
    else
        # Homebrew 경로들을 체크
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
            log_info "✅ Homebrew에서 Java 17 발견: $JAVA_HOME"
        else
            log_error "Java 17을 찾을 수 없습니다!"
            log_info "💡 해결 방법:"
            echo "   1. brew install openjdk@17"
            echo "   2. brew link openjdk@17"
            exit 1
        fi
    fi
    
    export PATH="$JAVA_HOME/bin:$PATH"
    
    # local.properties에 java.home 명시적 설정
    if [ -f "android/local.properties" ]; then
        sed -i.bak '/^java\.home=/d' android/local.properties
        echo "java.home=$JAVA_HOME" >> android/local.properties
        log_success "local.properties에 java.home 설정 완료"
    fi
    
    # Flutter config에도 Java path 설정
    flutter config --jdk-dir "$JAVA_HOME" > /dev/null 2>&1 || true
    
    # 설정 확인
    echo "📋 현재 Java 설정:"
    echo "   JAVA_HOME: $JAVA_HOME"
    java -version 2>&1 | head -1
    
    log_success "Java 17 설정 완료"
}

# Groovy DSL 전용 Gradle 설정
configure_groovy_dsl_gradle() {
    log_step "🟢 Groovy DSL 프로젝트 설정 시작"
    
    # 1. settings.gradle 업데이트 (있는 경우)
    if [ -f "android/settings.gradle" ]; then
        update_groovy_settings_gradle
    fi
    
    # 2. app/build.gradle 업데이트  
    update_groovy_app_build
    
    # 3. gradle.properties 설정 (공통)
    configure_gradle_properties_universal
    
    # 4. Gradle Wrapper 업데이트 (공통)
    update_gradle_wrapper_universal
    
    log_success "🟢 Groovy DSL 설정 완료"
}

# Flutter 정리 (기존 유지)
clean_flutter() {
    log_step "Flutter 캐시 정리"
    
    safe_remove "build" "build 폴더"
    
    flutter clean > /dev/null 2>&1
    log_success "flutter clean 완료"
    
    flutter pub get > /dev/null 2>&1
    log_success "flutter pub get 완료"
    
    if command -v flutter >/dev/null 2>&1; then
        flutter analyze --suggestions > /dev/null 2>&1 || true
        log_success "Flutter 호환성 검사 완료"
    fi
}

# 재미있는 메시지 배열 (기존 유지)
declare -a MESSAGES_15S=("⏱️  빌드 준비 중... 잠시만요!" "📄 의존성 확인 중..." "📦 패키지 정리 중...")
declare -a MESSAGES_30S=("☕ 조금만 기다려주세요... 커피 한 모금 어때요?" "🎵 거의 다 끝났어요... 좋아하는 노래 한 소절!" "📱 Flutter가 열심히 일하고 있어요...")
declare -a MESSAGES_1M=("🍕 아직도 빌드 중... 오늘 점심 뭐 드실래요?" "📚 책 한 페이지라도 읽어볼까요?" "🚀 복잡한 의존성을 정리하는 중... 거의 끝!")
declare -a MESSAGES_2M=("😅 참아주세요... 이것도 개발의 일부예요!" "🏃‍♂️ 스트레칭이라도 한번 해볼까요?" "🧘‍♀️ 심호흡... 곧 끝날 거예요!" "🎯 마지막 단계예요... 조금만 더 인내!")

# 개선된 진행 표시기 (범용 지원)
show_progress_with_fun() {
    local command="$1"
    local description="$2"
    
    # 백그라운드에서 명령어 실행
    $command > /tmp/flutter_build_output.log 2>&1 &
    local cmd_pid=$!
    
    local start_time=$(date +%s)
    local last_message_time=$start_time
    
    log_step "$description"
    
    while kill -0 $cmd_pid 2>/dev/null; do
        local current_time=$(date +%s)
        local elapsed=$((current_time - start_time))
        
        # 15초마다 메시지 업데이트
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
    
    # 프로세스 종료 대기
    wait $cmd_pid
    local exit_code=$?
    
    local total_time=$(($(date +%s) - start_time))
    
    if [ $exit_code -eq 0 ]; then
        log_success "$description 완료! (${total_time}초)"
        if [ $total_time -ge 15 ]; then
            log_fun "🎉 기다려주셔서 감사해요!"
        fi
    else
        log_warning "$description 실패 (${total_time}초)"
        log_info "자세한 로그: /tmp/flutter_build_output.log"
    fi
    
    return $exit_code
}

# =============================================================================
# 🚀 범용 보수적 Gradle 관리 시스템
# =============================================================================

# 범용 보수적 Gradle 정리 및 관리
clean_gradle_universal() {
    log_step "🌟 범용 보수적 Gradle 정리 및 관리"
    
    # 모든 Gradle Daemon 종료
    if command -v gradle >/dev/null 2>&1; then
        gradle --stop 2>/dev/null || true
        log_success "Gradle Daemon 종료됨"
    fi
    
    # Android 프로젝트용 gradlew 종료
    if [ -f "android/gradlew" ]; then
        cd android
        ./gradlew --stop 2>/dev/null || true
        cd ..
        log_success "Android Gradle Daemon 종료됨"
    fi
    
    # 안전한 캐시 삭제
    safe_remove "$HOME/.gradle/caches/modules-2" "Gradle 모듈 캐시"
    safe_remove "android/.gradle" "로컬 Gradle 캐시"
    
    # 범용 Gradle 설정 적용
    configure_gradle_universal
    
    # 단계별 검증 및 빌드 테스트
    if ! test_gradle_build_universal; then
        log_warning "첫 번째 빌드 테스트 실패, 재시도 중..."
        
        if test_gradle_build_universal; then
            log_success "재시도 빌드 성공!"
        else
            log_warning "Gradle 설정을 완전히 해결하지 못했습니다"
            log_info "다음 명령어로 수동 확인을 권장합니다:"
            log_info "cd android && ./gradlew --version"
            log_info "flutter build apk --debug"
        fi
    else
        log_success "범용 Gradle 환경 검증 및 빌드 테스트 완료"
    fi
}

# iOS 정리 (기존 유지)
clean_ios() {
    log_step "iOS 환경 정리"
    
    if [ ! -d "ios" ]; then
        log_warning "iOS 폴더가 없습니다. iOS 지원이 없는 프로젝트인 것 같습니다"
        return
    fi
    
    cd ios
    
    # 안전한 Pods 정리
    safe_remove "Pods" "Pods 폴더"
    safe_remove "Podfile.lock" "Podfile.lock"
    
    # CocoaPods 캐시 정리
    if command -v pod >/dev/null 2>&1; then
        pod cache clean --all 2>/dev/null || true
        log_success "CocoaPods 캐시 정리됨"
        
        log_step "CocoaPods 재설치 시작"
        
        if show_progress_with_fun "pod install" "CocoaPods 설치"; then
            log_success "Pod 설치 완료 (빠른 방법)"
        else
            log_info "빠른 설치 실패, repo 업데이트 후 재시도"
            if show_progress_with_fun "pod install --repo-update" "CocoaPods 설치 (repo 업데이트)"; then
                log_success "Pod 설치 완료 (repo 업데이트)"
            else
                log_warning "Pod 설치에 문제가 있습니다"
            fi
        fi
    else
        log_warning "CocoaPods가 설치되지 않았습니다"
        log_info "설치 방법: brew install cocoapods"
    fi
    
    cd ..
    
    # 안전한 Xcode 캐시 정리
    log_step "Xcode 캐시 정리"
    safe_remove "$HOME/Library/Developer/Xcode/DerivedData" "Xcode DerivedData"
    
    # 30일 이상된 Archives 정리
    local archives="$HOME/Library/Developer/Xcode/Archives"
    if [ -d "$archives" ]; then
        if find "$archives" -name "*.xcarchive" -mtime +30 -delete 2>/dev/null; then
            log_success "30일 이상된 Xcode Archives 정리됨"
        else
            log_info "Xcode Archives 정리 건너뜀 (권한 또는 파일 없음)"
        fi
    fi
}

# iOS 빌드 테스트
test_ios_build() {
    if [ ! -d "ios" ]; then
        log_info "iOS 폴더가 없어 빌드 테스트를 건너뜁니다"
        return 0
    fi
    
    log_step "iOS 빌드 테스트 시작"
    
    if show_progress_with_fun "flutter build ios --debug --no-codesign --quiet" "iOS 빌드 테스트"; then
        log_success "iOS 빌드 테스트 성공!"
        return 0
    else
        log_warning "iOS 빌드 테스트 실패 (정상적인 경우도 있음)"
        return 1
    fi
}

# =============================================================================
# 🎯 실행 모드들
# =============================================================================

# Android 모드 (범용 지원)
android_mode() {
    echo -e "${GREEN}🤖 Android 범용 모드 시작${NC}"
    echo ""
    
    setup_java17
    clean_flutter
    clean_gradle_universal
    
    echo ""
    log_success "🎉 Android 정리 완료!"
    log_info "🌟 Groovy DSL과 Kotlin DSL 모두 지원됨"
}

# iOS 모드
ios_mode() {
    echo -e "${GREEN}🍎 iOS 모드 시작${NC}"
    echo ""
    
    clean_flutter
    clean_ios
    test_ios_build
    
    echo ""
    log_success "🎉 iOS 정리 완료!"
}

# 전체 모드 (범용 지원)
full_mode() {
    echo -e "${GREEN}🌟 전체 범용 정리 모드 시작${NC}"
    echo ""
    
    setup_java17
    clean_flutter
    clean_gradle_universal
    clean_ios
    test_ios_build
    
    echo ""
    log_success "🎉 전체 정리 완료!"
    log_info "🌟 Kotlin DSL과 Groovy DSL 완벽 지원"
}

# =============================================================================
# 🆘 도움말 및 버전 정보
# =============================================================================

# 도움말 표시
show_help() {
    echo -e "${BLUE}Flutter Build Fix v$SCRIPT_VERSION - 범용 DSL 지원${NC}"
    echo ""
    echo "✨ 새로운 기능: Kotlin DSL (.kts)과 Groovy DSL (.gradle) 완벽 지원!"
    echo ""
    echo "사용법:"
    echo "  $0 [옵션]"
    echo ""
    echo "옵션:"
    echo "  --full      전체 정리 (Android + iOS, 기본값)"
    echo "  --android   Android 문제만 해결"  
    echo "  --ios       iOS 문제만 해결"
    echo "  --version   버전 정보 표시"
    echo "  --help      이 도움말 표시"
    echo ""
    echo "예제:"
    echo "  $0                # 전체 정리"
    echo "  $0 --android     # Android만"
    echo "  $0 --ios         # iOS만"
    echo ""
    echo "🌟 특징: Flutter 3.29+ Kotlin DSL과 기존 Groovy DSL 자동 감지 지원"
    echo "🛡️  안정성: 보수적 Gradle 버전 관리로 최고 안정성 보장"
    echo "Repository: https://github.com/$REPO"
}

# 버전 정보 표시
show_version() {
    echo "Flutter Build Fix v$SCRIPT_VERSION"
    echo "🌟 범용 DSL 지원 | Kotlin DSL + Groovy DSL | macOS 전용"
    echo "🛡️  안정성: 보수적 Gradle 관리 | 안전한 오류 처리"
    echo "📊 지원 Gradle 버전: ${STABLE_GRADLE_VERSIONS[*]}"
    echo "🔷 Kotlin DSL: Flutter 3.29+ 신규 프로젝트 완벽 지원"
    echo "🟢 Groovy DSL: Flutter 3.28 이하 기존 프로젝트 완벽 지원"
}

# GitHub 업데이트 확인
check_for_updates() {
    if command -v curl >/dev/null 2>&1; then
        local latest_version
        latest_version=$(curl -s "https://api.github.com/repos/$REPO/releases/latest" 2>/dev/null | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/' | head -1)
        
        if [ -n "$latest_version" ] && [ "$latest_version" != "v$SCRIPT_VERSION" ]; then
            echo ""
            log_warning "📢 새 버전이 있습니다: $latest_version (현재: v$SCRIPT_VERSION)"
            echo -e "${CYAN}📄 업데이트: curl -fsSL https://raw.githubusercontent.com/$REPO/main/install.sh -o install.sh && zsh install.sh${NC}"
            echo ""
        fi
    fi
}

# =============================================================================
# 🎯 메인 함수
# =============================================================================

main() {
    # macOS 체크
    check_macos
    
    # 헤더 출력
    echo -e "${BLUE}"
    echo "=================================================================="
    echo "    🚀 Flutter 3.35+ 범용 빌드 수정 스크립트"
    echo "    🌟 Kotlin DSL + Groovy DSL 완벽 지원 | v$SCRIPT_VERSION"
    echo "    🔷 Flutter 3.29+ (.kts) | 🟢 Flutter 3.28- (.gradle)"
    echo "    💻 macOS 전용 | 🛡️ 보수적 Gradle 관리"
    echo "    👨‍💻 Author: Heesung Jin (kage2k)"
    echo "=================================================================="
    echo -e "${NC}"
    
    # 업데이트 확인
    check_for_updates
    
    # Flutter 프로젝트 체크
    check_flutter_project
    
    # 인자 처리
    case "${1:-}" in
        --help|-h)
            show_help
            exit 0
            ;;
        --version|-v)
            show_version
            exit 0
            ;;
        --android)
            android_mode
            ;;
        --ios)
            ios_mode
            ;;
        --full|"")
            full_mode
            ;;
        *)
            log_error "알 수 없는 옵션: $1"
            echo ""
            show_help
            exit 1
            ;;
    esac
    
    echo ""
    log_info "💡 팁: 정기적으로 실행하면 Flutter 개발 환경을 최적 상태로 유지할 수 있어요!"
    log_info "🌟 범용성: Kotlin DSL과 Groovy DSL 프로젝트 모두 자동 지원"
    log_info "🛡️  안정성: 검증된 Gradle 버전 (${STABLE_GRADLE_VERSIONS[*]}) 우선 사용"
    log_info "🔗 Repository: https://github.com/$REPO"
}

# 스크립트 실행
main "$@"