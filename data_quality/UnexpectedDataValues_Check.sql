select
  min(createDate)
  , max(createDate)
  , min(modifyDate)
  , max(modifyDate)
  , min(pointsAwardedDate)
  , max(pointsAwardedDate)
  , min(purchaseDate)
  , max(purchaseDate)
  , min(dateScanned)
  , max(dateScanned)
from `fetch-analytics-proj.Production.Receipt`