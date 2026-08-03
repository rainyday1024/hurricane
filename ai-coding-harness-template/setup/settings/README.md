# settings/ — settings.json 스켈레톤

> 어느 JSON 을 어디에 놓는지만 다룬다. 권한 문법·계층·위험 등급은
> [`permissions-starter.md`](permissions-starter.md), 자격증명은 [`setup/README.md`](../README.md) §자격증명 취급.

## 파일 → 목적지

| 이 폴더의 파일 | 복사 목적지 | 성격 |
|----------------|------------|------|
| `user-settings.example.json` | `~/.claude/settings.json` | 개인 전역 — 모델·추론 강도·업데이트 채널·플러그인·어디서나 쓰는 조회 명령 |
| `project-settings.example.json` | `<리포>/.claude/settings.json` | 팀 공통, **git 추적** — 그 리포의 빌드·테스트 명령 |
| (예시 없음) | `<리포>/.claude/settings.local.json` | 개인·프로젝트별, **git 미추적** — 손으로 만들지 않는다. 권한 프롬프트를 허용하면 자동 생성·누적된다 |

로컬 계층의 예시 파일을 두지 않는 이유: 내용 대부분이 그 머신에서만 유효한 경로·일회성 명령이라
시드로 삼을 게 없다. 빈 상태에서 쌓이게 두는 것이 정답이다 (→ permissions-starter.md §운용법).

## 스칼라 키

`user-settings.example.json` 이 쓰는 키와 값 범위:

| 키 | 값 | 비고 |
|-----|-----|------|
| `model` | `"opus"` · `"sonnet"` · `"haiku"` 등 | `"opus[1m]"` 처럼 컨텍스트 변형 표기도 가능 |
| `effortLevel` | `"low"` / `"medium"` / `"high"` / `"xhigh"` | 추론 강도. 복잡한 도메인이면 상위로 |
| `autoUpdatesChannel` | `"latest"` / `"stable"` | |

복사 후 손볼 것(플러그인 2키 삭제 여부 포함)은 → [`permissions-starter.md`](permissions-starter.md) §예시 JSON 을 복사할 때.

## 주의

- JSON 은 주석을 담지 못한다. 예시 파일에 설명이 없는 것은 의도된 것 — 설명은 전부 이 폴더의 `.md` 에 있다.
- 예시를 복사한 뒤 `python -c "import json; json.load(open('<파일>'))"` 한 줄로 유효성을 확인하는 습관을 권장.
