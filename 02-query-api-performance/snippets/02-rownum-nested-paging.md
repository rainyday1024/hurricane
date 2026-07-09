# 02. Oracle ROWNUM 이중중첩 페이징 공통 프래그먼트

> 본 문서의 코드는 실제 운영 코드가 아니라, 적용한 기법을 일반화해 재현한 예시입니다.

## 기법

**Oracle ROWNUM 이중중첩 페이징 (`FIRST_ROWS` 힌트).**

Oracle 11g 호환 정석 페이징. 안쪽 인라인뷰에서 `ORDER BY` 후 `ROWNUM`을 부여하고, 바깥에서 `RNUM` 범위로 절단한다. `FIRST_ROWS` 힌트로 상위 N건을 빨리 뱉게 유도한다. 전량 로드 대신 한 페이지만 클라이언트로 전송한다. MyBatis 프래그먼트로 뽑아 모든 목록 쿼리가 공유한다.

```xml
<sql id="pagingStartSql"><![CDATA[
SELECT * FROM (
  SELECT /*+ FIRST_ROWS */ t1.*, ROWNUM rnum
    FROM (
]]></sql>

<!-- ... 본문 쿼리 (반드시 ORDER BY 포함) ... -->

<sql id="pagingEndSql"><![CDATA[
    ) t1
   WHERE ROWNUM <= #{lastRownum}
)
WHERE rnum >= #{firstRownum}
]]></sql>
```

서비스 계층에서 페이지 번호를 rownum 경계로 환산한다.

```java
// rcpp = rows-count-per-page (기본 1000)
int firstRownum = (pageNo - 1) * rcpp + 1;
int lastRownum  = pageNo * rcpp;
param.put("firstRownum", firstRownum);
param.put("lastRownum", lastRownum);
```
