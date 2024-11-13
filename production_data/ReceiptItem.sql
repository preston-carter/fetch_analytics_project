create or replace table `fetch-analytics-proj.Production.ReceiptItem` as 

select
  concat(_id,'_',row_number() over (partition by _id order by partnerItemId)) as receiptItemId
  , _id as receiptId
  , a.partnerItemId
  , a.rewardsProductPartnerId
  , a.pointsPayerId
  , a.originalReceiptItemText
  , a.description as receiptItemDescription
  , a.rewardsGroup
  , a.pointsEarned  
  , a.pointsNotAwardedReason
  , a.brandCode
  , a.barcode
  , a.quantityPurchased
  , a.itemPrice
  , a.discountedItemPrice
  , a.finalPrice  
from `fetch-analytics-proj.Staging.RawReceipt`
cross join unnest(rewardsReceiptItemList) a