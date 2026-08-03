# Hooks — 규칙을 기계가 강제하게 만들기

> Claude Code hook 설정 레시피 모음. 문서 규칙은 "읽고 해석해야" 적용되지만 hook 은 **어기는 순간 개입**한다.
> 이벤트명·스키마는 버전에 따라 늘어난다. 적용 전 최신 목록을 공식 문서로 확인할 것: <https://code.claude.com/docs/en/hooks>

## 왜 hook 인가

`CLAUDE.md` · `AGENTS.md` 의 규칙에는 채점자가 없다 — 어겨도 자동으로 막히지 않는다
(→ [`docs/FEEDBACK_LOOPS.md`](../../templates/docs/FEEDBACK_LOOPS.md) §0).
hook 이 그 채점자 자리를 메운다.

- **CLAUDE.md** — 컨텍스트. Claude 가 읽는다. 권장사항이고 해석 여지가 있다.
- **hook** — 실행. CLI 가 직접 돌린다. 종료코드로 도구 호출을 **차단**할 수 있다.

## 지원 이벤트

이 문서의 레시피가 실제로 쓰는 이벤트는 셋뿐이다.

| 이벤트 | 발화 시점 | 레시피 |
|--------|----------|--------|
| `SessionStart` | 세션 시작 시 | R1 · R2 |
| `PreToolUse` | 도구 호출 **직전** — 종료코드 `2` 로 차단 가능 | R3 |
| `PostToolUse` | 도구 호출 **직후** | — |

공식 문서에서 확인된 전체 이벤트명은 다음과 같다.

```
SessionStart  Setup  SessionEnd
UserPromptSubmit  UserPromptExpansion
Stop  StopFailure
PreToolUse  PostToolUse  PostToolUseFailure  PostToolBatch
PermissionRequest  PermissionDenied
SubagentStart  SubagentStop
TaskCreated  TaskCompleted  TeammateIdle
FileChanged  CwdChanged  DirectoryAdded  ConfigChange  InstructionsLoaded
PreCompact  PostCompact
Notification  MessageDisplay
WorktreeCreate  WorktreeRemove
Elicitation  ElicitationResult
```

> 위 목록은 **이름만** 검증된 것이다. 각 이벤트의 정확한 발화 조건과 payload 스키마는
> 공식 문서에서 확인하고 쓴다. 추측으로 걸면 조용히 안 걸린다.

## settings.json 구조

hook 은 `settings.json` 의 최상위 `hooks` 키에 넣는다.
팀 공유 규칙은 `.claude/settings.json`, 개인·OS 특화 규칙은 `.claude/settings.local.json`(git 미추적)에.

```json
{
  "hooks": {
    "<이벤트명>": [
      {
        "matcher": "<도구명 — 예: Bash>",
        "hooks": [
          {
            "type": "command",
            "command": "${CLAUDE_PROJECT_DIR}/.claude/hooks/<스크립트 파일>",
            "timeout": 10,
            "statusMessage": "<진행 중 표시 문구>"
          }
        ]
      }
    ]
  }
}
```

- **`matcher`** — 어떤 도구에 걸지. 도구를 가리지 않는 이벤트(`SessionStart` 등)에서는 생략한다.
- **`hooks`** — 실행 항목 배열. 한 이벤트에 여러 개를 걸 수 있다.
- **`type`** — `"command"`(외부 명령) 또는 `"http"`(`url` · `headers` · `allowedEnvVars`).
- **`command`** — 실행 경로. `${CLAUDE_PROJECT_DIR}` 로 프로젝트 루트를 가리킨다.
- **선택 필드** — `args` · `timeout`(초) · `statusMessage` · `if`(예: `"Bash(rm *)"`).
- **입력** — stdin 으로 JSON 이 들어온다 (`session_id` · `hook_event_name` · `tool_name` · `tool_input` 등).
- **출력** — stdout 은 **JSON 결과로 파싱**된다.
- **종료코드** — `0` 성공 · `2` **차단**(stderr 내용이 차단 사유) · 그 외 비차단 에러.

> ⚠️ **미검증 — 도입 전 반드시 확인할 것.** 확인된 사실은 위 두 줄뿐이다.
> **비차단(`exit 0`) hook 이 stderr 로 낸 문구가 사용자 화면에 보이는지는 확인되지 않았다.**
> 안 보인다면 아래 R1·R2 처럼 "stderr 로 알린다"는 형태의 알림 hook 은 **조용히 아무 일도 안 하는 hook** 이 된다.
> 알림용 hook 을 쓰려면 ① 새 세션에서 문구가 실제로 뜨는지 눈으로 확인하고,
> ② 안 뜨면 그 hook 을 **쓰지 말고**, 비차단 경로에서 사용자에게 문구를 전달하는 정식 출력 형식(stdout JSON)을
> 공식 문서에서 확인해 그 형식으로 다시 작성한다 — <https://code.claude.com/docs/en/hooks>.
> 추측한 JSON 스키마를 넣지 말 것. 틀리면 역시 조용히 안 걸린다.

## 레시피

### R1. SessionStart — 보호 브랜치 경고

- **목적** — 세션이 `main`/`develop` 에서 시작됐는지 알린다.
  [`AGENTS.md`](../../templates/AGENTS.md) 작업 시작 체크리스트 첫 줄을 사람 손에서 떼어내는 것.
- **설정**

```json
{
  "hooks": {
    "SessionStart": [
      {
        "hooks": [
          { "type": "command",
            "command": "${CLAUDE_PROJECT_DIR}/.claude/hooks/session-start-guard.sh",
            "timeout": 10 }
        ]
      }
    ]
  }
}
```

- **스크립트** — `session-start-guard.example.sh` / `.ps1`. `.example` 를 떼고 `.claude/hooks/` 로 복사.
- **스크립트 동작** — 보호 브랜치면 경고 두 줄을 stderr 로 쓰고, 그 외에는 아무것도 출력하지 않는다.
  차단하지 않는다(항상 `0`). 판단은 사람이 한다.
- **⚠️ 이 문구가 화면에 보이는지는 미검증** (→ 위 §settings.json 구조 경고).
  **새 세션에서 실제로 뜨는지 먼저 확인하고, 안 뜨면 이 레시피를 쓰지 말 것.**
  그 경우 비차단 hook 의 정식 출력 형식을 공식 문서에서 확인해 스크립트를 그 형식으로 고쳐야 한다.
  셸에서 직접 실행하면(`sh session-start-guard.sh`) 스크립트 자체의 동작은 언제든 검증할 수 있다.

### R2. SessionStart — 로컬 개발환경 점검

- **목적** — 핫리로드·자동 리스타트 같은 **로컬 개발용 플래그**가 꺼진 줄 모르고 작업하는 사고를 막는다.
  프로젝트마다 파일도 플래그도 다르므로 아래는 골격이다.
- **설정** — R1 과 같은 `SessionStart` 배열에 항목을 하나 더 넣는다.

```json
{ "type": "command",
  "command": "${CLAUDE_PROJECT_DIR}/.claude/hooks/check-local-dev.sh",
  "timeout": 10 }
```

- **스크립트**

```sh
#!/bin/sh
# <설정 파일>에서 <로컬 개발용 플래그>가 켜져 있는지 확인 — 알림 전용
f="${CLAUDE_PROJECT_DIR}/<설정 파일 경로>"   # 예: src/main/resources/application.yml
[ -f "$f" ] || exit 0
grep -q '<플래그가 켜진 상태의 문자열>' "$f" \
  || echo "[hook] $f — <플래그>가 로컬 개발용 상태가 아님. 확인 필요." >&2
exit 0
```

- **스크립트 동작** — 상태가 어긋날 때만 stderr 로 한 줄 쓴다.
  **R1 과 같은 미검증 전제 위에 있다** — 화면에 뜨는지 먼저 확인하고, 안 뜨면 쓰지 않는다.
- **주의** — 이 hook 이 **파일을 고치게 만들지 말 것**. 로컬 전용 변경이 커밋에 섞이는 사고로 이어진다
  (→ [`docs/GIT_WORKFLOW.md`](../../templates/docs/GIT_WORKFLOW.md)).

### R3. PreToolUse — 위험 명령 차단

- **목적** — force push·하드 리셋처럼 되돌리기 어려운 명령을 종료코드로 막는다.
  [`CLAUDE.md`](../../templates/CLAUDE.md) §0 의 산문 금지 규칙에 기계적 뒷받침을 붙이는 것.
- **설정**

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          { "type": "command",
            "command": "${CLAUDE_PROJECT_DIR}/.claude/hooks/block-dangerous.sh",
            "timeout": 10 }
        ]
      }
    ]
  }
}
```

- **스크립트**

```sh
#!/bin/sh
# PreToolUse — 되돌릴 수 없는 git 명령 차단. stdin 으로 hook payload(JSON)가 들어온다.
payload=$(cat)

# tool_input 의 하위 구조는 도구마다 다르므로 payload 전문을 문자열로 검사한다.
case "$payload" in
  *"push --force"*|*"push -f"*|*"reset --hard"*|*"clean -f"*|*"rm -rf"*|*"rm -fr"*)
    echo "차단: 되돌릴 수 없는 명령입니다. 사용자 승인 후 직접 실행하세요." >&2
    exit 2 ;;
esac
exit 0
```

- **기대 동작** — 패턴에 걸리면 도구가 실행되지 않고 stderr 문구가 차단 사유로 전달된다.
- **주의** — payload 전문 검사라 오탐이 난다(예: 그 문자열이 들어간 파일을 읽는 명령).
  오탐이 생기면 `tool_input` 의 **실제 구조를 공식 문서로 확인해** 필드 단위로 좁힌다.
  `if` 필드로 조건을 선언하는 방법도 있다.

## 도입 원칙

- **처음부터 다 걸지 마라.** 실제로 반복된 실수 **1개**부터. 이벤트 목록을 훑으며 고르는 순서가 아니다.
- **알림(`exit 0`) → 차단(`exit 2`) 순으로 승격**한다. 처음부터 차단하면 오탐 비용을 감당 못 한다.
- **오탐이 잦으면 즉시 뺀다.** 우회하는 습관이 붙는 순간 hook 체계 전체가 무력해진다.
- **hook 은 조용히 실패하면 최악이다** — 통과한 건지 애초에 안 걸린 건지 구분이 안 된다. 도입 직후 확인:

- [ ] 셸에서 직접 실행해 종료코드·출력 확인 (`echo '{}' | <스크립트>` · `echo $?`)
- [ ] **알림(비차단) hook — 새 세션을 시작해 문구가 실제로 화면에 뜨는지 확인.
      안 뜨면 그 hook 은 값이 0 이다. 즉시 제거하거나, 공식 문서에서 확인한 정식 출력 형식으로 다시 쓴다.
      "걸어 뒀으니 되겠지" 로 남겨 두지 말 것.**
- [ ] 차단 hook 은 **일부러 위반**해 보고 정말 막히는지 확인
- [ ] 실행 권한(`chmod +x`)·경로 오타 확인 — 실행 실패는 티가 나지 않는다

- hook 을 추가·제거하면 [`docs/FEEDBACK_LOOPS.md`](../../templates/docs/FEEDBACK_LOOPS.md) 현황 표를 갱신한다. "있는 척" 금지.

## 크로스플랫폼 주의

- `command` 값 하나는 **OS 하나**만 가리킨다. `.sh` 와 `.ps1` 을 함께 두고 각자 자기 것을 등록한다.
- 팀 공유 `.claude/settings.json` 에는 OS 중립 규칙만. OS 별 경로는 개인 `settings.local.json` 으로.
- Windows 에서 `.sh` 를 쓰려면 Git Bash 등 POSIX 셸이 PATH 에 있어야 한다.
- PowerShell 은 실행 정책에 막힐 수 있다 → `powershell -NoProfile -ExecutionPolicy Bypass -File <경로>` 형태로 호출.
- Windows PowerShell 5.1 은 **BOM 없는 UTF-8 `.ps1` 을 ANSI 로 읽는다** — 한글 문구가 깨진다.
  비ASCII 문자를 쓰는 `.ps1` 은 반드시 **UTF-8 with BOM** 으로 저장한다.
- 줄바꿈(CRLF)·경로 구분자·`chmod +x` 여부가 OS 별로 갈린다. **두 스크립트를 항상 같이 고친다.**

## 이 디렉터리의 파일

```
setup/hooks/
├── README.md                        # ← 이 문서
├── session-start-guard.example.ps1  # R1 — Windows PowerShell
└── session-start-guard.example.sh   # R1 — POSIX sh
```
