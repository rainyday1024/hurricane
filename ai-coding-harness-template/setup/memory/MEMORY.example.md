<!-- 인덱스 예시. `~/.claude/projects/<경로슬러그>/memory/MEMORY.md` 로 복사해 쓴다.
     각괄호 자리를 채우고 이 주석과 남는 예시 줄은 지운다. 규칙은 README.md 참조.
     인덱스에는 frontmatter 를 쓰지 않는다. -->

# <프로젝트명> 프로젝트 메모리

## 프로젝트 구조

- **경로**: <프로젝트 루트 절대경로>  <!-- 예: C:/src/acme-web — 항상 이 표기로 진입한다 -->
- **스택**: <예: Spring Boot 3.x + Oracle + MyBatis>
- **빠른 검증**: <빠른 검증 명령>  <!-- 예: ./gradlew check -->
- **비교용 워크스페이스**: <예: 다른 DB 버전 리포 경로 / 워크트리 경로>

## 메모리 노트

<!-- 한 줄 = 포인터 1개. `- [<제목>](<파일명>.md) — <한 줄 훅>`. 본문은 각 노트 파일에.
     훅은 요약이 아니라 "이 노트를 열어야 할 이유"를 쓴다. -->

- [코드 주석 작성자 표기](user_author_name.md) — `@author` 에는 계정 ID 가 아니라 <표기 이름>을 쓴다.
- [템플릿 수정이 화면에 안 뜰 때](feedback_resource_sync.md) — 빌드 산출물 사본이 낡아서 생긴 문제. 재발 시 대응 순서.
- [공용 개발 DB 수정 금지](feedback_db_write_policy.md) — 다른 개발자에게 영향. 왜 막는지 + 지시받았을 때의 절차.
- [<이슈번호> <모듈> 리팩터링](project_<모듈>_refactor.md) — <YYYY-MM-DD> 착수, <제약 한 줄>. 진행 중.
- [<모듈> 조회 성능 개선](project_<모듈>_perf.md) — 느렸던 원인과 적용한 인덱스. 느려지면 여기부터.
- [정본 브랜치·폴더 지도](project_branch_map.md) — 어느 폴더가 어느 브랜치인지. **커밋 전 확인.**
- [개발 DB 접속 절차](reference_db_access.md) — 접속 도구 경로와 순서. **자격증명은 적지 않는다.**
- [사내 표준 문서 위치](reference_internal_docs.md) — <위키/포털> 링크 모음.
- [<외부 API> 스펙](reference_<api>_spec.md) — 공식 문서 URL + 우리가 실제로 쓰는 엔드포인트만.
