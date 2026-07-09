# 03. 직전 단가: 상관 서브쿼리 없는 그룹최대 + 페이지 한정

> 본 문서의 코드는 실제 운영 코드가 아니라, 적용한 기법을 일반화해 재현한 예시입니다.

## 기법

**`SUBSTR(MAX(키 || 값), N)` 그룹최대 + 키셋 한정.**

개정번호(`price_revision_no`)를 정렬 접두로 값에 붙여 `MAX`를 취하면 '가장 최신 개정의 값'이 문자열 뒤쪽에 남고, `SUBSTR(..., N)`으로 접두를 잘라 값만 얻는다. 윈도우함수나 상관 서브쿼리 없이 단일 `GROUP BY`로 그룹별 최신값을 획득한다. 계산 대상은 `IN (SELECT resource_no FROM paged)`로 현재 페이지 키에만 국한해 스캔량을 최소화한다.

```sql
, old AS (
  SELECT a1.resource_no,
         -- 개정번호(길이 10 가정) 접두 뒤의 실제 값만 잘라냄
         SUBSTR(MAX(a1.price_revision_no || a1.material_price), 11) AS old_price,
         SUBSTR(MAX(a1.price_revision_no ||
                    TO_CHAR(b1.apply_dt, 'YYYYMMDD')), 11)          AS old_apply_dt
    FROM resource_unit_price      a1
    JOIN resource_price_revision  b1 ON b1.price_revision_no = a1.price_revision_no
    JOIN revision_apply_item      c1 ON c1.price_revision_no = b1.price_revision_no
   WHERE b1.apply_yn = 'Y'
     AND c1.revision_item_code = 'F01'
     AND a1.price_revision_no < #{currentRevisionNo}
     AND a1.resource_no IN (SELECT resource_no FROM paged)   -- 현재 페이지로 한정
   GROUP BY a1.resource_no
)
SELECT p.*, o.old_price, o.old_apply_dt
  FROM paged p
  LEFT JOIN old o ON o.resource_no = p.resource_no
 ORDER BY p.rnum
```

`paged`는 [02번 페이징 프래그먼트](02-rownum-nested-paging.md)로 절단된 현재 페이지 CTE다. 직전 단가 계산을 전체 데이터가 아니라 이 페이지 키셋에만 걸어 상관 서브쿼리를 제거한다.
