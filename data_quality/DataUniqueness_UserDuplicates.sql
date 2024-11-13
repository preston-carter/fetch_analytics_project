select
  _id
  , count(*)
from `fetch-analytics-proj.Staging.RawUser`
group by 1 having count(*) > 1
order by 2 desc
;

with DistinctUser as 
(
  select
    distinct *
  from `fetch-analytics-proj.Staging.RawUser`
)

select
  _id
  , count(*)
from DistinctUser
group by 1 having count(*) > 1
order by 2 desc
-- returns nothing, so we have no non-pure duplicates and we can just select distinct to remove dupes