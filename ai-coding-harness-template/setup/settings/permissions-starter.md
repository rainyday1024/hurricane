# permissions-starter.md — 권한 allowlist 설계

> `permissions.allow` 를 어떤 문법으로 쓰고, 어느 계층에 두고, 무엇을 절대 넣지 않을지에 대한 규칙.
> 새 도구·새 명령을 상시 허용하기 전에 아래 **위험 등급** 표를 먼저 확인한다.

## 패턴 문법

| 형태 | 예시 | 의미 |
|------|------|------|
| `Tool(명령:*)` | `Bash(git fetch:*)` | 접두 매칭. **재사용성이 가장 높은 형태** |
| `Tool(명령 *)` | `Bash(git worktree *)` | 공백 + `*` 형태도 동작. 한 리포 안에서는 한 표기로 통일 |
| `Tool(<완전한 명령>)` | `Bash(./gradlew check)` | 정확히 일치할 때만 허용 |
| `Read(//<경로>/**)` | `Read(//c/work/<리포>/**)` | 해당 경로 하위 전체 읽기 |
| `WebFetch(domain:<호스트>)` | `WebFetch(domain:docs.claude.com)` | 도메인 단위 |
| `mcp__<서버>__<도구>` | `mcp__playwright__playwright_navigate` | MCP 도구. **괄호 없음** |
| `<툴명>` | `WebSearch` | 인자 없는 툴 전체 허용 |

- **셸이 다르면 툴명도 다르다** — `Bash(...)` 와 `PowerShell(...)` 은 별개 항목. Windows 팀은 두 벌이 필요할 수 있다.
- 경로는 Windows 에서도 POSIX 표기(`//c/...`, `//d/...`)로 쓴다. JSON 이므로 백슬래시는 `\\` 로 이스케이프 — `"PowerShell(.\\gradlew.bat check)"`.
- AI 가 자동으로 추가한 항목에는 정규식 이스케이프(`\(` `\)`)가 섞이기도 한다. **손으로 재현하려 하지 말고 그대로 두거나 지운다.**

## 3계층 분담

| 계층 | 파일 | 넣을 것 |
|------|------|---------|
| 전역 (개인 습관) | `~/.claude/settings.json` | 어느 프로젝트에서나 쓰는 조회 명령 — `git status`·검색·`WebSearch`. **특정 리포의 절대경로 금지** |
| 프로젝트 (팀 공통, git 추적) | `<리포>/.claude/settings.json` | 그 리포의 빌드·테스트·린트, 팀이 공용으로 쓰는 MCP 도구 |
| 로컬 (개인·프로젝트별, git 미추적) | `<리포>/.claude/settings.local.json` | 내 PC 경로, 실험용 명령, 개인 MCP |

- 같은 규칙이 여러 계층에 있으면 **로컬 > 프로젝트 > 전역** 순으로 적용된다 (조직 관리형 설정이 그보다 위).
- `.gitignore` 에 `.claude` 를 통째로 넣으면 **팀 공유 계층이 사라진다.** `.claude/settings.local.json` 만 제외할 것.
- 전역 파일에 특정 리포 경로·세션 임시 경로가 쌓이고 있다면 **계층을 잘못 잡았다는 신호**다. 프로젝트/로컬로 옮긴다.

## 예시 JSON 을 복사할 때

`user-settings.example.json` · `project-settings.example.json` 은 그대로 복사해 쓰는 시드다.
**JSON 은 `<!-- 예: ... -->` 주석을 담지 못하므로** 이 리포의 플레이스홀더 관례가 파일 안에서 작동하지 않는다.
복사 후 다음을 손으로 처리한다.

- `additionalDirectories` — 빈 배열로 두고, 실제로 필요할 때 존재하는 경로만 넣는다.
- `enabledPlugins` · `extraKnownMarketplaces` — **플러그인을 안 쓰면 두 키를 통째로 삭제**한다.
  쓸 거라면 `enabledPlugins` 에 `"<플러그인명>@<마켓플레이스명>": true` 형태로 실제 이름을 채운다.
  없는 플러그인을 선언하거나 쓰지 않는 마켓플레이스를 등록해 두면 조용히 죽은 설정으로 남는다.
- `permissions.allow` 시드는 **자기 환경에서 실제로 쓰는 명령만** 남긴다 (예시의 `gradlew`/`npm` 은 예시일 뿐).

## 위험 등급

| 등급 | 예시 | 판단 |
|------|------|------|
| 무조건 allow | `Bash(git status:*)` · `Bash(git diff:*)` · `Bash(git log:*)` · `Read(...)` · `WebSearch` | 상태를 바꾸지 않는 조회. 막아 봐야 프롬프트만 늘어난다 |
| 프로젝트별 판단 | `Bash(./gradlew check)` · `Bash(npm test)` · `Bash(git commit *)` · DB 조회 MCP | 부작용 범위(빌드 산출물·테스트 DB·커밋 이력)를 팀이 합의한 뒤 **프로젝트 계층**에 |
| 절대 allow 금지 | `Bash(rm *)` · `Bash(git push --force*)` · `Bash(git reset --hard*)` · `Bash(git clean *)` · DDL(`DROP`/`ALTER`) 실행 · 비밀번호·토큰을 인자로 받는 명령 | 되돌릴 수 없거나, 자격증명을 설정 파일에 평문으로 남긴다 |

- 세 번째 등급은 "allow 에 안 넣기"로 끝내지 말고 **`permissions.deny` 에 명시해 기계적으로 차단**한다.
  산문 규칙(→ [`CLAUDE.md`](../../templates/CLAUDE.md) §0)은 읽어야 지켜지지만, `deny` 는 어기는 순간 막힌다.
- 운영 환경을 건드리는 명령(배포·마이그레이션·운영 DB 접속)은 등급과 무관하게 **사람이 직접** 실행한다.

## 운용법 — 손으로 쓰지 말고 승격시킨다

1. **시드만 손으로.** 10~20줄이면 충분하다 (`user-settings.example.json`, `project-settings.example.json`).
2. **프롬프트가 뜰 때 허용.** 그 시점에 해당 계층 파일로 자동 추가된다. 미리 상상해서 채우지 않는다.
3. **주기적으로 승격.** 같은 명령이 정확 매칭으로 여러 줄 쌓였으면 `Bash(git show:*)` 같은 접두 패턴 **1줄로 합친다.**
4. **주기적으로 가지치기.** 세션 임시 경로, 삭제된 워크트리, 1회성 명령은 지운다. 방치하면 수백 줄로 증식하고, 그중 대부분이 죽은 항목이 된다.
5. **`/fewer-permission-prompts`** 스킬이 최근 세션 기록을 훑어 읽기 전용 Bash·MCP 호출을 프로젝트 `.claude/settings.json` 에 우선순위대로 추가해 준다 — 3·4단계의 출발점으로 쓴다.

> 권장: allowlist 는 "설계해서 쓰는 목록"이 아니라 **"쌓인 뒤 정리하는 목록"** 이다.
> 분기마다 한 번 가지치기 + 승격을 하는 것이, 처음부터 완벽하게 쓰려는 것보다 싸고 정확하다.

## additionalDirectories

- 리포 밖 디렉터리(비교용 리포, 워크트리, 스크래치패드) 접근을 허용하는 목록.
- **팀 전원이 동일한 경로를 갖는 경우에만** 프로젝트 계층에 둔다. 내 PC 경로는 로컬 계층.
- 세션 임시 경로·삭제된 워크트리가 특히 잘 남는다. allowlist 와 **같은 주기로** 가지치기한다.

## 자격증명은 규칙에 넣지 않는다

- 허용 규칙에는 **명령 이름까지만** 쓰고 인자를 넣지 않는다. 명령 전체를 허용하는 순간
  인자에 있던 비밀번호·토큰·접속 URL 이 설정 파일에 평문으로 남는다.
- 나머지 규칙(환경변수 주입, 이미 유출된 값의 처리)은 → [`setup/README.md`](../README.md) §자격증명 취급.

## 참고

- Anthropic — 설정 / 권한 공식 문서: <https://code.claude.com/docs/en/settings>
- 어떤 MCP 서버를 어떤 정책으로 쓸지는 [`docs/TOOLS.md`](../../templates/docs/TOOLS.md) 소관. 이 문서는 **허용 문법과 계층**만 다룬다.
