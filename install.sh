#!/usr/bin/env bash

# =============================================================================
# Flutter Build Fix 자동 설치 스크립트
# 
# Repository: https://github.com/flutterkage2k/flutter-build-fix
# Author: Heesung Jin (kage2k)
# =============================================================================

set -e

# 색상 설정
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 설정
REPO="flutterkage2k/flutter-build-fix"
INSTALL_DIR="$HOME/.flutter-tools"
SCRIPT_NAME="flutter_build_fix.sh"
SCRIPT_URL="https://github.com/$REPO/releases/latest/download/$SCRIPT_NAME"

log_info()    { echo -e "${BLUE}ℹ️  $1${NC}"; }
log_success() { echo -e "${GREEN}✅ $1${NC}"; }
log_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
log_error()   { echo -e "${RED}❌ $1${NC}"; }

detect_shell() {
    if [ -n "$ZSH_VERSION" ]; then
        echo "zsh"
    elif [ -n "$BASH_VERSION" ]; then
        echo "bash"
    else
        echo "sh"
    fi
}

get_shell_rc() {
    local shell_type=$(detect_shell)
    case $shell_type in
        zsh) echo "$HOME/.zshrc" ;;
        bash) echo "$HOME/.bashrc" ;;
        *) echo "$HOME/.profile" ;;
    esac
}

check_dependencies() {
    log_info "의존성 확인 중..."
    
    if ! command -v curl >/dev/null 2>&1; then
        if command -v wget >/dev/null 2>&1; then
            log_warning "curl이 없어서 wget을 사용합니다"
            USE_WGET=true
        else
            log_error "curl 또는 wget이 필요합니다"
            exit 1
        fi
    fi
}

download_script() {
    log_info "Flutter Build Fix 스크립트 다운로드 중..."
    
    # 설치 디렉토리 생성
    mkdir -p "$INSTALL_DIR"
    
    # 스크립트 다운로드
    if [ "$USE_WGET" = true ]; then
        if ! wget -q "$SCRIPT_URL" -O "$INSTALL_DIR/$SCRIPT_NAME"; then
            log_error "다운로드 실패: $SCRIPT_URL"
            exit 1
        fi
    else
        if ! curl -fsSL "$SCRIPT_URL" -o "$INSTALL_DIR/$SCRIPT_NAME"; then
            log_error "다운로드 실패: $SCRIPT_URL"
            log_info "GitHub Releases에 파일이 있는지 확인해주세요"
            exit 1
        fi
    fi
    
    # 실행 권한 부여
    chmod +x "$INSTALL_DIR/$SCRIPT_NAME"
    log_success "스크립트 다운로드 완료: $INSTALL_DIR/$SCRIPT_NAME"
}

setup_aliases() {
    log_info "alias 설정 중..."
    
    local shell_rc=$(get_shell_rc)
    
    # 백업 생성
    if [ -f "$shell_rc" ]; then
        cp "$shell_rc" "${shell_rc}.backup.$(date +%Y%m%d_%H%M%S)"
    fi
    
    # 기존 flutter-fix 관련 alias 제거
    if [ -f "$shell_rc" ]; then
        sed -i.bak '/# Flutter Build Fix aliases/d' "$shell_rc" 2>/dev/null || true
        sed -i.bak '/alias flutter-fix=/d' "$shell_rc" 2>/dev/null || true
        sed -i.bak '/alias ffand=/d' "$shell_rc" 2>/dev/null || true
        sed -i.bak '/alias ffios=/d' "$shell_rc" 2>/dev/null || true
        rm -f "${shell_rc}.bak" 2>/dev/null || true
    fi
    
    # 새 alias 추가
    cat >> "$shell_rc" << EOF

# Flutter Build Fix aliases
alias flutter-fix="$INSTALL_DIR/$SCRIPT_NAME --full"
alias ffand="$INSTALL_DIR/$SCRIPT_NAME --android"
alias ffios="$INSTALL_DIR/$SCRIPT_NAME --ios"
EOF
    
    log_success "alias 설정 완료: $shell_rc"
}

show_completion_message() {
    echo ""
    log_success "🎉 Flutter Build Fix 설치 완료!"
    echo ""
    echo -e "${BLUE}📋 사용법:${NC}"
    echo "  flutter-fix    # 전체 정리 (Android + iOS)"
    echo "  ffand          # Android만"
    echo "  ffios          # iOS만 (macOS)"
    echo ""
    echo -e "${YELLOW}💡 주의사항:${NC}"
    echo "  - 새 터미널을 열거나 다음 명령어를 실행하세요:"
    echo "    source $(get_shell_rc)"
    echo ""
    echo -e "${GREEN}🔄 업데이트:${NC}"
    echo "  curl -fsSL https://raw.githubusercontent.com/$REPO/main/install.sh | bash"
    echo ""
    echo -e "${BLUE}📚 자세한 사용법:${NC}"
    echo "  https://github.com/$REPO"
}

verify_installation() {
    log_info "설치 확인 중..."
    
    if [ -f "$INSTALL_DIR/$SCRIPT_NAME" ] && [ -x "$INSTALL_DIR/$SCRIPT_NAME" ]; then
        log_success "스크립트 설치 확인됨"
        
        # 버전 정보 표시 (스크립트에 버전 정보가 있다면)
        local version=$("$INSTALL_DIR/$SCRIPT_NAME" --version 2>/dev/null || echo "설치됨")
        log_info "버전: $version"
    else
        log_error "설치 확인 실패"
        exit 1
    fi
}

check_flutter() {
    if command -v flutter >/dev/null 2>&1; then
        local flutter_version=$(flutter --version 2>/dev/null | head -n1 | cut -d' ' -f2 || echo "알 수 없음")
        log_info "Flutter 버전: $flutter_version"
    else
        log_warning "Flutter가 설치되지 않았습니다"
        log_info "Flutter 설치: https://docs.flutter.dev/get-started/install"
    fi
}

main() {
    echo -e "${BLUE}"
    echo "=================================================================="
    echo "    Flutter Build Fix 자동 설치 스크립트"
    echo "    Repository: https://github.com/$REPO"
    echo "    Author: Heesung Jin (kage2k)"
    echo "=================================================================="
    echo -e "${NC}"
    
    check_dependencies
    check_flutter
    download_script
    setup_aliases
    verify_installation
    show_completion_message
}

# 스크립트 실행
main "$@"