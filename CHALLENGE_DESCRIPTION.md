# Fetch Rewards Analytics Engineering Challenge

## Overview
This coding exercise evaluates your ability to:
- Reason about data
- Communicate your understanding of specific datasets to others

## Requirements

### 1. Data Modeling
Review unstructured JSON data and create a structured relational data model:
- Develop a simplified, structured, relational diagram for data warehouse modeling
- Show each table's fields and joinable keys
- Can use any diagramming tool (digital or hand-drawn)

### 2. Business Analysis Queries
Write SQL queries to answer at least two of these business questions:
- What are the top 5 brands by receipts scanned for most recent month?
- How does the ranking of the top 5 brands by receipts scanned for the recent month compare to the ranking for the previous month?
- When considering average spend from receipts with 'rewardsReceiptStatus' of 'Accepted' or 'Rejected', which is greater?
- When considering total number of items purchased from receipts with 'rewardsReceiptStatus' of 'Accepted' or 'Rejected', which is greater?
- Which brand has the most spend among users who were created within the past 6 months?
- Which brand has the most transactions among users who were created within the past 6 months?

### 3. Data Quality Assessment
- Use any programming language (SQL, Python, R, Bash, etc.)
- Identify data quality issues
- Document exploration and evaluation methodology

### 4. Stakeholder Communication
Write an email/Slack message addressing:
- Questions about the data
- How data quality issues were discovered
- What's needed to resolve data quality issues
- Additional information needed for data asset optimization
- Anticipated performance and scaling concerns and solutions

## Data Schemas

### Receipts Data
- **_id**: uuid for this receipt
- **bonusPointsEarned**: Number of bonus points awarded upon receipt completion
- **bonusPointsEarnedReason**: Event that triggered bonus points
- **createDate**: Event creation date
- **dateScanned**: Receipt scan date
- **finishedDate**: Receipt processing completion date
- **modifyDate**: Event modification date
- **pointsAwardedDate**: Points award date
- **pointsEarned**: Number of points earned
- **purchaseDate**: Purchase date
- **purchasedItemCount**: Number of items on receipt
- **rewardsReceiptItemList**: Items purchased
- **rewardsReceiptStatus**: Receipt validation/processing status
- **totalSpent**: Total receipt amount
- **userId**: Reference to User collection

### Users Data
- **_id**: User Id
- **state**: State abbreviation
- **createdDate**: Account creation date
- **lastLogin**: Last recorded login time
- **role**: Set to 'CONSUMER'
- **active**: Account status flag

### Brand Data
- **_id**: Brand uuid
- **barcode**: Item barcode
- **brandCode**: Partner product file reference
- **category**: Brand's product category name
- **categoryCode**: BrandCategory reference
- **cpg**: CPG collection reference
- **topBrand**: Featured brand indicator
- **name**: Brand name

## Submission Guidelines
- Provide link to public repository (GitHub/Bitbucket)
- Include all code, documentation, and diagrams
- Specify SQL dialect used
- Show work and document assumptions

## Evaluation Criteria
- ER diagrams must be legible
- SQL must be runnable
- Solution doesn't need to be production-ready but should demonstrate best practices

## Notes
- No time limit (designed to take a few hours)
- Use best judgment for unspecified requirements
- Document decisions and assumptions in repository