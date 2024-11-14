create or replace table `fetch-analytics-proj.Production.ReceiptItemDetail` as 

select
  ri.receiptItemId
  , ri.receiptId
  , r.userId
  , b.brandId
  , r.dateScanned
  , u.createdDate as userCreatedDate
  , b.brandName
  , r.rewardsReceiptStatus
  , r.totalSpent
  , r.purchasedItemCount
from `fetch-analytics-proj.Production.ReceiptItem` ri 
left join `fetch-analytics-proj.Production.Receipt` r 
  on r.receiptId = ri.receiptId
left join `fetch-analytics-proj.Production.User` u 
  on u.userId = r.userId
-- No directly reliable (id to id) fields to join for brand data
left join `fetch-analytics-proj.Production.Brand` b 
  on lower(b.brandCode) = lower(ri.brandCode)
  and b.barcode = ri.barcode