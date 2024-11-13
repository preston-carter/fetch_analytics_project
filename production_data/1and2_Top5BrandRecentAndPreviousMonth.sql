-- Latest Month
with LatestMonth as 
(
  select
    max(dateScanned) as maxDateScanned
  from `fetch-analytics-proj.Production.ReceiptItemDetail`
)

select
  date_trunc(dateScanned, month) as monthScanned
  , brandName
  , count(*) as count
from `fetch-analytics-proj.Production.ReceiptItemDetail`
where date_trunc(dateScanned, month) = (select maxDateScanned from LatestMonth)
  and brandName is not null
group by 1,2
order by 1 desc, 3 desc
limit 5
;

-- Previous Month
with LatestMonth as 
(
  select
    max(dateScanned) as maxDateScanned
  from `fetch-analytics-proj.Production.ReceiptItemDetail`
)

select
  date_trunc(dateScanned, month) as monthScanned
  , brandName
  , count(*) as count
from `fetch-analytics-proj.Production.ReceiptItemDetail`
where date_trunc(dateScanned, month) = date_sub((select maxDateScanned from LatestMonth), interval 1 month)
  and brandName is not null
group by 1,2
order by 1 desc, 3 desc
limit 5
;