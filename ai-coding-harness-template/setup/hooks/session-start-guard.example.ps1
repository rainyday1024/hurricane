# SessionStart hook — 보호 브랜치 경고 (레시피 R1)
#
# 사용법: .claude/hooks/session-start-guard.ps1 로 복사(.example 제거)
#         → settings.json 의 hooks.SessionStart 에 등록.
#         실행 정책에 막히면 powershell -NoProfile -ExecutionPolicy Bypass -File <경로> 형태로 호출.
# 알림 전용 — 절대 차단하지 않는다(항상 exit 0).
# stdout 은 JSON 결과로 파싱되므로 안내 문구는 stderr 로 낸다.
#
# !! 미검증 !! 비차단(exit 0) hook 의 stderr 가 사용자 화면에 표시되는지는 확인되지 않았다.
#   등록 후 새 세션에서 아래 문구가 실제로 뜨는지 먼저 확인할 것. 안 뜨면 이 스크립트는 값이 없다 —
#   제거하거나, 비차단 hook 의 정식 출력 형식을 공식 문서에서 확인해 그 형식으로 고쳐 쓴다.
#   https://code.claude.com/docs/en/hooks
# 이 파일은 UTF-8 with BOM 으로 저장할 것 — Windows PowerShell 5.1 은 BOM 없으면 한글을 깨뜨린다.

$ProtectedBranches = @('main', 'master', 'develop')

# git 이 없으면 조용히 통과
if (-not (Get-Command git -ErrorAction SilentlyContinue)) { exit 0 }

# git 리포가 아니면 조용히 통과
$inside = git rev-parse --is-inside-work-tree 2>$null
if ($LASTEXITCODE -ne 0 -or "$inside".Trim() -ne 'true') { exit 0 }

# 현재 브랜치 (detached HEAD 면 'HEAD' 가 나오며 보호 목록에 없으므로 통과)
$branch = git rev-parse --abbrev-ref HEAD 2>$null
if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($branch)) { exit 0 }
$branch = "$branch".Trim()

if ($ProtectedBranches -contains $branch) {
    [Console]::Error.WriteLine("[hook] 현재 브랜치가 보호 브랜치입니다: $branch")
    [Console]::Error.WriteLine("[hook] 작업 전 새 작업 브랜치를 딸지 사용자에게 확인하세요 (AGENTS.md 작업 시작 체크리스트).")
}

exit 0
