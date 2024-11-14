select
  a.itemNumber
  , count(*)
from `fetch-analytics-proj.Staging.RawReceipt`
cross join unnest(rewardsReceiptItemList) a
group by 1
order by 2 desc