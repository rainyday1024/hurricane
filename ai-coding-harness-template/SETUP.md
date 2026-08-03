# 하네스 세팅 시작하기 (Setup)

> 새 PC 를 받았거나 새 프로젝트를 시작할 때 **가장 먼저 여는 문서**.
> 무엇을 어떤 순서로 놓을지만 안내하고, 근거와 상세 절차는 각 문서로 넘깁니다.

---

## 30초 요약 — 이 저장소는 두 겹입니다

```
                    ┌── templates/ ──→ 대상 프로젝트 루트에 복사      (문서 하네스)
   이 저장소 ───────┤                   CLAUDE.md · AGENTS.md · docs/
                    └── setup/ ─────→ 내 머신의 Claude Code 를 세팅   (환경 세팅)
                                        settings.json · MCP · memory
```

| 겹 | 무엇을 정하나 | 위치 | 빠지면 |
|------|--------------|------|--------|
| 문서 하네스 | AI 에게 **무엇을 지시할지** — 규칙·구조·도메인 지식 | `templates/` | 규칙을 모른 채 제멋대로 작성 |
| 환경 세팅 | AI 를 **어떤 환경에서 돌릴지** — 설정·권한·MCP·메모리 | `setup/` | 도구·권한·기억 없이 매번 맨손 |

두 겹은 서로 독립입니다. 한쪽만 해도 굴러가지만, **효과는 둘이 겹칠 때** 납니다.
하네스 개념·구축 방법론은 [README.md](README.md) 와 [GUIDE.md](GUIDE.md),
환경 레이어의 이식 범위(무엇을 옮기고 무엇을 새로 만드나)는 [`setup/README.md`](setup/README.md) 를 참고하세요.

---

## 세 가지 경로

| 상황 | 경로 | 예상 소요 |
|------|------|----------|
| 장비를 바꿨다 / 계정을 새로 만들었다 | **A. 환경 복원** | 30분~1시간 |
| 이미 굴러가는 팀 프로젝트에 하네스를 얹는다 | **B. 하네스 도입** | 반나절~1일 (Phase 0) |
| 프로젝트도 환경도 새로 시작한다 | **C. A → B 순서** | A + B |

### A. 새 PC 에 내 환경 복원

1. [`setup/checklist.md`](setup/checklist.md) 를 열고 **0단계부터 순서대로** 체크합니다.
2. 각 단계의 상세 근거는 하위 문서에 있습니다 — 설정 3계층 [`setup/settings/`](setup/settings/),
   MCP 등록 [`setup/mcp/`](setup/mcp/), 영속 메모리 [`setup/memory/`](setup/memory/).
3. 다 채운 실물이 어떻게 생겼는지는 [`profiles/`](profiles/) 의 스냅샷을 예시로 봅니다.

- **복사 금지 목록을 먼저 읽으세요.** 옛 머신의 설정 파일을 통째로 옮기면 죽은 경로·계정 정보가 그대로 따라옵니다 ([`setup/README.md`](setup/README.md)).
- 대상 프로젝트에 이미 문서 하네스가 있다면 A 만으로 끝납니다.

### B. 기존 팀 프로젝트에 하네스 도입

1. [README.md](README.md) **빠른 시작 5단계**를 그대로 수행합니다 (방법론 배경은 [GUIDE.md](GUIDE.md) §7).
2. 프로젝트 단위 환경 파일(`.claude/settings.json`, MCP 프로젝트 스코프)은
   [`setup/settings/`](setup/settings/) 와 [`setup/mcp/`](setup/mcp/) 를 참고해 **팀 공유분과 개인분을 분리**합니다.

- 문서 거버넌스는 팀이 **먼저 합의**해야 합니다 ([`docs/DOC_GARDENING.md`](templates/docs/DOC_GARDENING.md)).
- 환경 레이어를 통째로 `.gitignore` 에 넣으면 팀 공유 계층이 죽습니다. 무엇을 커밋할지 초기에 정하세요.

### C. 새 프로젝트를 처음부터

A 를 끝낸 뒤 B 로 갑니다. 순서를 바꾸면 문서를 채우는 내내 권한 승인 프롬프트에 막힙니다.
프로젝트 진입 경로 표기(드라이브 문자 대소문자·구분자)를 **처음에 하나로 고정**하세요 —
나중에 바꾸면 MCP 등록과 메모리 디렉터리가 갈라집니다 ([`setup/checklist.md`](setup/checklist.md)).

---

## 시간이 없으면 이것만 (최소 세트)

> 아래 4개면 대부분 굴러갑니다. 나머지는 실제로 쓰면서 채우세요.

1. **`CLAUDE.md` + `AGENTS.md` 채우기** — 하네스 본체. 이게 없으면 나머지를 해도 의미가 없습니다.
2. **전역 `settings.json` 의 스칼라 키** — `model` · `effortLevel` · `autoUpdatesChannel`.
   몇 줄이고 머신과 무관해서 이식 비용이 0 입니다 ([`setup/settings/user-settings.example.json`](setup/settings/user-settings.example.json)).
3. **재사용 가능한 `permissions.allow` 패턴 + 최소한의 `deny`** — 명령 전체가 아니라 접두 패턴으로
   ([`setup/settings/permissions-starter.md`](setup/settings/permissions-starter.md)).
4. **자주 쓰는 MCP 1~2개 등록** — 접속정보는 반드시 환경변수 참조로 ([`setup/mcp/`](setup/mcp/)).

---

## 자주 밟는 함정

- **설정 파일 통째 복사** — `~/.claude.json` 은 설정 파일이 아니라 계정·상태 저장소입니다. 복사 금지.
- **권한 규칙에 접속정보 박기** — 명령 전체를 allow 에 넣다 보면 계정·비밀번호가 설정 파일에 평문으로 남습니다.
- **allow 방치** — 실사용 중 자동 누적됩니다. 주기적으로 패턴으로 승격시키고 죽은 항목을 지우세요.
- **경로 표기 흔들림** — 같은 디렉터리를 대소문자·구분자만 다르게 진입하면 별개 프로젝트로 등록됩니다 (Windows).
- **MCP 사용 정책 혼동** — 등록 방법은 `setup/mcp/`, 사용 규칙은 [`docs/TOOLS.md`](templates/docs/TOOLS.md) 소관입니다.
