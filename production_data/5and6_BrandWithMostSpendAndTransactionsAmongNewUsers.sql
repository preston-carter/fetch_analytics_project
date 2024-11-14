with MaxUserDate as 
(
  select
    max(createdDate) as maxUserCreatedDate
  from `fetch-analytics-proj.Production.User`
)

select
  brandName
  , round(sum(totalSpent),2) as TotalSpentSum
from `fetch-analytics-proj.Production.ReceiptItemDetail`
where userCreatedDate >= date_sub((select MaxUserCreatedDate from MaxUserDate), interval 6 month)
  and brandName is not null
group by 1
order by 2 desc
limit 1
;

with MaxUserDate as 
(
  select
    max(createdDate) as maxUserCreatedDate
  from `fetch-analytics-proj.Production.User`
)

select
  brandName
  , count(distinct receiptId) as TotalTransactions
from `fetch-analytics-proj.Production.ReceiptItemDetail`
where userCreatedDate >= date_sub((select MaxUserCreatedDate from MaxUserDate), interval 6 month)
  and brandName is not null
group by 1
order by 2 desc
limit 1