# 다이어리 앱 기획 정리

## 앱 개요
- 다이어리처럼 쓸 수 있는 모바일 앱 (개인 사용 목적)
- 핵심 페이지 4개 구성
- 플랫폼: iOS 우선 출시, 추후 Android 추가 예정

## 페이지 구성

### 1. Today Diary 기록
- 게시글 작성 형태
- 휴대폰 앨범 접근 가능
- 즉석 사진 촬영 가능
- 인스타그램 스토리 / Selog 스타일의 짧은 동영상 바로 촬영 기능

### 2. 월간 캘린더 페이지
- 특정 day 클릭 시 해당 날짜의 day diary 등록/조회 가능

### 3. 전체 글 모아보기 (블로그 형식) + 검색/태그 필터링
- 작성했던 전체 글을 블로그 형식으로 모아보는 페이지
- 검색/태그 필터링 기능 포함 (키워드 검색, 태그별/사진별 필터)

### 4. 인사이트(통계) 페이지
- 캘린더 히트맵 (작성 유무 / 감정색 표시)
- 연속 작성일(스트릭) 표시
- 월별 감정 분포 통계
- 자주 쓰는 태그/키워드 워드클라우드 등

## 위젯 (추후 고려 기능으로 보류)
1. Weekly 캘린더 위젯 — 그날의 todolist를 스택 형태로 표시 (추가 구상 필요)
2. 게시된 전체 사진(또는 선택 사진)을 랜덤하게 보여주는 2×2 photo 위젯 (전체/이번 달 옵션 고려)
   - 추가 아이디어: 스트릭 위젯, 오늘 다이어리 한 줄 미리보기 위젯

## 보류 / 추후 고려 사항
- 보안/잠금(생체인증·PIN): 개인 전용 앱이라 초기 버전에서는 제외, 추후 필요 시 추가
- 백업/클라우드 동기화
- 위젯 (위 참고)

## 플랫폼 & 기술 스택 (추천)

**요약: Flutter로 크로스플랫폼 개발, iOS 먼저 출시 → 추후 Android 빌드 추가**

- iOS만 우선 출시하지만 "추후 Android 추가"가 확정 목표이므로, Swift 네이티브로 먼저 만들면 Android 때 사실상 재작성이 필요함. Flutter로 시작하면 UI/로직 코드베이스를 그대로 유지한 채 Android 빌드만 추가하면 됨.

| 영역 | 추천 | 비고 |
|---|---|---|
| 프레임워크 | Flutter (Dart) | 단일 코드베이스로 iOS+Android, 사진/캘린더/차트 생태계 성숙 |
| 상태관리 | Riverpod | 개인 프로젝트 규모에 적합, 러닝커브 낮음 |
| 로컬 DB | Drift (SQLite 기반) | 관계형 태그 구조 + SQLite FTS5로 키워드 검색(3페이지 검색 기능) 구현 용이 |
| 캘린더 UI | table_calendar | 날짜별 마커/데코레이션 지원 → 2페이지, 4페이지 히트맵에 재사용 가능 |
| 카메라/사진 | camera + image_picker | 즉석 촬영, 앨범 접근, 짧은 동영상 녹화 모두 지원 |
| 차트/통계 | fl_chart | 4페이지 감정 분포, 스트릭 그래프 |
| 홈스크린 위젯 (추후) | home_widget 패키지 | Flutter에서 위젯 데이터 동기화 → iOS는 WidgetKit(Swift), Android는 Glance(Kotlin)로 위젯 UI만 네이티브로 별도 작성 |
| 보안/잠금 (추후) | local_auth | Face ID/지문 잠금 필요 시 추가 |

### 대안 비교
- **네이티브(Swift/SwiftUI) 우선**: iOS 품질·위젯 완성도는 최고지만, Android 추가 시 Kotlin/Compose로 사실상 앱을 다시 만들어야 함 → "추후 Android 추가" 목표와는 안 맞음
- **React Native**: Flutter와 비슷한 크로스플랫폼 장점 있으나, 홈스크린 위젯 생태계(home_widget 대응 라이브러리)가 Flutter보다 덜 성숙

## 다음 단계 (Claude Code 스캐폴딩 요청 시 참고)
- Flutter 프로젝트 초기 구조 생성 (flutter create)
- 위 페이지 4개에 대응하는 화면/라우팅 골격
- Drift 스키마: diary_entries, tags, entry_tags, media(photo/video) 테이블
- pubspec.yaml에 riverpod, drift, table_calendar, camera, image_picker, fl_chart 의존성 추가
