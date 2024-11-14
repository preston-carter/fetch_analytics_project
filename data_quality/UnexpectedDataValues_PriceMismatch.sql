select 
  receiptItemId
  , receiptId
  , itemPrice
  , discountedItemPrice
  , finalPrice
from `fetch-analytics-proj.Production.ReceiptItem`
where finalPrice <> discountedItemPrice and finalPrice <> itemPrice
order by 1