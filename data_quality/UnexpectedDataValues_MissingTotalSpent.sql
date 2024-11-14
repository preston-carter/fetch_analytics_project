select
  r.receiptId
  , sum(finalPrice)
from `fetch-analytics-proj.Production.Receipt` r 
left join `fetch-analytics-proj.Production.ReceiptItem` ri 
  on r.receiptId = ri.receiptId
where r.totalSpent is null
group by 1
order by 2 desc