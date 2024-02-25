use airbnb;

/*Identifying Approval Trends
1. Determine the number of drugs approved each year and provide insights into the yearly trends. */

SELECT extract(year from ActionDate) AS Year, COUNT(DISTINCT ApplNo) AS TotalApprovals
FROM RegActionDate
GROUP BY extract(year from ActionDate)
ORDER BY Year;
/* There are dips and tips in the total number of approvals yearly but the overall trend is upwards.
They increased dramatically till 2003 to a little over 300 and then fell to 1000 before steadily raising to around 2000. */

/*2. Identify the top three years that got the highest and lowest approvals, in descending and ascending order, respectively.*/
-- Top three years with the highest approvals
SELECT extract(year from ActionDate) AS Year, COUNT(DISTINCT ApplNo) AS TotalApprovals
FROM RegActionDate
GROUP BY extract(year from ActionDate)
ORDER BY TotalApprovals DESC
LIMIT 3;

-- Top three years with the lowest approvals
SELECT extract(year from ActionDate) AS Year, COUNT(DISTINCT ApplNo) AS TotalApprovals
FROM RegActionDate
GROUP BY extract(year from ActionDate)
ORDER BY TotalApprovals
LIMIT 3;

/*3. Explore approval trends over the years based on sponsors.*/

SELECT extract(year from r.ActionDate) AS Year, a.SponsorApplicant, COUNT(DISTINCT r.ApplNo) AS TotalApprovals
FROM RegActionDate r
JOIN Application a ON r.ApplNo = a.ApplNo
GROUP BY extract(year from r.ActionDate), a.SponsorApplicant
ORDER BY Year, TotalApprovals DESC;

/*4. Rank sponsors based on the total number of approvals they received each year between 1939 and 1960.*/

SELECT Year, SponsorApplicant, TotalApprovals,
       DENSE_RANK() OVER (PARTITION BY Year ORDER BY TotalApprovals DESC) AS Ranking
FROM (
    SELECT extract(year from r.ActionDate) AS Year, a.SponsorApplicant, COUNT(DISTINCT r.ApplNo) AS TotalApprovals
    FROM RegActionDate r
    JOIN Application a ON r.ApplNo = a.ApplNo
    WHERE extract(year from r.ActionDate) BETWEEN '1939' AND '1960'
    GROUP BY Year, a.SponsorApplicant
) AS ApprovalCounts;

/* Segmentation Analysis Based on Drug MarketingStatus
1. Group products based on MarketingStatus. Provide meaningful insights into the segmentation patterns.*/

select * from product limit 5;

SELECT ProductMktStatus, COUNT(*) AS TotalProducts
FROM Product
GROUP BY ProductMktStatus;

-- Most of the products have the marketing status as 1 or 3. Comparitively, there are very few products with statuses 2 and 4.

/* 2. Calculate the total number of applications for each MarketingStatus year-wise after the year 2010.*/

SELECT extract(year from r.ActionDate) AS Year, p.ProductMktStatus, COUNT(DISTINCT r.ApplNo) AS TotalApplications
FROM RegActionDate r
JOIN Application a ON r.ApplNo = a.ApplNo
JOIN Product p ON a.ApplNo = p.ApplNo
WHERE extract(year from r.ActionDate) > '2010'
GROUP BY Year, p.ProductMktStatus
ORDER BY Year, TotalApplications DESC;

-- In each year, products with marketing statuses 1 have the highest number of applications followed by those with status 3.

/* 3. Identify the top MarketingStatus with the maximum number of applications and analyze its trend over time. */

WITH MaxMarketingStatus AS (
    SELECT p.ProductMktStatus, COUNT(DISTINCT r.ApplNo) AS TotalApplications
    FROM RegActionDate r
    JOIN Application a ON r.ApplNo = a.ApplNo
    JOIN Product p ON a.ApplNo = p.ApplNo
    GROUP BY p.ProductMktStatus
    ORDER BY TotalApplications DESC
    LIMIT 1
)
SELECT extract(year from r.ActionDate) AS Year, p.ProductMktStatus, COUNT(DISTINCT r.ApplNo) AS TotalApplications
FROM RegActionDate r
JOIN Application a ON r.ApplNo = a.ApplNo
JOIN Product p ON a.ApplNo = p.ApplNo
JOIN MaxMarketingStatus mms ON p.ProductMktStatus = mms.ProductMktStatus
GROUP BY Year, p.ProductMktStatus
ORDER BY Year;

-- The products with marketing status 1 always had the highest number of applications. 
-- The number of applications increased steeply till 2002 and fell dramatically in 2003 only to increase again steadily till 2015.

/* Analyzing Products
1. Categorize Products by dosage form and analyze their distribution.*/

select * from product limit 5;

SELECT SUBSTRING_INDEX(SUBSTRING_INDEX(Form,";",1),',',1) as Form, COUNT(*) AS TotalProducts
FROM Product
GROUP BY SUBSTRING_INDEX(SUBSTRING_INDEX(Form,";",1),',',1)
ORDER BY TotalProducts DESC;

-- Tablets are the most in number followed by injectables and there are some random products 
-- like foam, pellets, kit etc. which are just a one time appearance suggesting that they may not have been categorised properly.

/* 2. Calculate the total number of approvals for each dosage form and identify the most successful forms. */

SELECT SUBSTRING_INDEX(SUBSTRING_INDEX(p.Form,";",1),',',1), COUNT(DISTINCT r.ApplNo) AS TotalApprovals
FROM Product p
JOIN Application a ON p.ApplNo = a.ApplNo
JOIN RegActionDate r ON a.ApplNo = r.ApplNo
GROUP BY SUBSTRING_INDEX(SUBSTRING_INDEX(p.Form,";",1),',',1)
ORDER BY TotalApprovals DESC;

-- Tablets and injectables are naturally the most succesful forms which might be due to their vast numbers.

/* 3. Investigate yearly trends related to successful forms. */

SELECT extract(year from r.ActionDate) AS Year, SUBSTRING_INDEX(SUBSTRING_INDEX(p.Form,";",1),',',1) as Form, COUNT(DISTINCT r.ApplNo) AS TotalApprovals
FROM Product p
JOIN Application a ON p.ApplNo = a.ApplNo
JOIN RegActionDate r ON a.ApplNo = r.ApplNo
GROUP BY Year, SUBSTRING_INDEX(SUBSTRING_INDEX(p.Form,";",1),',',1)
ORDER BY Year, TotalApprovals DESC;

-- Initially, there were applications for only a couple of forms each year, but they increased steeply over time adding more products over years.

/* Exploring Therapeutic Classes and Approval Trends
1. Analyze drug approvals based on therapeutic evaluation code (TE_Code). */

SELECT p.TECode, COUNT(DISTINCT r.ApplNo) AS TotalApprovals
FROM Product p
JOIN Application a ON p.ApplNo = a.ApplNo
JOIN RegActionDate r ON a.ApplNo = r.ApplNo
GROUP BY p.TECode
ORDER BY TotalApprovals DESC;

-- There are many approvals for products without a TE code.
-- Products with TE code 'AB' has the most approvals followed by those with code 'AP'.
-- There are single instances of approvals of products with multiple TE codes.

/* 2. Determine the therapeutic evaluation code (TE_Code) with the highest number of Approvals in each year. */

WITH TECodeApprovalsRanked AS (
    SELECT EXTRACT(YEAR FROM r.ActionDate) AS Year, p.TECode, 
	COUNT(DISTINCT r.ApplNo) AS TotalApprovals, ROW_NUMBER() OVER (PARTITION BY EXTRACT(YEAR FROM r.ActionDate) 
	ORDER BY COUNT(DISTINCT r.ApplNo) DESC) AS RowNum
    FROM Product p
    JOIN Application a ON p.ApplNo = a.ApplNo
    JOIN RegActionDate r ON a.ApplNo = r.ApplNo
    GROUP BY Year, p.TECode
)
SELECT Year,TECode,TotalApprovals
FROM TECodeApprovalsRanked
WHERE RowNum = 1;

