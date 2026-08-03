# 프로파일 — 사내 SI 레거시 웹 업무 시스템 (2026-08-03 스냅샷)

> 이 템플릿을 실제로 적용한 환경 **1건의 실측 스냅샷**. 템플릿도 정본도 아니다 —
> "다 채워 쓰면 실물이 어떻게 생기는가"를 보여주는 사례이자, 새 PC 복원 시의 체크리스트다.
> 2026-08-03 측정치이며 이후 환경과 어긋날 수 있다. 갱신은 재측정할 때만.
> **대상 시스템은 익명화했다** — 제품명·업무 도메인·사내 경로·호스트·계정은 전부 일반화하거나
> 플레이스홀더로 치환했다. 공개 리포에 특정 시스템의 보안 상태를 남기지 않기 위한 것이며,
> 자기 환경을 익명화하지 않고 기록하려면 `*.private.md` 로 두어 git 추적에서 제외한다 (→ `.gitignore`).

## 대상 프로젝트

- **`<프로젝트 A>`** — 사내 SI 레거시 웹 업무 시스템. 다년차 유지보수 단계.
- 스택 한 줄: **JVM 계열 웹 프레임워크 + ORM + 서버사이드 템플릿 엔진 + 관계형 DB** / Gradle 빌드.
- 업무 모듈 수십 개, 같은 역할의 UI 라이브러리 2종 공존, 테스트 0개.
- 문서 레이어가 먼저 자리 잡았고, 환경 레이어는 설계 없이 뒤늦게 자연 증식했다.

## 전역 설정 — `~/.claude/settings.json`

최상위 키 **6개**가 전부다. 사람이 손으로 관리하는 값은 사실상 아래 스칼라 4줄 + 플러그인 2키.

```json
{
  "model": "opus[1m]",
  "effortLevel": "xhigh",
  "autoUpdatesChannel": "latest",
  "enabledPlugins": { "figma@claude-plugins-official": true, "discord@claude-plugins-official": true },
  "extraKnownMarketplaces": {
    "claude-plugins-official": { "source": { "source": "github", "repo": "anthropics/claude-plugins-official" } } },
  "permissions": { "allow": [ "<207개 — 아래 참조>" ], "additionalDirectories": [ "<1개>" ] }
}
```

`hooks` · `statusLine` · `outputStyle` · `env` · `permissions.deny` · `permissions.ask` — **전부 없음**.

## 권한 3계층 실측

| 파일 | allow | additionalDirectories |
|------|-------|------------------------|
| `~/.claude/settings.json` (전역) | 207 | 1 |
| `<repo>/.claude/settings.json` (프로젝트) | 16 | 1 |
| `<repo>/.claude/settings.local.json` (개인) | 194 | 16 |

- **숫자보다 중요한 사실**: 읽는 도중 204 → 207로 늘었다. 관리되는 설정이 아니라 **자동 누적 로그**다.
- 전역 207건 중 **186건(90%)이 일회성 정확 명령**. 재사용 패턴(`Bash(git fetch:*)`, `Read(//<repo>/**)`,
  `WebFetch(domain:<host>)`, `mcp__<server>__<tool>`)은 21건뿐이고 죽은 경로도 섞여 있다.
  세 파일 간 중복은 1건 — 분업이 아니라 "그때 열려 있던 파일"에 임의로 붙은 결과다.
- `additionalDirectories` 는 개인 파일 16건이 주력 — 정본 리포 · 다른 DB 로 포팅한 비교 리포 · 기능 브랜치 폴더 ·
  별도 워크스페이스 · 이 템플릿 리포까지 **5개 리포 교차참조**용. 단 죽은 경로가 4건 섞여 있었다.
- **팀 공유 계층은 죽어 있다** — `.gitignore` 가 `.claude` 를 통째 무시해 `.claude/settings.json` 이 추적 안 됨.
  반면 `CLAUDE.md` 와 `claude-docs/` 는 선등록되어 공유 중. 즉 **문서는 공유, 환경은 개인 소유**.

## MCP 4종

| 서버 | transport | 스코프 | 용도 |
|------|-----------|--------|------|
| `oracle` | stdio — `<sqlcl 설치경로>\bin\sql.exe -mcp` | 프로젝트 | 개발 DB 직접 조회 (스키마·데이터 확인) |
| `playwright` | stdio — `npx @executeautomation/playwright-mcp-server` | 전역 | UI 검증 (화면 렌더·클릭·스크린샷) |
| `figma-remote-mcp` | http — `https://mcp.figma.com/mcp` | 프로젝트 | 디자인 시안 참조 |
| `<pg-server>` | stdio — `@modelcontextprotocol/server-postgres` | 다른 프로젝트 | 비교용 PostgreSQL 리포 |

- 등록 실물은 `~/.claude.json` (최상위 `mcpServers` = 전역 / `projects["<절대경로>"].mcpServers` = 프로젝트).
  이 파일은 설정이 아니라 **클라이언트 상태 저장소**라 통째 복사 금지 — `claude mcp add` 로 재등록한다.
- **일반 교훈**: 접속 URL 을 인자로 받는 유형의 DB MCP(`<user>:<password>@<db-host>` 형태의 URL 을 `args` 로 전달)는
  구조상 설정 파일에 평문이 남기 쉽다. 같은 문자열이 권한 규칙에도 따라 들어간다.
  이런 서버는 처음부터 `${환경변수}` 참조로 등록한다 (→ [`setup/README.md`](../setup/README.md) §자격증명 취급).
- Windows 함정: `projects` 키가 대소문자·슬래시 방향까지 구분하는 리터럴이라 같은 디렉터리가 3가지 표기로
  중복 등록됐다(실 프로젝트 4개 → 엔트리 10개). 표기가 다르면 MCP가 안 붙는다.
- 사용 정책은 [`docs/TOOLS.md`](../templates/docs/TOOLS.md) 소관. 여기는 등록 현황만.

## 문서 하네스 — 루트 2 + `claude-docs/` 13

| 문서 | 역할 |
|------|------|
| `CLAUDE.md` | 진입점. 운영 절대 규칙 6개 + 스택 표 + 명령어 + 구조 (75줄) |
| `AGENTS.md` | 업무 지침 Quick Reference (≤60줄) |
| `ARCHITECTURE.md` | 레이어(web/service/impl)·모듈 경계·금지 패턴 |
| `PLAN_SYSTEM.md` | 비단순 작업의 plan 작성 절차 |
| `FEEDBACK_LOOPS.md` | 검증 자동화 현황 — 실질적으로 "없음"의 기록 |
| `GIT_WORKFLOW.md` | 브랜치·커밋·커밋 제외 변경(로컬 전용 설정) |
| `UI_VALIDATION.md` | 화면 변경 검증 절차 (Playwright MCP 전제) |
| `SECURITY.md` | 보안 규칙 |
| `TOOLS.md` | MCP 사용 규칙 |
| `FRONTEND.md` | 레거시/신규 자산 2계열 구분, 공통 스크립트 규약 |
| `<그리드 A>_GUIDE.md` | 기본 그리드 라이브러리 |
| `<그리드 B>_GUIDE.md` | 특정 모듈 전용 그리드 라이브러리 |
| `DOC_GARDENING.md` | 문서 거버넌스 (메타) |
| `HARNESS_BUILD_GUIDE.md` | 하네스 구축 방법론 — 이 템플릿 리포의 원본 |
| `product-specs/index.md` | 도메인 카탈로그 |

> 표준 세트 위에 스택 특화 3개(`FRONTEND`·`GRID_GUIDE`·`SLICKGRID_GUIDE`)가 얹힌 형태.

## 영속 메모리 — 27 파일

`~/.claude/projects/<슬러그>/memory/` 에 `MEMORY.md` 인덱스 1 + 노트 26.
유형별: **project 16 / reference 7 / feedback 2 / user 1**.

값어치가 컸던 노트를 성격으로 일반화하면 다음 4종이다. 공통점은 **코드를 읽어서는 알 수 없는 것**이라는 점.

- **조용한 실패 함정** — 문법은 맞는데 아무 일도 안 일어나는 규칙(속성에 괄호를 빼면 no-op). 에러가 안 나
  매번 처음부터 다시 디버깅하게 된다. 한 줄 메모로 반복 손실이 끝났다.
- **빌드 산출물 다중 사본** — 리소스가 3벌로 출력돼 편집본이 무시되던 문제. 툴체인 특유의 배치 사실.
- **같은 이름 상반된 관례 공존** — 동일 컴포넌트가 두 계열로 갈려 섞으면 즉시 깨진다. 아키텍처 문서에 쓰기엔 지엽적.
- **정본이 어디냐** — 어느 브랜치·어느 폴더가 진짜 작업본인지. 리포 어디에도 안 적힌 조직 지식.

> 교훈: 남길 가치가 있는 것은 "재조사 비용이 큰데 코드에 안 적힌 사실"뿐. 열면 5초에 아는 것은 남기지 않는다.

## 도입하지 않은 것 (있는 척 금지 — [GUIDE.md](../GUIDE.md) §6)

| 항목 | 현 상태 | 사유 |
|------|---------|------|
| hooks | 0개 | 필요를 산문 규칙으로 대체 중. `CLAUDE.md` §0.5 "매 작업 시작 시 설정 확인"이 대표적 — 정확히 hook 이 할 일 |
| 커스텀 슬래시 커맨드 / 스킬 | 0개 | 반복 절차(검증 명령 → 리소스 동기화 → 하드새로고침)가 메모리 노트로만 존재 |
| 커스텀 서브에이전트 | 0개 | 필요 인지 못 함 |
| `permissions.deny` | 0개 | 위험 명령 차단이 `CLAUDE.md` 산문 규칙에만 있고 **기계적 강제가 전혀 없음** |
| 테스트 스위트 | 0개 | 레거시. `check`/`build` 는 사실상 컴파일 검증 |
| 정적분석 · CI/PR 검증 | 없음 | 레거시 대량 위반 부담 / 배포는 수동 운용 |
| `.mcp.json` (팀 공유 MCP) | 미사용 | 존재는 확인했으나 이 환경에 파일이 없어 미검증 |

## 실제로 효과가 컸던 것 top 3

1. **`CLAUDE.md` §0 운영 절대 규칙 6개** — PR·push·파일삭제·`--no-verify` 금지. 강제력 없는 산문인데도
   실효가 컸다. 근거: 도입 후 의도치 않은 push·삭제 0건. 6줄 투자 대비 최대 효과.
2. **영속 메모리 26 노트** — 여러 세션에 걸쳐 반복 발견되던 위 4종 함정이 등록 이후 재조사 0건.
3. **`additionalDirectories` 멀티 워크스페이스** — 정본 / 다른 DB 포팅본 / 기능 브랜치를 한 세션에서
   같이 읽는다. 근거: DB 방언 이식이 파일 복사 왕복 없이 끝난다.

> 반대로 **효과가 없었던 것**: `permissions.allow` 를 손으로 늘리는 일. 90%가 일회성이라 다음 세션에 안 맞는다.

## 다음에 할 것

- [ ] **SessionStart hook** — `CLAUDE.md` §0.5 의 로컬 개발 설정 확인을 산문에서 hook 으로 이관.
- [ ] **`permissions.deny`** — force push · 재귀 삭제 등 산문 금지 규칙을 기계적 차단으로 승격.
- [ ] **allow 가지치기** — 일회성 186건 폐기, 재사용 패턴만 전역에 남기고 프로젝트 고유는 프로젝트 파일로.
- [ ] **`.claude/settings.json` 추적 전환** — `.gitignore` 가 `settings.local.json` 만 무시하게 바꿔 공유 계층 복구.
- [ ] **자격증명 분리 + 슬래시 커맨드 1개** — MCP `args` 평문 URL을 환경변수로, 최다 반복 절차를 커맨드로.
