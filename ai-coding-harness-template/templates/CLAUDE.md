# CLAUDE.md — <프로젝트명> 실행 가이드

> 새 세션의 첫 읽기 대상. AI 에이전트는 작업 시작 전 반드시 이 문서를 읽는다.
> 세부 지침은 `AGENTS.md` 및 `docs/` 하위 문서에서 찾을 것.
>
> <!-- 이 문서는 "안정 문서(앵커)"다. 60~120줄로 유지하고, 디테일은 docs/ 로 보낸다. -->

---

## 0. 운영 규칙 (절대 위반 금지)

- **PR 생성 금지** — 사용자가 명시적으로 지시한 경우에만 Commit, PR 생성. 자동 push 금지.
- **추측 금지, 질문 우선** — 요청이 모호하면 추측해서 진행하지 말고 반드시 확인 질문.
- **임의 파일 삭제 금지** — `rm`, `Remove-Item`, `git clean`, `git reset --hard` 류는 사용자 승인 후에만.
- **커밋 검증 우회 금지** — pre-commit hook 등을 `--no-verify` 로 건너뛰지 않는다. 실패 시 원인을 고친다.
- **force push 금지** — 명시적 지시 없으면 절대 안 됨.
- **민감 파일 커밋 금지** — `.env`, 인증서, 설정 파일의 암호 평문 등.

<!-- 로컬 개발 전용으로 커밋하면 안 되는 파일/설정이 있으면 여기(§0.5)에 명시.
     예: 핫리로드/디버그 설정처럼 추적 대상이지만 로컬에서만 켜는 값. GIT_WORKFLOW.md "커밋 제외 변경" 참고. -->

## 1. 프로젝트 개요

<한 문단으로: 이 프로젝트가 무엇을 하는 시스템인지>

| 항목 | 값 |
|------|-----|
| 프레임워크 | <예: Spring Boot 3.x + MVC> |
| 언어 | <예: Java 17 / TypeScript 5.x> |
| 빌드 | <예: Gradle / npm / Maven> |
| 패키징 | <예: jar / war / docker image> |
| DB | <예: PostgreSQL 16> |
| ORM / 쿼리 | <예: MyBatis / Prisma / JPA> |
| 템플릿 / 프론트 | <예: React / Pebble / Thymeleaf> |
| 보안 | <예: Spring Security (세션 기반)> |
| 진입점 | <예: src/main/java/.../Application.java> |

## 2. 자주 쓰는 명령어

```bash
# 빠른 검증 (작업 중 반복) — <이 명령이 실제로 무엇을 검증하는지 한 줄>
<빠른 검증 명령>          # 예: ./gradlew check / npm run lint && tsc

# 완료 검증 (완료 기준 / 최종 확인)
<완료 검증 명령>          # 예: ./gradlew build / npm run build && npm test

# 실행 / 기동
<실행 명령>              # 예: ./gradlew bootRun / npm run dev
```

## 3. 디렉터리 구조 (요지)

```
<프로젝트명>/
├── CLAUDE.md              # ← 이 문서. 운영 규칙 + 진입점
├── AGENTS.md              # 업무 지침서 (Quick Reference)
├── docs/                  # 하네스 문서 (ARCHITECTURE / PLAN_SYSTEM / ...)
└── <소스 루트>/           # <핵심 하위 디렉터리를 3~6줄로>
```

## 4. 아키텍처 / 도메인

- 아키텍처 규칙: `docs/ARCHITECTURE.md`
- 도메인 카탈로그: `docs/product-specs/index.md`

## 5. 작업 흐름 (간단히)

1. **읽기** — `CLAUDE.md` → `AGENTS.md` → 관련 `docs/`
2. **계획** — 단순하지 않은 작업은 `docs/PLAN_SYSTEM.md` 절차에 따라 plan 작성
3. **검증** — 작업 중 빠른 검증 반복, **완료 시 완료 검증 통과** + UI는 `docs/UI_VALIDATION.md` 절차
4. **반영** — `docs/GIT_WORKFLOW.md` 규칙 (PR/머지는 사용자가 직접)

---

> **주의**: 이 문서는 60~120줄 수준으로 유지. 늘어나는 디테일은 `docs/` 하위로 이전한다.
