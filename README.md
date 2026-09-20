# ForPotato
reminescence

개인용 다이어리 PWA(Progressive Web App). Flutter로 작성되어 웹으로 빌드되고, 아이폰 Safari에서 "홈 화면에 추가"해서 앱처럼 사용합니다.

**접속**: https://chachapo08.github.io/ForPotato/ (Safari로 접속 후 공유 → 홈 화면에 추가)

## 왜 PWA인가

원래 계획은 Flutter 앱을 iOS로 출시하는 것이었으나, iOS 정식 서명/배포는 Mac 또는 Apple Developer Program($99/년) 가입이 필요해 현재 개발 환경(Mac 미보유)에서는 불가능했습니다. 대신 App Store 심사나 서명 없이 오늘 바로 아이폰에서 쓸 수 있는 PWA로 방향을 잡았습니다. 자세한 배경은 [platform-decision.md](platform-decision.md) 참고. 원래 기능 기획은 [diary-app-spec.md](diary-app-spec.md) 참고.

## 기술 스택

| 영역 | 사용 기술 |
|---|---|
| 프레임워크 | Flutter (web target) |
| 상태관리 | Riverpod (`flutter_riverpod`) |
| 로컬 DB | Drift + `drift_flutter` — 웹에서는 WASM SQLite(`sqlite3.wasm` + `drift_worker.dart.js`, `web/`에 위치)를 IndexedDB/OPFS에 저장 |
| 캘린더 UI | `table_calendar` (날짜 셀을 커스텀 렌더링해서 이모지+숫자 오버레이 표시) |
| 카메라 | `camera`(웹은 `camera_web`이 자동 연결, `getUserMedia`/`MediaRecorder` 사용) — 자체 제작 촬영 화면(`camera_capture_page.dart`)에서 사진/최대 10초 영상 지원 |
| 사진 촬영 미리보기 | `video_player` (촬영한 영상 미리보기용) |
| 앨범 접근 | `image_picker` |
| 통계/차트 | `fl_chart` |
| 폰트/디자인 | `google_fonts` (Gaegu, Gowun Dodum 등으로 "귀엽고 아기자기함" 테마 적용, `main.dart`의 `CuteColors`/`_buildCuteTheme()`) |
| 날짜 포맷 | `intl` |

## 폴더 구조 (`lib/`)

```
lib/
├── main.dart                     # 앱 진입점, 테마(CuteColors), 하단 탭 네비게이션
├── database/
│   ├── database.dart             # Drift 스키마 + 쿼리 메서드
│   └── database.g.dart           # drift_dev가 생성한 코드 (직접 수정 금지)
├── providers/
│   └── database_provider.dart    # AppDatabase의 Riverpod 프로바이더
├── screens/
│   ├── today_diary_page.dart     # 특정 날짜의 글 목록 (Today 탭 + Calendar에서 날짜 선택 시 재사용)
│   ├── entry_edit_page.dart      # 글 작성/수정 화면 (제목/내용/태그/사진/이모지)
│   ├── calendar_page.dart        # 캘린더, 날짜 셀에 이모지+숫자 오버레이
│   ├── blog_list_page.dart       # 전체 글 모아보기 (날짜 + 사진 그리드)
│   ├── insights_page.dart        # 통계 (현재 샘플 데이터 기반, 실제 DB 연동 전)
│   └── camera_capture_page.dart  # 자체 카메라 촬영 화면
└── widgets/
    └── entry_preview_dialog.dart # 글 미리보기 팝업 (화면 중앙, 앱 전체에서 공용으로 사용)
```

## 데이터 모델

- `DiaryEntries`: `id, date, title, content, mood, emoji, createdAt, updatedAt` — 하루에 여러 개 등록 가능 (날짜당 1개 제한 없음)
- `Media`: 사진/동영상을 파일 경로가 아니라 **바이너리(blob)로 직접 DB에 저장** — 웹에는 영속적인 파일시스템이 없어서 이 방식을 택함
- `Tags` / `EntryTags`: 다대다 태그 관계
- `emoji`: 캘린더에 표시할 마커 (하트/별/동그라미 중 선택, 미선택 시 기본 원 모양)

## 로컬 개발

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # database.dart 스키마 변경 시 필요
flutter analyze
flutter test
flutter run -d chrome                                        # 로컬 개발 서버
flutter build web --base-href /ForPotato/                    # 배포용 빌드
```

## 배포

`main` 브랜치에 push하면 `.github/workflows/deploy-web.yml`이 자동으로:
1. `flutter build web --base-href /ForPotato/` 실행
2. 결과물을 `gh-pages` 브랜치에 push
3. GitHub Pages가 `gh-pages`를 서빙 (Settings → Pages에서 소스로 지정해둠)

사람이 수동으로 빌드/배포할 필요 없이, 코드만 `main`에 올리면 몇 분 안에 실제 서비스에 반영됩니다.

## 알려진 제약 / 진행 중인 부분

- **Insights 탭**: 현재 하드코딩된 샘플 데이터로 디자인만 구현됨. 실제 `AppDatabase` 집계 쿼리 연동은 아직 안 함
- **감정(mood) 선택**: 글쓰기 화면에 UI는 있으나 현재 저장은 안 되는 시각적 요소로만 존재 (`DiaryEntries.mood` 컬럼은 있음)
- **Blog 검색/태그 필터**: 검색창 UI만 있고 실제 필터링 로직 미구현
- **오프라인/홈스크린 위젯**: 미구현 (기획서에서도 추후 고려 항목으로 보류)
- PWA 특성상 데이터 영속성을 위해 반드시 "홈 화면에 추가"로 설치해서 사용해야 함 (Safari에서 매번 URL 직접 접속 시 브라우저 데이터 정책상 불안정할 수 있음)
