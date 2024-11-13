create or replace table `fetch-analytics-proj.Production.Brand` as 

select
  _id as brandId
  , brandCode
  , name as brandName
  , cast(barcode as string) as barcode
  -- , cpg
  , categoryCode
  , category
  , topBrand
from `fetch-analytics-proj.Staging.RawBrand`
