#!/usr/bin/env bash

# =============================================================================
# Flutter Build Fix - macOS 전용 자동화 스크립트
# 
# Repository: https://github.com/flutterkage2k/flutter-build-fix
# Author: Heesung Jin (kage2k)
# Version: 2.1.0
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
SCRIPT_VERSION="2.1.0"

# GitHub 업데이트 확인
REPO="flutterkage2k/flutter-build-fix"
GITHUB_API="https://api.github.com/repos/$REPO/releases/latest"

# 로그 함수들
log_info()    { echo -e "${BLUE}ℹ️  $1${NC}"; }
log_success() { echo -e "${GREEN}✅ $1${NC}"; }
log_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
log_error()   { echo -e "${RED}❌ $1${NC}"; }
log_step()    { echo -e "${CYAN}🔧 $1${NC}"; }
log_fun()     { echo -e "${PURPLE}$1${NC}"; }

# macOS 체크
check_macos() {
    if [[ "$OSTYPE" != "darwin"* ]]; then
        log_error "이 스크립트는 macOS 전용입니다"
        log_info "현재 OS: $OSTYPE"
        exit 1
    fi
}

# 도움말 표시
show_help() {
    echo -e "${BLUE}Flutter Build Fix v$SCRIPT_VERSION - macOS 전용${NC}"
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
    echo "Repository: https://github.com/$REPO"
}

# 버전 정보 표시
show_version() {
    echo "Flutter Build Fix v$SCRIPT_VERSION"
    echo "macOS 전용"
}

# 업데이트 확인
check_for_updates() {
    if command -v curl >/dev/null 2>&1; then
        local latest_version
        latest_version=$(curl -s "$GITHUB_API" 2>/dev/null | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/' | head -1)
        
        if [ -n "$latest_version" ] && [ "$latest_version" != "v$SCRIPT_VERSION" ]; then
            echo ""
            log_warning "🔔 새 버전이 있습니다: $latest_version (현재: v$SCRIPT_VERSION)"
            echo -e "${CYAN}🔄 업데이트: curl -fsSL https://raw.githubusercontent.com/$REPO/main/install.sh -o install.sh && zsh install.sh${NC}"
            echo ""
        fi
    fi
}

# Flutter 프로젝트 체크
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

# 재미있는 메시지 배열
declare -a MESSAGES_30S=("☕ 조금만 기다려주세요... 커피 한 모금 어때요?" "🎵 거의 다 됐어요... 좋아하는 노래 한 소절!" "📱 Flutter가 열심히 일하고 있어요...")
declare -a MESSAGES_1M=("🍕 아직도 빌드 중... 오늘 점심 뭐 드실래요?" "📚 책 한 페이지라도 읽어볼까요?" "🚀 복잡한 의존성을 정리하는 중... 거의 끝!")
declare -a MESSAGES_2M=("😅 참아주세요... 이것도 개발의 일부에요!" "🏃‍♂️ 스트레칭이라도 한번 해볼까요?" "🧘‍♀️ 심호흡... 곧 끝날 거예요!" "🎯 마지막 단계예요... 조금만 더 인내!")

# 재미있는 진행 표시기
show_progress_with_fun() {
    local command="$1"
    local description="$2"
    
    # 백그라운드에서 명령어 실행
    $command > /tmp/flutter_build_output.log 2>&1 &
    local cmd_pid=$!
    
    local start_time=$(date +%s)
    local last_message_time=$start_time
    local message_shown=false
    
    log_step "$description"
    
    while kill -0 $cmd_pid 2>/dev/null; do
        local current_time=$(date +%s)
        local elapsed=$((current_time - start_time))
        
        # 30초마다 메시지 업데이트
        if [ $((current_time - last_message_time)) -ge 30 ]; then
            if [ $elapsed -ge 120 ] && [ $elapsed -lt 150 ]; then
                # 2분 이상
                local msg=${MESSAGES_2M[$((RANDOM % ${#MESSAGES_2M[@]}))]}
                log_fun "$msg"
                message_shown=true
            elif [ $elapsed -ge 60 ] && [ $elapsed -lt 90 ]; then
                # 1분 이상
                local msg=${MESSAGES_1M[$((RANDOM % ${#MESSAGES_1M[@]}))]}
                log_fun "$msg"
                message_shown=true
            elif [ $elapsed -ge 30 ] && [ $elapsed -lt 60 ]; then
                # 30초 이상
                local msg=${MESSAGES_30S[$((RANDOM % ${#MESSAGES_30S[@]}))]}
                log_fun "$msg"
                message_shown=true
            fi
            last_message_time=$current_time
        fi
        
        sleep 5
    done
    
    # 프로세스 종료 대기
    wait $cmd_pid
    local exit_code=$?
    
    local total_time=$(($(date +%s) - start_time))
    
    if [ $exit_code -eq 0 ]; then
        log_success "$description 완료! (${total_time}초)"
        if [ $message_shown = true ]; then
            log_fun "🎉 기다려주셔서 감사해요!"
        fi
    else
        log_warning "$description 실패 (${total_time}초)"
        log_info "자세한 로그: /tmp/flutter_build_output.log"
    fi
    
    return $exit_code
}

# Java 17 설정
setup_java17() {
    log_step "Java 17 환경 설정"
    
    # Homebrew Java 17 경로들
    local java_paths=(
        "/opt/homebrew/opt/openjdk@17"
        "/usr/local/opt/openjdk@17"
        "/Library/Java/JavaVirtualMachines/openjdk-17.jdk/Contents/Home"
        "/opt/homebrew/Cellar/openjdk@17/*/libexec/openjdk.jdk/Contents/Home"
    )
    
    local java_home=""
    
    # Java 17 경로 탐색
    for path in "${java_paths[@]}"; do
        # 와일드카드 경로 확장
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
        export PATH="$JAVA_HOME/bin:$PATH"
        log_success "Java 17 설정됨: $JAVA_HOME"
        
        local java_version
        java_version=$("$JAVA_HOME/bin/java" -version 2>&1 | head -n1 | cut -d'"' -f2)
        log_info "Java 버전: $java_version"
    else
        log_warning "Java 17을 찾을 수 없습니다"
        log_info "설치 방법: brew install openjdk@17"
        log_info "시스템 등록: sudo ln -sfn /opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk /Library/Java/JavaVirtualMachines/openjdk-17.jdk"
    fi
}

# Flutter 정리
clean_flutter() {
    log_step "Flutter 캐시 정리"
    
    if [ -d "build" ]; then
        rm -rf build
        log_success "build 폴더 삭제됨"
    fi
    
    flutter clean > /dev/null 2>&1
    log_success "flutter clean 완료"
    
    flutter pub get > /dev/null 2>&1
    log_success "flutter pub get 완료"
    
    # Flutter 호환성 검사
    if command -v flutter >/dev/null 2>&1; then
        flutter analyze --suggestions > /dev/null 2>&1 || true
        log_success "Flutter 호환성 검사 완료"
    fi
}

# 현재 Flutter가 생성하는 기본 Gradle 버전 확인
get_flutter_default_gradle() {
    local temp_dir="/tmp/flutter_gradle_check_$$"
    mkdir -p "$temp_dir"
    cd "$temp_dir"
    
    flutter create temp_project > /dev/null 2>&1
    local default_gradle=""
    
    if [ -f "temp_project/android/gradle/wrapper/gradle-wrapper.properties" ]; then
        default_gradle=$(grep "gradle-.*-all.zip" "temp_project/android/gradle/wrapper/gradle-wrapper.properties" | sed -E 's/.*gradle-([0-9.]+)-all.zip.*/\1/')
    fi
    
    cd - > /dev/null
    rm -rf "$temp_dir"
    
    echo "$default_gradle"
}

# 단계별 Gradle 검증
validate_gradle() {
    log_step "Gradle 환경 검증"
    
    # 1단계: 기본 Gradle 작동 확인 (빠른 체크)
    if [ -f "android/gradlew" ]; then
        cd android
        if ./gradlew tasks --quiet > /dev/null 2>&1; then
            log_success "Gradle 기본 설정 정상"
            cd ..
            return 0
        else
            log_warning "Gradle 기본 설정에 문제 발견"
            cd ..
        fi
    fi
    
    # 2단계: 실제 빌드 호환성 테스트
    log_step "Android 빌드 호환성 테스트 시작"
    
    if show_progress_with_fun "flutter build apk --debug --quiet" "Android 빌드 테스트"; then
        log_success "현재 Gradle 버전으로 빌드 성공!"
        return 0
    else
        log_warning "빌드 실패 - Gradle 버전 조정 필요"
        return 1
    fi
}

# 스마트 Gradle 업데이트
smart_gradle_update() {
    log_step "스마트 Gradle 버전 조정"
    
    local wrapper_props="android/gradle/wrapper/gradle-wrapper.properties"
    
    if [ ! -f "$wrapper_props" ]; then
        log_error "gradle-wrapper.properties 파일을 찾을 수 없습니다"
        return 1
    fi
    
    # 현재 버전 확인
    local current_gradle=$(grep "gradle-.*-all.zip" "$wrapper_props" | sed -E 's/.*gradle-([0-9.]+)-all.zip.*/\1/')
    log_info "현재 Gradle 버전: $current_gradle"
    
    # Flutter 기본 버전 확인
    local flutter_default=$(get_flutter_default_gradle)
    if [ -n "$flutter_default" ]; then
        log_info "Flutter 기본 Gradle 버전: $flutter_default"
        
        # Flutter 기본 버전으로 업데이트
        cp "$wrapper_props" "${wrapper_props}.backup"
        sed -i '' "s|gradle-.*-all\.zip|gradle-${flutter_default}-all.zip|g" "$wrapper_props"
        log_success "Gradle을 Flutter 기본 버전 $flutter_default 로 업데이트"
        
        # 업데이트 후 테스트
        if validate_gradle; then
            return 0
        fi
    fi
    
    # 그래도 실패하면 최신 안정 버전으로
    log_step "최신 안정 버전으로 업데이트 시도"
    sed -i '' 's|gradle-.*-all\.zip|gradle-8.14-all.zip|g' "$wrapper_props"
    log_success "Gradle을 8.14로 업데이트"
    
    return 0
}

# Gradle 정리 및 스마트 업데이트
clean_gradle() {
    log_step "Gradle 완전 정리 및 스마트 업데이트"
    
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
    
    # Gradle 캐시 삭제
    if [ -d "$HOME/.gradle/caches" ]; then
        rm -rf "$HOME/.gradle/caches"
        log_success "전역 Gradle 캐시 삭제됨"
    fi
    
    if [ -d "android/.gradle" ]; then
        rm -rf "android/.gradle"
        log_success "로컬 Gradle 캐시 삭제됨"
    fi
    
    # 단계별 검증 및 업데이트
    if ! validate_gradle; then
        smart_gradle_update
        
        # 최종 검증
        if ! validate_gradle; then
            log_warning "Gradle 설정을 완전히 해결하지 못했습니다"
            log_info "수동으로 Android Studio에서 확인이 필요할 수 있습니다"
        fi
    fi
    
    # gradle.properties 최적화
    local gradle_props="android/gradle.properties"
    if [ -f "$gradle_props" ]; then
        log_step "gradle.properties 최적화"
        
        # 백업 생성
        cp "$gradle_props" "${gradle_props}.backup"
        
        # 기존 최적화 설정 제거
        grep -v "# Flutter Build Fix" "$gradle_props" > "${gradle_props}.tmp" || true
        mv "${gradle_props}.tmp" "$gradle_props"
        
        # 성능 최적화 설정 추가
        {
            echo ""
            echo "# Flutter Build Fix 최적화 설정"
            echo "org.gradle.jvmargs=-Xmx4096m -XX:MaxMetaspaceSize=512m -XX:+HeapDumpOnOutOfMemoryError"
            echo "org.gradle.parallel=true"
            echo "org.gradle.daemon=true"
            echo "org.gradle.configureondemand=true"
            echo "org.gradle.caching=true"
            echo "android.useAndroidX=true"
            echo "android.enableJetifier=true"
        } >> "$gradle_props"
        
        log_success "gradle.properties 최적화 완료"
    fi
}

# iOS 정리
clean_ios() {
    log_step "iOS 환경 정리"
    
    if [ ! -d "ios" ]; then
        log_warning "iOS 폴더가 없습니다. iOS 지원이 없는 프로젝트인 것 같습니다"
        return
    fi
    
    cd ios
    
    # Pods 완전 정리
    if [ -d "Pods" ]; then
        rm -rf Pods
        log_success "Pods 폴더 삭제됨"
    fi
    
    if [ -f "Podfile.lock" ]; then
        rm -f Podfile.lock
        log_success "Podfile.lock 삭제됨"
    fi
    
    # CocoaPods 캐시 정리
    if command -v pod >/dev/null 2>&1; then
        pod cache clean --all 2>/dev/null || true
        log_success "CocoaPods 캐시 정리됨"
        
        # 스마트 Pod 설치 (진행 표시기 포함)
        log_step "CocoaPods 재설치 시작"
        
        # 빠른 방법 먼저 시도
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
    
    # Xcode 캐시 정리
    log_step "Xcode 캐시 정리"
    
    local derived_data="$HOME/Library/Developer/Xcode/DerivedData"
    if [ -d "$derived_data" ]; then
        rm -rf "$derived_data"
        log_success "Xcode DerivedData 삭제됨"
    fi
    
    local archives="$HOME/Library/Developer/Xcode/Archives"
    if [ -d "$archives" ]; then
        find "$archives" -name "*.xcarchive" -mtime +30 -delete 2>/dev/null || true
        log_success "30일 이상된 Xcode Archives 정리됨"
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

# Android 모드
android_mode() {
    echo -e "${GREEN}🤖 Android 모드 시작${NC}"
    echo ""
    
    setup_java17
    clean_flutter
    clean_gradle
    
    echo ""
    log_success "🎉 Android 정리 완료!"
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

# 전체 모드
full_mode() {
    echo -e "${GREEN}🌟 전체 정리 모드 시작${NC}"
    echo ""
    
    setup_java17
    clean_flutter
    clean_gradle
    clean_ios
    test_ios_build
    
    echo ""
    log_success "🎉 전체 정리 완료!"
}

# 메인 함수
main() {
    # macOS 체크
    check_macos
    
    # 헤더 출력
    echo -e "${BLUE}"
    echo "=================================================================="
    echo "    🚀 Flutter 3.32.4 최적화 빌드 수정 스크립트"
    echo "    📱 macOS 전용 | 스마트 Gradle 관리 | v$SCRIPT_VERSION"
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
    log_info "🔗 Repository: https://github.com/$REPO"
}

# 스크립트 실행
main "$@"