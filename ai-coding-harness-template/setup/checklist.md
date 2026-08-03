# checklist.md — 새 환경 세팅 순서

> 새 PC 또는 새 프로젝트에서 Claude Code 환경을 세우는 순서. 위에서부터 그대로 따라간다.
> 각 단계의 상세 근거는 `→ 상세` 링크에, 전체 이식 범위는 [README.md](README.md) 에 있다.

전 단계 합계 약 **1시간** (문서 하네스 내용을 채우는 시간은 제외).

## 0단계 — 설치·로그인 (10분)

- [ ] Claude Code 설치 및 계정 로그인
- [ ] 프로젝트 디렉터리에서 세션을 시작해 정상 기동 확인
- [ ] **진입 경로 표기를 하나로 고정** — 특히 Windows

> 경로 표기가 흔들리면(`D:\proj` / `D:/proj` / `d:/proj`) **서로 다른 프로젝트로 등록**된다.
> MCP 가 붙었다 안 붙었다 하고 메모리 디렉터리도 갈라진다. 표기를 정해 팀 규칙으로 적어 둔다.

## 1단계 — 전역 settings (5분)

→ 상세: [`settings/`](settings/)

- [ ] `~/.claude/settings.json` 생성
- [ ] 스칼라 키부터: `model`, `effortLevel`(`low`/`medium`/`high`/`xhigh`), `autoUpdatesChannel`(`latest`/`stable`)
- [ ] `permissions` 는 빈 껍데기로 두고 시작 (allow 시드는 3단계에서)
- [ ] 전역에는 **특정 프로젝트 절대경로·임시 경로를 넣지 않는다**

## 2단계 — 프로젝트 문서 하네스 (복사 5분)

→ 상세: [README.md](../README.md) 빠른 시작, [GUIDE.md](../GUIDE.md) §7

- [ ] [README.md](../README.md) **빠른 시작 1~3단계** 완료 (문서 하네스는 그쪽이 정본 — 여기서 반복하지 않는다)

## 3단계 — 프로젝트 settings + 권한 (10분)

→ 상세: [`settings/`](settings/)

- [ ] `.claude/settings.json`(팀 공유, **git 추적**) 과 `.claude/settings.local.json`(개인, 미추적) 역할 결정
- [ ] `.gitignore` 에는 `settings.local.json` **만** 넣는다 — `.claude` 를 통째로 제외하면 팀 공유 계층이 죽는다
- [ ] allow 시드는 재사용 패턴 위주로: `Bash(<명령>:*)`, `Read(//<프로젝트 경로>/**)`, `WebFetch(domain:<호스트>)`
- [ ] 위험 명령은 `permissions.deny` 로 기계적으로 차단한다 (문서의 산문 규칙만으로는 막히지 않는다)
- [ ] `additionalDirectories` 는 실제 존재하는 경로만. 워크트리·임시 경로는 넣지 않는다

## 4단계 — MCP 등록 (서버당 5~15분)

→ 상세: [`mcp/`](mcp/) · 사용 정책은 [`docs/TOOLS.md`](../templates/docs/TOOLS.md)

- [ ] `claude mcp add <이름> --scope <local|project|user> --transport <stdio|http|sse|ws>` 로 등록 (JSON 직접 편집보다 권장 — 스코프 선택 기준은 [mcp/README.md](mcp/README.md))
- [ ] 팀과 공유할 서버는 프로젝트 루트 `.mcp.json` 에 둔다
- [ ] **접속정보·토큰은 `${환경변수}` 참조로.** args·url·headers 에 평문 금지
- [ ] 호스팅형 커넥터는 파일 복사로 옮겨지지 않는다 — 새 환경에서 다시 연결
- [ ] 플러그인이 MCP 서버를 함께 제공하는 경우가 있으니 6단계 후 목록을 다시 본다

## 5단계 — 메모리 초기화 (5분)

→ 상세: [`memory/`](memory/)

- [ ] 메모리 위치 확인: `~/.claude/projects/<프로젝트 슬러그>/memory/`
- [ ] 슬러그는 **진입 경로 문자열에서 파생**된다 — 0단계의 표기 고정이 지켜졌는지 재확인
- [ ] `MEMORY.md` 는 **인덱스로만** 쓴다. 세션 시작 시 앞 200줄(또는 25KB)만 로드된다
- [ ] 노트 유형과 frontmatter 형식을 **한 가지로 고정**하고 규약을 적어 둔다
- [ ] 이전 프로젝트 메모리는 옮기지 않는다

## 6단계 — 플러그인 (5분)

→ 상세: [`settings/`](settings/)

- [ ] `extraKnownMarketplaces` 에 마켓플레이스 등록
- [ ] `enabledPlugins` 에 실제로 쓸 플러그인만 `"<플러그인명>@<마켓플레이스명>": true` 로 활성화
- [ ] **플러그인을 안 쓰면 `enabledPlugins`·`extraKnownMarketplaces` 두 키를 통째로 삭제한다.**
      예시 JSON 은 주석을 못 담아 플레이스홀더 안내가 파일 안에 없다 (→ [`settings/permissions-starter.md`](settings/permissions-starter.md) §예시 JSON 을 복사할 때)
- [ ] 설치 기록 파일은 손대지 않는다 (기계 생성)

## 7단계 — 검증 (10분)

- [ ] 아래 **동작 확인** 표를 전부 통과시킨다. 하나라도 실패하면 다음 단계로 넘어가지 않는다

## 8단계 — 점진 확장 (상시)

→ 상세: [`hooks/`](hooks/)

- [ ] 같은 절차를 3회 이상 반복했다 → 커스텀 스킬로 (`.claude/skills/<이름>/SKILL.md`)
- [ ] 문서에 "매 작업 시작 시 ~를 확인하라"고 적고 있다 → hook 후보
- [ ] 역할이 분명한 반복 작업이 있다 → 서브에이전트로 (`.claude/agents/<이름>.md`)
- [ ] allow 목록 주기적 가지치기 — 죽은 경로·일회성 항목 제거, 자주 쓰는 것은 패턴으로 승격

## 동작 확인

프로젝트 디렉터리에서 **새 세션**을 시작하고 다음을 눈으로 확인한다.

| 확인 대상 | 먹었다는 신호 | 실패 시 볼 곳 |
|------|------|------|
| 프로젝트 지침 | `CLAUDE.md` 에만 적힌 고유 규칙을 물었을 때 그대로 답한다 | 파일 위치(`./CLAUDE.md` 또는 `./.claude/CLAUDE.md`), 진입 경로 표기 |
| MCP 로드 | 도구 목록에 `mcp__<서버명>__<툴명>` 형태가 보인다 | 스코프·경로 표기 불일치, 등록 후 재시작 여부 |
| 권한 | 자주 쓰는 명령에서 승인 프롬프트가 더 이상 뜨지 않는다 | 규칙 문법 오타, 계층 우선순위(local > project > user) |
| 차단 | `deny` 에 넣은 명령이 실제로 거절된다 | 같은 대상이 allow 에도 걸려 있는지 |
| 메모리 | `MEMORY.md` 에 적어둔 사실을 세션 시작 직후 이미 알고 있다 | 슬러그 디렉터리가 진입 경로 표기와 어긋났는지 |
| 플러그인 | 플러그인이 제공하는 스킬·커맨드가 목록에 뜬다 | `enabledPlugins` 의 `<플러그인>@<마켓플레이스>` 표기 |
| 문서 하네스 | 작업 지시 시 `docs/` 의 규칙을 근거로 되묻는다 | 링크 깨짐, 플레이스홀더 미기입 |

세팅이 끝나면 실제 작업 한 건을 돌려 보고, 프롬프트가 잦은 명령과 빠진 규칙을 3단계로 되돌아가 보강한다.
