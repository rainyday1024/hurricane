# MCP 서버 등록 가이드

> MCP 서버를 **설치·등록하고 스코프에 배치하는** 절차. 등록된 MCP 를 *어떻게 쓸지*(사용 정책)는 여기가 아니라
> 프로젝트의 `docs/TOOLS.md` 소관이다. 서버를 추가/제거하면 `docs/TOOLS.md` 를 갱신할 것.

## 등록 방법 2가지

| 방법 | 명령 / 파일 | 언제 쓰나 |
|------|------------|-----------|
| ① CLI (권장) | `claude mcp add <이름> …` | 거의 모든 경우. 스코프·transport 를 인자로 주고 파일 편집은 CLI 에 맡긴다 |
| ② 파일 직접 편집 | `~/.claude.json` 또는 `<repo>/.mcp.json` | CLI 로 표현이 번거로운 값(중첩 `env`, 여러 서버 일괄 이관)을 넣을 때 |

```bash
# 사용 가능한 플래그·스코프 값은 반드시 --help 로 먼저 확인한다
claude mcp add --help

# stdio 서버
claude mcp add <이름> --scope <local | project | user> --transport stdio -- <실행파일> <인자...>

# 원격 HTTP 서버
claude mcp add <이름> --scope <...> --transport http <URL>
```

- transport 는 `stdio` / `http` / `sse` / `ws` 4종 (`streamable-http` 는 `http` 별칭). 원격은 `http` 권장.
- **`~/.claude.json` 은 설정 파일이 아니라 클라이언트 상태 저장소다.** MCP 정의 외에 계정·머신 식별자·세션 통계가
  같이 들어 있으므로 **통째 복사·커밋 금지**. 새 PC 로 옮길 땐 `mcpServers` 블록만 옮기거나 CLI 로 재등록한다.
- `<repo>/.mcp.json` 은 **팀 공유용 MCP 정의 파일**이고 git 추적 대상. 여기 정의된 서버의 on/off 는
  `settings.json` 의 `enabledMcpjsonServers` / `disabledMcpjsonServers` 로 개별 제어한다.

파일을 직접 편집할 경우 전체 형태는 이렇다. 서버 정의는 **`mcpServers` 아래 서버명 키의 값**이다.

```json
{
  "mcpServers": {
    "<서버명>": { "type": "stdio", "command": "<실행파일>", "args": ["<인자>"], "env": {} },
    "<다른 서버명>": { "type": "http", "url": "https://<호스트>/mcp" }
  }
}
```

`~/.claude.json` 도 같은 `mcpServers` 객체를 쓰지만 위치가 다르다 — 전역은 **최상위** `mcpServers`,
프로젝트 스코프는 `projects["<절대경로>"].mcpServers`.

## 스코프 선택 기준

| 판단 기준 | 전역 (`user`) | 프로젝트 (`project` / `local`) |
|-----------|--------------|-------------------------------|
| 특정 리포·스키마·디자인 파일에 종속되는가 | 아니오 | 예 |
| 팀 전원이 같은 값으로 써야 하는가 | 아니오 | 예 → `.mcp.json` |
| 대표 예 | 브라우저 자동화, 범용 검색 | 개발 DB, 디자인 툴, 이슈 트래커 |

> 자격증명이 필요한 서버는 프로젝트 종속이더라도 **공유 스코프(`project`/`.mcp.json`)에 두지 않는다.**
> 값은 개인 파일(`local`/`user`)에, 존재 사실과 사용 규칙만 `docs/TOOLS.md` 에 적는다.

## 레시피

> 1~3번 코드블록은 위 `mcpServers.<서버명>` 의 **값 부분**이다. 그대로 붙여넣지 말고 서버명 키 아래에 넣는다.
> 4번만 파일이 다르다 — `settings.json` 소관이다.

### 1. 관계형 DB (읽기 위주)

Oracle — CLI 도구가 저장된 접속 프로필을 쓰므로 **인자에 자격증명이 없다**. 가장 이상적인 형태.

```json
{ "type": "stdio", "command": "<SQLcl 설치경로>/bin/sql.exe", "args": ["-mcp"], "env": {} }
```

PostgreSQL — 접속 URL 이 **인자에 평문으로** 들어간다. 반드시 환경변수 참조로 우회한다.

```json
{ "type": "stdio", "command": "npx",
  "args": ["-y", "@modelcontextprotocol/server-postgres", "${PG_URL}"], "env": {} }
```

- **⚠️ 주의** — `${PG_URL}` 자리에 `postgresql://<user>:<password>@<db-host>:5432/<db>` 를 직접 쓰면
  그 파일은 영구히 공유 불가가 된다 (→ 아래 §자격증명 취급).
- 확인: 세션 재시작 후 도구 목록에 `mcp__<이름>__…` 이 보이는지. 첫 호출은 스키마 조회 같은 읽기 전용으로.

### 2. 브라우저 자동화 (Playwright)

```json
{ "type": "stdio", "command": "npx",
  "args": ["@executeautomation/playwright-mcp-server"], "env": {} }
```

- 프로젝트 종속성도 자격증명도 없다 → **전역(`user`) 스코프**가 적합.
- 확인: `mcp__playwright__…` 도구 노출 여부. UI 검증 절차 자체는 `docs/UI_VALIDATION.md` 참조.

### 3. 원격 HTTP MCP (OAuth 인증형)

```json
{ "type": "http", "url": "https://mcp.<서비스>.com/mcp" }
```

- 키는 `type` + `url` 둘이면 충분. 토큰 헤더가 필요하면 `"headers": { "Authorization": "Bearer ${<TOKEN 변수명>}" }`.
- OAuth 는 최초 1회 **대화형 세션에서만** 인증할 수 있다(`/mcp`). 비대화형·서브에이전트 세션에서는 인증 불가.
- claude.ai 호스팅 커넥터는 로컬 파일에 정의가 남지 않는다 → **새 PC 재현 시 파일 복사로 옮겨지지 않는다.**
  claude.ai 설정에서 다시 연결해야 한다.
- 플러그인이 MCP 서버를 번들로 들고 오기도 한다. 같은 서비스가 두 경로로 뜨면 하나를 끈다.

### 4. 이슈 트래커 (읽기 전용 정책)

산문 규칙만으로는 쓰기 호출을 막지 못한다. 권한으로 기계적 강제까지 건다.
**아래 조각만 `settings.json` 것이다** — `mcpServers` 가 아니라 `permissions` 아래로 들어간다.

```json
{
  "permissions": {
    "allow": ["mcp__<서버명>__<조회도구>", "mcp__<서버명>__<검색도구>"],
    "deny":  ["mcp__<서버명>__<생성도구>", "mcp__<서버명>__<수정도구>"]
  }
}
```

- 도구 단위 표기는 `mcp__<서버명>__<도구명>` — **괄호 없음**. 서버 통째 차단은 `deniedMcpServers`.
- 확인: 차단 대상 도구를 일부러 호출시켜 거부되는지 1회 검증한다.

## 자격증명 취급

- MCP 고유 사실 하나 — 환경변수 확장은 `${VAR}` / `${VAR:-<기본값>}` 형태로 **`args` 와 `headers` 에서 동작**한다.
  공유 `.mcp.json` 에는 서버명·transport·명령/URL 껍데기 + 환경변수 *이름*만 남기고 실제 값은 각자 로컬에서 채운다.
- 나머지 규칙(평문 금지 대상, 이미 유출된 값의 처리)은 → [`setup/README.md`](../README.md) §자격증명 취급.

## 사용 정책

- 등록된 MCP 를 **어떤 상황에 어디까지 쓸지**(DB 쓰기 금지, 이슈 읽기 전용, 브라우저 접속 URL 제한 등)는
  [`docs/TOOLS.md`](../../templates/docs/TOOLS.md) 에서 정의한다. 이 문서는 **설치·등록까지만** 다룬다.

## 트러블슈팅 — MCP 가 안 붙을 때

1. **도구 목록 확인** — `mcp__<서버명>__…` 이 보이는가. 안 보이면 로드 실패다. 여기서부터 시작한다.
2. **세션 재시작** — 등록 직후에는 반영되지 않는다. 재시작 후 1번을 다시 본다.
3. **시작 디렉터리 표기** — 프로젝트 스코프는 `~/.claude.json` 의 `projects["<절대경로>"]` 키에 매달린다.
   이 키는 **대소문자·슬래시 방향까지 구분하는 리터럴 문자열**이라 `D:/x` · `d:/x` · `D:\x` 가 각각 별개 엔트리가 된다.
   같은 프로젝트인데 MCP 가 붙었다 안 붙었다 하면 십중팔구 이것 → **항상 한 가지 표기로 진입**하는 규칙을 팀에 고정한다.
4. **인증 대기** — OAuth 서버는 미인증 상태에서 도구가 아예 안 뜬다. 대화형 세션에서 `/mcp` 로 인증한다.
5. **on/off 상태** — `.mcp.json` 서버는 `enabledMcpjsonServers`/`disabledMcpjsonServers`,
   그 외는 `allowedMcpServers`/`deniedMcpServers` 를 확인한다.
6. **명령 자체 검증** — 등록한 명령을 셸에서 그대로 실행해 프로세스가 뜨는지 본다.
   `npx` 계열은 최초 패키지 다운로드에서 시간이 걸리므로 서버 정의의 `timeout` 값을 올려본다.

## 참고

- Anthropic — MCP: <https://code.claude.com/docs/en/mcp>
- Anthropic — 설정(`settings.json`): <https://code.claude.com/docs/en/settings>
