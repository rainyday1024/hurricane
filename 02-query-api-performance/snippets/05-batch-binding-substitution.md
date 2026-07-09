# 05. 집계 배치: 스칼라 서브쿼리 → 바인딩 치환 + 페이지 업데이트

> 본 문서의 코드는 실제 운영 코드가 아니라, 적용한 기법을 일반화해 재현한 예시입니다.

## 기법

**동치 바인딩 치환 + 페이지 단위 처리.**

집계 배치는 발표일자 루프에서 검증 프로시저를 호출하며 여러 INSERT를 연쇄한다. 바로 앞 INSERT가 이미 확보한 값을, 다음 INSERT가 상관 스칼라 서브쿼리로 다시 조회하고 있었다 — 루프마다 반복되는 잉여 풀스캔이다. 이를 파라미터 바인딩으로 치환해 반복 조회를 제거한다. 또한 외부 API 페이지(예: 500건 × 다수 페이지)를 전량 적재하던 경로를 페이지 단위 업데이트로 바꿔 OOM을 원천 차단한다.

```xml
<!-- BEFORE: 행마다 ref_price_revision_no 를 재조회 (풀스캔 반복) -->
<!--
INSERT INTO ref_revision_apply_item (ref_price_revision_no, ...)
VALUES (
  (SELECT ref_price_revision_no
     FROM ref_resource_price_revision
    WHERE ...),                      -- 직전 INSERT가 넣은 값과 동일
  ...
)
-->

<!-- AFTER: 직전 insertRefResourcePriceRevision 가 넣은 동일 값을 바인딩 재사용 -->
INSERT INTO ref_revision_apply_item (ref_price_revision_no, ...)
VALUES (#{refPriceRevisionNo}, ...)
```

서비스 계층은 전량 적재 업데이트를 페이지 단위로 교체한다.

```java
// BEFORE: 전체 목록을 List 한 개에 모두 담아 갱신 -> 대량 건에서 OOM
// updateResourceCollectScd(fullList);
// updateResourceCollectSru(fullList);

// AFTER: API 페이지 단위로 즉시 갱신 (누적 없음)
for (int page = 1; page <= totalPages; page++) {
    List<Map<String, Object>> pageRows = fetchPage(page);   // 예: 500건
    mapper.updateResourceCollectScdPage(pageRows);
    mapper.updateResourceCollectSruPage(pageRows);
}
```

동치인 값을 재사용하므로 결과는 동일하고, 루프 내 반복 풀스캔과 대량 건 메모리 누적이 함께 사라진다.
