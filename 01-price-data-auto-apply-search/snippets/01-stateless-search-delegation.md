# 01 · 배치 검색 위임 + JSON SSOT 후보 반환 (stateless 검색)

> 본 문서의 코드는 실제 운영 코드가 아니라, 적용한 기법을 일반화해 재현한 예시입니다.

## 기법

**Stateless 매칭 이관 + 단일 진실원(SSOT) 정규화 (호스트단 컷오프 제거)**

매칭 서버는 검색만 담당하고, 부가필드는 검색 응답 JSON을 그대로 신뢰한다. 이전에는 호스트가 외부 시세 테이블을 다시 조인해 분류명 등을 보강(`enrichClass`)하고 하위 등급(임계 미만)을 잘라냈는데, 이 이중 필터가 배치의 등급 판정(저점수라도 자동후보 가능)과 충돌해 정상 후보를 누락시켰다. 컷오프를 배치 검색에 위임하고 선택적 하한 점수만 옵션으로 남겼다.

```java
// 입력 → 품명/규격/단위 파싱 (검색 경로와 동일 규칙:
//   hidden 포맷 우선, 3자 이하 공백 제거, 단위 정규화)
Map<String, String> in = parseSearchInput(param);
int fetchSize = Math.max(searchSize, 30);

String searchUrl = matchBatchUrl + "/searchItem"
        + "?ITEM_NM=" + enc(in.get("itemNm"))
        + "&SPEC_NM=" + enc(in.get("specNm"))
        + "&UNIT="    + enc(in.get("unit"))
        + "&APPLY_YM=" + enc(applyYm)
        + "&size="    + fetchSize;

Map<String, Object> batchResult = callBatchPost(searchUrl, null); // 검색 = SSOT

List<Map<String, Object>> returnList = new ArrayList<>();
for (Map<String, Object> row : (List<Map<String, Object>>) batchResult.get("list")) {
    // 선택적 하한만 적용 — 등급 컷오프는 없다. 배치가 이미 걸러줌.
    if (minScore > 0 && toDouble(row.get("SCORE")) < minScore) continue;

    row.put("CAND_SCORE",   row.get("SCORE"));
    row.put("CAND_TIER",    row.get("TIER")); // HIGH / MID / LOW
    row.put("CAND_SEGMENT", row.get("STEP"));
    returnList.add(row);
    if (returnList.size() >= searchSize) break;
}
// 분류/부가세/결제/인도조건은 배치 JSON이 SSOT —
// 외부 시세 조인 보강(enrichClass) 폐기, 값이 없으면 null 그대로 둔다.
return returnList;
```
