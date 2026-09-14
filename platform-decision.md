# 플랫폼 결정: Flutter 네이티브 앱 → PWA 전환

## 배경

`diary-app-spec.md`의 원래 계획은 Flutter로 iOS 우선 출시(추후 Android 추가)였다. 실제 개발 환경(Windows PC, Mac 미보유, iPhone 사용자)에서 이 계획을 실행하는 과정에서 iOS 빌드/배포 관련 기술적 제약을 확인했고, 그 결과 **PWA(Progressive Web App) 방식으로 전환**하기로 결정했다.

## 확인된 기술적 제약사항

### 1. iOS 컴파일은 macOS + Xcode 없이는 원천적으로 불가능
- iOS 네이티브 바이너리 컴파일(clang/링커)과 코드 서명(codesign)은 Xcode 도구체인에 종속되어 있고, Xcode는 macOS 전용으로만 배포된다.
- `flutter build ios`도 내부적으로 `xcodebuild`를 직접 호출하므로 Windows/Linux에서는 실행 자체가 안 된다.

### 2. 코드 서명 정책이 Mac 유무와 무관하게 유료 가입을 요구
- **무료 Apple ID (Personal Team)**: Xcode가 실행 중인 Mac에 iPhone을 케이블로 직접 연결한 "그 순간"에만 발급되는 로컬 개발용 인증서. 유효기간 7일, 기기 연결 없이는 원격/자동 발급이 불가능.
- **Ad Hoc / TestFlight 배포용 인증서**: Mac 소유 여부와 무관하게 **Apple Developer Program($99/년, 연 단위 결제만 존재, 월 구독 없음)** 가입자에게만 발급된다.
- 즉 "Mac이 있어서 무료로 정식 배포한다"는 경로 자체가 없다 — Mac 사용자도 정식 배포(TestFlight 등)를 하려면 동일하게 유료 가입이 필요하다. Mac이 있으면 얻는 이득은 "로컬 테스트 설치를 무료로 할 수 있다"는 것뿐이며, 이마저 7일마다 재연결이 필요하다.

### 3. 클라우드 CI(Codemagic, GitHub Actions macOS runner)도 유료 가입을 우회하지 못함
- 이들 서비스는 실제 Apple 하드웨어를 클라우드에서 빌려주는 방식이라 Mac 없이도 빌드 자체는 가능하다.
- 하지만 무인 자동 서명에 필요한 **App Store Connect API 키**는 Apple Developer Program 가입자만 발급받을 수 있어, 결국 동일한 $99/년 관문에 부딪힌다.

### 4. AltStore/SideStore(Windows 사이드로딩 도구)도 근본 해결책은 아님
- Xcode 없이 Windows에서 아이폰에 사이드로드 가능하지만, 내부적으로 동일한 "무료 개인 인증서" 메커니즘을 사용하므로 7일 만료 문제가 그대로 남는다.

### 5. Hackintosh / macOS 가상머신은 정책 위반
- Apple의 macOS 소프트웨어 라이선스 계약은 Apple 브랜드 하드웨어에서만 실행을 허용한다. 기술적으로는 가능하나 라이선스 위반이며, 업데이트마다 불안정해지는 실용적 문제도 있어 채택하지 않음.

### 6. Android는 완전히 다른 조건이지만, 아이폰 사용자에게는 무의미
- Android는 자체 생성한 키스토어로 서명(유효기간 수십 년, 사실상 영구), 사이드로딩에 등록/승인 절차 자체가 없음. 실제로 Windows 환경에서 Android SDK를 구성해 `app-debug.apk` 빌드까지 성공적으로 검증했다.
- 그러나 **APK와 IPA는 완전히 다른 바이너리 포맷**이라 Android용으로 빌드해도 iPhone에는 설치할 수 없다. 사용자가 iPhone 사용자이므로 Android 빌드는 현재 목적에 도움이 되지 않는다.

## 결론: PWA로 전환

Mac 미보유 + iPhone 전용 사용자라는 조건에서, 반복 비용/번거로움 없이 아이폰에서 쓸 수 있는 유일한 현실적 경로는 **모바일 웹앱(PWA)**이다.

- Apple의 서명/심사/인증서 절차가 전혀 필요 없음 (그냥 웹사이트이므로)
- Safari에서 접속 후 "홈 화면에 추가"하면 아이콘이 생기고 전체화면 앱처럼 동작
- $99/년, Mac, 7일 만료 문제 모두 해소
- 기존에 작성한 Flutter 코드(캘린더, 통계, 상태관리, UI)의 대부분을 그대로 재사용 가능 (`flutter build web`로 컴파일)

### 이번 전환으로 변경된 프로젝트 구성

- **데이터베이스 계층**: `dart:io` 기반 `NativeDatabase`(네이티브 파일시스템 직접 접근)에서 `drift_flutter` 패키지의 `driftDatabase()` 헬퍼로 교체. 웹에서는 WASM SQLite(`sqlite3.wasm` + `drift_worker.dart.js`, `web/` 폴더에 배치)를 사용하도록 설정 (`lib/database/database.dart`).
- **카메라/사진 기능**: `camera`, `image_picker` 패키지에 이미 포함된 웹 호환 컴패니언 패키지(`camera_web`, `image_picker_for_web`)를 활용해 구현 예정.
- **배포 방식**: 앱스토어/TestFlight 대신 `flutter build web` 결과물(`build/web`)을 정적 호스팅(GitHub Pages/Netlify/Vercel 등)에 올려 URL로 접근.

### PWA 방식의 한계 (인지하고 있는 트레이드오프)

- 홈스크린 위젯 구현 불가 — 원래 기획서에서도 "추후 고려"로 이미 보류된 항목이라 현재 영향 없음.
- 백그라운드 동작/푸시 알림이 네이티브 대비 제한적 (iOS 16.4+부터 부분 지원).
- 데이터 영속성을 보장하려면 반드시 "홈 화면에 추가"로 설치해야 함 (Safari에서 매번 URL로 접속하는 방식은 브라우저 데이터 정책상 불안정할 수 있음).
