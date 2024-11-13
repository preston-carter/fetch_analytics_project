create or replace table `fetch-analytics-proj.Production.Receipt` as 

select
  _id as receiptId
  , userId
  , rewardsReceiptStatus
  , purchasedItemCount
  , totalSpent
  , pointsEarned
  , bonusPointsEarned
  , bonusPointsEarnedReason
  , date(timestamp_millis(createDate)) as createDate
  , date(timestamp_millis(modifyDate)) as modifyDate
  , date(timestamp_millis(purchaseDate)) as purchaseDate
  , date(timestamp_millis(pointsAwardedDate)) as pointsAwardedDate
  , date(timestamp_millis(dateScanned)) as dateScanned
from `fetch-analytics-proj.Staging.RawReceipt`
