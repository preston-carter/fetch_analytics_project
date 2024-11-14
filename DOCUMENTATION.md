# Fetch Rewards Analytics Engineering Challenge Documentation

## Table of Contents
1. [Overview](#overview)
2. [Data Model](#1-data-model)
3. [Analysis Queries](#2-analysis-queries)
4. [Data Quality Assessment](#3-data-quality-assessment)
5. [Questions for Stakeholders](#4-questions-for-stakeholders)

## Overview
This repository contains my solution to the Fetch Rewards Analytics Engineering coding challenge. The challenge involves analyzing receipt, user, and brand data to derive business insights and address data quality concerns. I primarily used Google Cloud Platform (GCP) BigQuery (BQ) SQL and even set up a dummy project in GCP. 

### Tools and Technologies Used
- SQL Dialect: GCP BigQuery SQL
- Python
- GitHub

### Data Sources
The analysis uses three raw JSON data sources (from a MongoDB source):
1. **Receipts Data**: Contains transaction information including points earned, items purchased, and receipt status
2. **Users Data**: Contains user account information and activity status
3. **Brands Data**: Contains brand and product categorization information

### Initial Observations
Before exploring the data, I created a Python script to process each json file to a BQ SQL-friendly format.  This primarily involved flattening the the MongoDB objects (I had to do a lot of research here as I was unfamiliar with MongoDB json formats) and then updating the files to be in a new line delimited JSON format.  This is contained in the process_json.py script:

```python
import json

# Func to flatten MongoDB objects but preserve arrays for BigQuery
def flatten_mongo_object(obj, prefix=''):
    if isinstance(obj, dict):
        new_obj = {}
        for key, value in obj.items():
            if isinstance(value, dict):
                if "$date" in value:
                    new_obj[key] = value["$date"]
                elif "$oid" in value:
                    new_obj[key] = value["$oid"]
                elif "$ref" in value and "$id" in value:
                    if isinstance(value["$id"], dict) and "$oid" in value["$id"]:
                        new_obj[key] = value["$id"]["$oid"]
                    else:
                        new_obj[key] = value["$id"]
                else:
                    # Handle nested objects
                    nested_obj = flatten_mongo_object(value)
                    # If nested object is a dict, flatten with dot notation
                    if isinstance(nested_obj, dict):
                        for nested_key, nested_value in nested_obj.items():
                            new_obj[f"{key}.{nested_key}"] = nested_value
                    else:
                        new_obj[key] = nested_obj
            elif isinstance(value, list):
                # Keep arrays as arrays, but flatten their contents
                new_obj[key] = [flatten_mongo_object(item) for item in value]
            else:
                new_obj[key] = value
        return new_obj
    elif isinstance(obj, list):
        return [flatten_mongo_object(item) for item in obj]
    return obj

# Func to process each json file and parse them properly for BigQuery
def process_json_file(filename):
    # Read all lines and parse each line as JSON
    with open(filename, 'r') as file:
        objects = []
        for line in file:
            if line.strip():
                obj = json.loads(line)
                flattened_obj = flatten_mongo_object(obj)
                objects.append(flattened_obj)
    
    # Write each object on a new line
    output_filename = filename.replace('.json', '_processed.json')
    with open(output_filename, 'w') as file:
        for obj in objects:
            json_line = json.dumps(obj)
            file.write(json_line + '\n')
    
    print(f"Created {output_filename} with {len(objects)} objects")

# Parse files
process_json_file('brands.json')
process_json_file('receipts.json')
process_json_file('users.json')
```

Methods used to explore the data:
- Built-in table explorer feature in BQ (new feature which is really cool!)  Here is an example screenshot of that feature:

![BQ Table Explorer Example](./images/BQTableExplorerExample.png)

- Simple SQL aggregations to look for duplicates and unique field values.  Here are a couple examples:

```sql
select
  _id
  , count(*)
from `fetch-analytics-proj.Staging.RawUser`
group by 1 having count(*) > 1
order by 2 desc
```

![Checking User table for Duplicates](./images/UserDuplicateQry.png)

```sql
select
  role
  , count(*)
from `fetch-analytics-proj.Staging.RawUser`
group by 1
order by 2 desc
```

![User.Role Query](./images/UserRoleQry.png)

Once the processed json files were imported to tables in BQ, these were my observations:

- Date/time fields are in a unix milliseconds format which I will transform to iso
- There may be duplicates in the User table (to be investigated later on)
- Receipt and Brand tables are unique on _id field.
- User fields:
  - User.role field also has 'fetch-staff' as a potential value though the schema for the project specifies that this field is a: 'constant value set to "CONSUMER"'
- Brand fields: 
  - name is better populated than brandCode
  - Similarly, category is better populated than categoryCode
  - barcode has a few dupes but the _id field is unique, so this may be expected
  - topBrand is a bool, but has a lot of NULLs, will likely transform NULLs to FALSE
- Receipt fields:
  - There are a lot of NULL purchasedItemCount records which is unexpected on first glance
  - Similarly, a lot of NULL pointsEarned values, but maybe not all purchases result in earning reward points
  - There are also a lot of NULL totalSpent records, given these are receipt entries, I would expect something was purchased
  - bonusPointsEarnedReason field values are not very explanatory, would need more info from Stakeholders here
  - rewardsReceiptItemList is a nested array field and likely should be in it's own table to be useful for analytics
    - several nested bool fields that have NULLs

    
## 1. Data Model
I created a structured, relational data model using Miro. The model shows the relationship between the raw data through the simple transformation layer I created to a final dataset that will be used for analytics to answer the stakeholder's questions.

![Data Model](./images/DataModel.png)

Discussion:
- While the model is simple, there is some storage duplication in that I am essentially replicating the raw data layer in the transformation layer and only updating a few fields while not exposing a few others. I'm doing this to show an ELT pipeline. Extract raw data, load it to BQ, and transform it as necessary. 
- The only dataset in the analytics layer is also simply set up to solve the questions posed by the business stakeholder. This is efficient and performant given that I do not have full context of the data or if there are specific analytics and reporting requirements.
- I considered adding some additional datasets in both the transformation and analytics layers like the below. But in the end, I decided these were outside the scope of this project's purpose.
  - Other dimensional tables for partners
  - Or metrics views for a guess at some metrics that may be important to Fetch (maybe comparing points earned to dollars spent, etc)
  - Or maybe a slowly-changing dimension for monitoring user data like logins
- I dropped a few fields that were not necessary for the analytics layer or were fairly incomplete (mostly NULL). I generally take the approach to tranform and store as minimum as possible to meet business objectives to save on cost and query performance.
- I could have modeled only the analytics layer table, joining directly to the raw tables, and perform the transformations within it. However, I wanted to show a full data pipeline model, from raw to staging/dimensional tables to a fact table - similar to the popular star schema. This is more commonly how an analytics team would model a data warehouse in the real world.


### Key Tables and Relationships
- The User, Brand, and Receipt tables are fairly straightforward
  - Date/Timestamp fields were transformed to an iso format
  - Minor field renaming, most notably the _id fields were renamed to add clarity between the datasets
  - A few fields were not exposed as they were not necessary for analytics (currently) or they were not very supportive dimensionally for the datasets with my limited knowledge of the data
- ReceiptItem was created from the nested array field, rewardsReceiptItemList, in the RawReceipt table
  - The unique id for the table was created by taking the receiptId and appending an incrementing integer for each item associated with the receipt record
- ReceiptItemDetail is the only analytics table exposed in the model
  - This table functions as a fact table at the most granular data level (receiptItemId) and joins the four transformation tables to access all necessary data fields for analysis
- The data model allows us to consider and analyze all stakeholder questions

### Data Transformation Layer
I transformed the raw data tables in order to parse date/time fields into a useable format, unnest arrays, remove duplicates, rename primary key fields, etc. I tried to keep renaming of fields to a minimum so that it's easy to follow along.

All transformation and the final analytics layer scripts are in the production_data folder.
- production_data 
  - Brand.sql
  - Receipt.sql
  - ReceiptItem.sql
  - ReceiptItemDetail.sql
  - User.sql


## 2. Analysis Queries

The following SQL queries address the business stakeholder questions and are located in the repo here:
- production_data
  - 1and2_Top5BrandRecentAndPreviousMonth.sql
  - 3and4_AvgSpendItemsPurchasedReceiptStatus.sql
  - 5and6_BrandWithMostSpendAndTransactionsAmongNewUsers.sql

### Query 1: What are the top 5 brands by receipts scanned for most recent month?

```sql
-- Latest Month
with LatestMonth as 
(
  select
    max(dateScanned) as maxDateScanned
  from `fetch-analytics-proj.Production.ReceiptItemDetail`
)

select
  date_trunc(dateScanned, month) as monthScanned
  , brandName
  , count(*) as count
from `fetch-analytics-proj.Production.ReceiptItemDetail`
where date_trunc(dateScanned, month) = (select maxDateScanned from LatestMonth)
  and brandName is not null
group by 1,2
order by 1 desc, 3 desc
limit 5
```

**Explanation**: This is how I would query to answer this question. However, the latest two months in the dataset do not have any brand data associated to the receipt items, so this will not return anything.
However, if you expanded to look at the 3rd most recent month, you would have some results:

![Question 1 and 2 Analysis](./images/Question1and2Issue.png)

### Query 2: How does the ranking of the top 5 brands by receipts scanned for the recent month compare to the ranking for the previous month?

```sql
-- Previous Month
with LatestMonth as 
(
  select
    max(dateScanned) as maxDateScanned
  from `fetch-analytics-proj.Production.ReceiptItemDetail`
)

select
  date_trunc(dateScanned, month) as monthScanned
  , brandName
  , count(*) as count
from `fetch-analytics-proj.Production.ReceiptItemDetail`
where date_trunc(dateScanned, month) = date_sub((select maxDateScanned from LatestMonth), interval 1 month)
  and brandName is not null
group by 1,2
order by 1 desc, 3 desc
limit 5
```

**Explanation**: Similar to Question 1, this is how I would query to answer this question. However, the latest two months in the dataset do not have any brand data associated to the receipt items, so this will not return anything.

### Query 3 and 4: When considering average spend and items purchased from receipts with 'rewardsReceiptStatus’ of ‘Accepted’ or ‘Rejected’, which is greater?

```sql
select
  round(avg(if(rewardsReceiptStatus = 'FINISHED',totalSpent,null)),2) as AverageSpendWithAcceptedStatus
  , round(avg(if(rewardsReceiptStatus = 'REJECTED',totalSpent,null)),2) as AverageSpendWithRejectedStatus
  , sum(if(rewardsReceiptStatus = 'FINISHED',purchasedItemCount,null)) as TotalPurchasedItemsWithAcceptedStatus
  , sum(if(rewardsReceiptStatus = 'REJECTED',purchasedItemCount,null)) as TotalPurchasedItemsWithRejectedStatus
from `fetch-analytics-proj.Production.ReceiptItemDetail`
```

**Explanation**: I could simply average and sum the totalSpent and purchasedItemCount, respectively, in my analytics-ready table, ReceiptItemDetail. I had to assume that 'Accepted' = 'FINISHED' as there is not an 'Accepted' status directly in the dataset.

Results: The average spend and total purchased items are greater for receipts with 'FINISHED' status vs 'REJECTED' status

![Question 3 and 4 Result](./images/Question3and4Result.png)

### Query 5: Which brand has the most spend among users who were created within the past 6 months?
```sql
with MaxUserDate as 
(
  select
    max(createdDate) as maxUserCreatedDate
  from `fetch-analytics-proj.Production.User`
)

select
  brandName
  , round(sum(totalSpent),2) as TotalSpentSum
from `fetch-analytics-proj.Production.ReceiptItemDetail`
where userCreatedDate >= date_sub((select MaxUserCreatedDate from MaxUserDate), interval 6 month)
  and brandName is not null
group by 1
order by 2 desc
limit 1
```
**Explanation**: I found the maximum user date and used this field to sum ReceiptItemDetail.totalSpent by users created in the last 6 months for each brandName and then selected only the greatest result.

Result: Tostitos with 15799.37 spent

### Query 6: Which brand has the most transactions among users who were created within the past 6 months?
```sql
with MaxUserDate as 
(
  select
    max(createdDate) as maxUserCreatedDate
  from `fetch-analytics-proj.Production.User`
)

select
  brandName
  , count(distinct receiptId) as TotalTransactions
from `fetch-analytics-proj.Production.ReceiptItemDetail`
where userCreatedDate >= date_sub((select MaxUserCreatedDate from MaxUserDate), interval 6 month)
  and brandName is not null
group by 1
order by 2 desc
limit 1
```
**Explanation**: Similarly to Question 5, I found the maximum user date and used this field to count distinct ReceiptItemDetail.receiptId by users created in the last 6 months for each brandName and then selected only the greatest result. I had to assume that a transaction is defined as a receipt.

Result: Swanson with 11 total transactions


## 3. Data Quality Assessment
### Identified Issues

All data quality SQL script examples are included in the data_quality folder.

- Data Completeness
  - Many data fields are fairly incomplete and have a significant amount or majority of NULL values. Some of these seem particularly problematic (like a receipt not having a purchasedItemCount/totalSpent). Here are some examples:
    - Brand.categoryCode
    - Receipt.purchasedItemCount
    - User.lastLoginTimestamp
- Data Uniqueness
  - The raw users table contains many pure duplicates identifiable with the following query. After removing these, there are no remaining user duplicates (like a userId with 2 different roles for example). These were removed from the User table during data transformation.

```sql
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
```

  - There are a handful of barcodes with different brandCodes which seems incorrect. Given I do not know the full context of the data, I did not remove these.

![Barcodes with Multiple BrandCodes](./images/BarcodesWithMultipleBrandCodes.png)

- Inconsistent Values & Data Types
  - The barcodes field in the Brand dataset is integer, but in the receipt item data, the barcodes have a string data type and some non-integer characters.
  - Several boolean fields have NULLs. Generally NULLs should be treated as FALSE. It will be risky or less reliable to filter against these fields if there are NULLs. I decided not to expose any of these data fields in my production dataset as they were unnecessary for analysis and incomplete.
  - The brandCode contains string values, NULLs, and '' empty strings.  Mixing nulls and empty strings is not good practice, it should be one or the other (preferrably NULLs) because, otherwise, this makes it much harder to filter against this field properly.
- Unexpected Data Values
  - I already mentioned that the ReceiptItem.brandCode is a string, but there appears to be a value (4011) that is added when a barcode is invalid, should NULLs also have this value?
  - In ReceiptItem, there is one finalPrice that does not match either discountedItemPrice or itemPrice (receiptId = '600260210a720f05f300008f'):

```sql
select 
  receiptItemId
  , receiptId
  , itemPrice
  , discountedItemPrice
  , finalPrice
from `fetch-analytics-proj.Production.ReceiptItem`
where finalPrice <> discountedItemPrice and finalPrice <> itemPrice
order by 1
```

  - In RawReceipt.rewardsReceiptItemList (because I did not expose this field), there is an itemNumber field that is mostly NULL but when it's not a majority of the records have a 4023 value.
  - In Receipt, there are many NULLs for totalSpent (and itemsPurchased). This is unexpected as I would assume a receipt should always have at least one item purchased and it's associated price.
  - One check that passed was that there were no unusual dates that were dramatically outside the expected range. For example, there were no dates in the future. I could easily check the mins and maxes for each date field like so:

```sql
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
```

- Other Checks Considered
  - Data freshness
    - Not relevant as this sample dataset is historical (Data from 2021 are the most recent).
  - Statistical Anomalies
    - Given that the sample size of this dataset is rather small, it is not relevant (and likely misleading) to check for any statistical outliers.
  - Referential Integrity
    - Checking for orphaned records is not relevant here as each dataset has it's own primary key.


## 4. Questions for Stakeholders
First of all, I would compose several different Slack messages because I have many questions about the dataset overall.
- First, in regard to the questions they asked (I would send this before I sent them the results):
  - Hi, stakeholderName 👋 I have a few questions about the metrics you requested:
    - We do not have any entered brand information for receipts scanned in the last 2 months.
      - Would you like to know the top 5 brands for the 2 most recent months for which we do have data?
    - You are interested in the average spend and total items purchased for 'Accepted' receipts, but the rewardsReceiptStatus field does not store this status.
      - Is 'Accepted' status equivalent to a status of 'FINISHED'? 
    - You are also interested in transactions among users who were created in the last 6 months. 
      - Could you define transaction for me? Would a transaction be equivalent to a processed receipt?
  - Thank you!
- Second, in regard to overall questions about the data and it's use (I would send this before I modeled the data):
  - Hello, stakeholderName! I have a few questions about the data if you could help me 😊
    - Could you tell me about the intended audience/consumer of the data that I'm modeling?
    - Is this a one-off request or do we anticipate that business users will regularly be querying these data?
    - Do we anticipate expanding this model to include additional datasets?
    - Are these data mature and complete?
    - Are there any known issues with the data?
- Third, in regard to the data quality issues identified (I would start a thread or probably better, a temporary channel, and resolve these one or two at a time):
  - Hi again, stakeholderName! I identified a few data quality issues with the dataset. I am hoping you can help me resolve them. Could we start by looking at these two issues:
    - The raw users table contains many duplicate records. Could you tell me more about how the data are captured or could you point me to someone in engineering that could help? I'd like to see if we could fix this at the source.
    - Can you take a look at this image and let me know if you expect barcodes to be associated with more than 1 brandCode? There are a few cases of this.

![Barcodes with Multiple BrandCodes](./images/BarcodesWithMultipleBrandCodes.png)

- Finally, in regard to the optimization and performance/scaling topics:
  - Hello, stakeholderName 👋 I'd like to hop on a call to discuss some of the longer-term optimization and performance considerations for the entire dataset.  My primary questions/concerns are:
    - I am planning to expose two tables that store one record for each item on a user's receipt. These datasets will grow rather large over time.
      - Are we okay with partitioning these tables?
      - Do we need the entire history of receipts? 
        - If not we could just expose the last year or two and also create a backup of historical data in a data lake or cloud storage.
    - I'd like to implement data protection for the entire dataset. Do you have a preference or any questions about these options?
      - Data restoration
        - Table snapshots
          - Could take daily snapshots of tables so that we could restore them to a previous state if needed
      - Data loss 
        - Time Travel
          - GCP has a built-in feature where we can access data from the last 7 days
          - We would need to implement daily, automated monitoring so we could backfill if any outages occur before the 7 day period expires
        - Cross-region snapshots
          - This would protect against data pipeline outages in multiple regions but would increase costs
