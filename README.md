# 🚀 Flutter Build Fix

[![GitHub release](https://img.shields.io/github/v/release/flutterkage2k/flutter-build-fix?style=for-the-badge&logo=github)](https://github.com/flutterkage2k/flutter-build-fix/releases/latest)
[![Downloads](https://img.shields.io/github/downloads/flutterkage2k/flutter-build-fix/total?style=for-the-badge&logo=github)](https://github.com/flutterkage2k/flutter-build-fix/releases)
[![License](https://img.shields.io/github/license/flutterkage2k/flutter-build-fix?style=for-the-badge)](LICENSE)

Flutter 빌드 에러를 **한 번에 해결**하는 자동화 스크립트예요! Java, Gradle, iOS 관련 문제를 모두 해결합니다.

## ⚡ 빠른 시작

### 🚀 원클릭 설치

```bash
curl -fsSL https://raw.githubusercontent.com/flutterkage2k/flutter-build-fix/main/install.sh -o install.sh && zsh install.sh
```

!!! warning "⚠️ Shell 자동 감지 문제 안내"
    macOS에서는 `sh`가 bash로 실행될 수 있어 zsh 사용자의 `.zshrc`에 alias가 등록되지 않을 수 있습니다.
    따라서 아래와 같이 직접 설치 후 실행하는 방법을 권장합니다:

    ```bash
    curl -fsSL https://raw.githubusercontent.com/flutterkage2k/flutter-build-fix/main/install.sh -o install.sh
    zsh install.sh
    ```

### 💫 바로 사용

```bash
flutter-fix    # 전체 정리 (Android + iOS)
ffand          # Android만
ffios          # iOS만 (macOS)
```

## 🎯 주요 기능

| 기능 | 설명 | 지원 OS |
|------|------|---------|
| ☕ **Java 17 자동 설정** | Java 17 자동 감지 및 환경변수 설정 | macOS, Linux |
| 🧹 **Flutter 캐시 정리** | `flutter clean`, `flutter pub get` 자동 실행 | 모든 OS |
| 🛠️ **Gradle 정리** | Android 빌드 캐시 및 daemon 정리 | 모든 OS |
| 📱 **iOS Pods 재설치** | CocoaPods 완전 정리 및 재설치 | macOS |
| 🍎 **Xcode 캐시 정리** | DerivedData 폴더 삭제 | macOS |
| 🔔 **자동 업데이트 알림** | 새 버전 출시 시 자동 알림 | 모든 OS |

## 📋 사용법

### 🎯 3가지 실행 모드

```bash
# 전체 정리 (가장 많이 사용)
flutter-fix

# Android 문제만 해결
ffand

# iOS 문제만 해결 (macOS)
ffios

# 도움말
flutter-fix --help
```

### 💡 언제 사용하면 좋을까요?

- 🆕 **새 Flutter 프로젝트 시작 전**
- 🔄 **오랫동안 작업하지 않은 프로젝트 재개 시**
- ❌ **이상한 빌드 에러 발생 시**
- 🛠️ **Gradle이나 Pods 관련 문제가 생겼을 때**
- ⚡ **"Starting a Gradle Daemon" 에러 발생 시**

## 📍 설치 정보

### 자동 설치 시
- **설치 위치**: `~/.flutter-tools/flutter_build_fix.sh`
- **지원 Shell**: `zsh`, `bash`, `fish` 자동 감지
- **설정 파일**: 각 Shell에 맞는 설정 파일에 자동 추가
  - `zsh`: `~/.zshrc` 
  - `bash`: `~/.bashrc` 또는 `~/.bash_profile`
  - `fish`: `~/.config/fish/config.fish`

### 설치 후 확인
```bash
# 새 터미널을 열거나
source ~/.zshrc    # zsh 사용자
source ~/.bashrc   # bash 사용자

# 설치 확인
flutter-fix --help
```

## 🔄 업데이트

```bash
# 동일한 설치 명령어로 최신 버전 업데이트
curl -fsSL https://raw.githubusercontent.com/flutterkage2k/flutter-build-fix/main/install.sh -o install.sh && zsh install.sh
```

## 🛠️ 수동 설치

```bash
# 1. 설치 디렉토리 생성
mkdir -p ~/.flutter-tools

# 2. 최신 버전 다운로드
curl -fsSL https://raw.githubusercontent.com/flutterkage2k/flutter-build-fix/main/flutter_build_fix.sh \
  -o ~/.flutter-tools/flutter_build_fix.sh

# 3. 실행 권한 부여
chmod +x ~/.flutter-tools/flutter_build_fix.sh

# 4. alias 설정 (Shell에 맞게 선택)
# zsh 사용자
echo 'alias flutter-fix="$HOME/.flutter-tools/flutter_build_fix.sh --full"' >> ~/.zshrc
echo 'alias ffand="$HOME/.flutter-tools/flutter_build_fix.sh --android"' >> ~/.zshrc
echo 'alias ffios="$HOME/.flutter-tools/flutter_build_fix.sh --ios"' >> ~/.zshrc
source ~/.zshrc

# bash 사용자
echo 'alias flutter-fix="$HOME/.flutter-tools/flutter_build_fix.sh --full"' >> ~/.bashrc
echo 'alias ffand="$HOME/.flutter-tools/flutter_build_fix.sh --android"' >> ~/.bashrc
echo 'alias ffios="$HOME/.flutter-tools/flutter_build_fix.sh --ios"' >> ~/.bashrc
source ~/.bashrc
```

## 🎯 실제 사용 예시

### 빌드 에러 해결

```bash
# 빌드 에러 발생
flutter run # ❌ 에러 발생

# 한 번에 해결
flutter-fix

# 다시 빌드
flutter run # ✅ 정상 작동
```

### 새 프로젝트 시작

```bash
# 프로젝트 생성
flutter create my_awesome_app
cd my_awesome_app

# 환경 최적화
flutter-fix

# 개발 시작
flutter run
```

## 🆘 문제 해결

### 자주 발생하는 문제

#### `curl` 명령어 실행 안됨
```bash
# wget 사용
wget -qO- https://raw.githubusercontent.com/flutterkage2k/flutter-build-fix/main/install.sh | sh
```

#### `flutter-fix` 명령어를 찾을 수 없음
```bash
# Shell 확인
echo $SHELL

# Shell별 설정 파일 다시 로드
source ~/.zshrc    # zsh 사용자
source ~/.bashrc   # bash 사용자
source ~/.config/fish/config.fish  # fish 사용자

# 또는 새 터미널 열기
```

#### Java 17을 찾을 수 없음 (macOS)
```bash
# Homebrew로 Java 17 설치
brew install openjdk@17

# 시스템에 등록
sudo ln -sfn /opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk /Library/Java/JavaVirtualMachines/openjdk-17.jdk
```

#### 다른 Shell 사용하는 경우
```bash
# 현재 Shell 확인
echo $SHELL

# 수동으로 alias 추가
nano ~/.zshrc      # zsh
nano ~/.bashrc     # bash
nano ~/.config/fish/config.fish  # fish
```

## 🗑️ 제거

```bash
# 스크립트 파일 삭제
rm -rf ~/.flutter-tools

# alias 제거 (Shell에 맞게 선택)
# zsh
sed -i '' '/flutter-fix\|ffand\|ffios/d' ~/.zshrc
source ~/.zshrc

# bash  
sed -i '/flutter-fix\|ffand\|ffios/d' ~/.bashrc
source ~/.bashrc

# fish
sed -i '/flutter-fix\|ffand\|ffios/d' ~/.config/fish/config.fish
```

## 🤝 기여하기

- 🐛 **버그 리포트**: [Issues](https://github.com/flutterkage2k/flutter-build-fix/issues)
- 💡 **기능 제안**: [Discussions](https://github.com/flutterkage2k/flutter-build-fix/discussions)
- ⭐ **Star**: 도움이 되셨다면 Star를 눌러주세요!
- 🔄 **Pull Request**: 개선사항이 있으시면 PR을 보내주세요

## 📚 자세한 문서

더 자세한 사용법과 문제 해결 방법은 [공식 문서](https://flutterkage2k.github.io/mkdocspdflutterguide/)를 참고하세요.

## 📄 라이선스

이 프로젝트는 [MIT 라이선스](LICENSE) 하에 배포됩니다.

---

**Author**: Heesung Jin (kage2k)  
**Repository**: https://github.com/flutterkage2k/flutter-build-fix