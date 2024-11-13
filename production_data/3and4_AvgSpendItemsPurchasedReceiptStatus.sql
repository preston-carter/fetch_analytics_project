select
  round(avg(if(rewardsReceiptStatus = 'FINISHED',totalSpent,null)),2) as AverageSpendWithAcceptedStatus
  , round(avg(if(rewardsReceiptStatus = 'REJECTED',totalSpent,null)),2) as AverageSpendWithRejectedStatus
  , sum(if(rewardsReceiptStatus = 'FINISHED',purchasedItemCount,null)) as TotalPurchasedItemsWithAcceptedStatus
  , sum(if(rewardsReceiptStatus = 'REJECTED',purchasedItemCount,null)) as TotalPurchasedItemsWithRejectedStatus
from `fetch-analytics-proj.Production.ReceiptItemDetail`