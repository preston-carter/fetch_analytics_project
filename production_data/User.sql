create or replace table `fetch-analytics-proj.Production.User` as 

select distinct
  _id as userId
  , role
  , state
  , signUpSource
  , active
  , date(timestamp_millis(createdDate)) as createdDate
  , timestamp_millis(lastLogin) as lastLoginTimestamp
from `fetch-analytics-proj.Staging.RawUser`