# 04 · 인도조건 세그먼트 파생 — 유니코드 마커(①~⑳) REGEXP

> 본 문서의 코드는 실제 운영 코드가 아니라, 적용한 기법을 일반화해 재현한 예시입니다.

## 기법

**Oracle `REGEXP` + `UNISTR` 마커 인덱싱, 구분코드를 세그먼트 선택자로 사용**

인도조건 원문에 여러 구분값이 동그라미 마커로 뭉쳐 오는 형식(`①값A ②값B ③...`)을, 구분코드를 마커 인덱스(`NCHR(9311 + n)`)로 삼아 해당 조각만 뽑아낸다. 범위 문자클래스(`[①-⑳]`) 대신 `UNISTR`로 마커를 명시 나열해 Oracle의 `ORA-12728`(정규식 범위 오류)을 회피했고, 프론트 JS가 동일 규칙을 표시 시점에 재현한다. 저장 경로 조회키는 자원코드 앞16자리 + 최신 수신일로 잡아, 기관별 코드 형식 차이로 인한 미매칭을 해결했다.

```sql
/* 원문 delivery_cond_val 은 구분값을 동그라미 마커로 이어붙여 옴:
   예) '①값A ②값B ③...'  →  segment_cd = 1 이면 '값A' 조각만 필요 */
SELECT
  ...,
  REGEXP_REPLACE(
    COALESCE(
      CASE
        WHEN REGEXP_LIKE(dd.segment_cd, '^[0-9]+$')
        THEN REGEXP_SUBSTR(
               dd.delivery_cond_val,
               NCHR(9311 + TO_NUMBER(dd.segment_cd))                  -- ① = U+2460 = 9312, 코드 n → 마커
               || '([^' || UNISTR('\2460\2461...\2473') || ']+)',     -- 그 마커 뒤 비마커 텍스트
               1, 1, NULL, 1)
      END,
      -- 마커를 못 찾으면 첫 세그먼트로 폴백
      REGEXP_SUBSTR(
        dd.delivery_cond_val,
        '([^' || UNISTR('\2460...\2473') || ']+)', 1, 1, NULL, 1)
    ),
    '[[:space:]]', ''
  ) AS delivery_seg
FROM ...

/* 바깥 SELECT: 저장된 코드 우선, 없으면 파생 세그먼트를 공통코드로 변환 */
SELECT
  COALESCE(
    NULLIF(e.delivery_cond_cd, ''),
    (SELECT c.common_cd
       FROM common_code c
      WHERE c.code_class = 'DELV_COND'
        AND c.use_yn = 'Y'
        AND REGEXP_REPLACE(c.code_nm, '[[:space:]]', '') = NULLIF(d.delivery_seg, '')
        AND ROWNUM = 1)
  ) AS delivery_cond_cd
FROM ...
```
