CREATE TABLE Databel (
    Customer_ID varchar(250),    
    Churn_Label boolean,    
    Account_Length_in_months int,    
    Local_Calls int,
    Local_Mins float,    
    Intl_Calls float,
    Intl_Mins float,
    Intl_Active boolean,    
    Intl_Plan boolean,
    Extra_International_Charges float,
    Customer_Service_Calls int,
    Avg_Monthly_GB_Download int,
    Unlimited_Data_Plan boolean,
    Extra_Data_Charges int,    
    State varchar(250),
    Phone_Number varchar(250),
    Gender varchar(250),
    Age int,    
    Under_30 boolean,    
    Senior boolean,
    "Group" varchar(250),    
    Number_of_Customers_in_Group int,
    Device_Protection_and_Online_Backup boolean,
    Contract_Type varchar(250),
    Payment_Method varchar(250),
    Monthly_Charge int,
    Total_Charges bigint,
    Churn_Category varchar(250),
    Churn_Reason varchar(250),    
    Churned int,
);

CREATE TABLE databel_aggregate
(
Unlimited_Data_Plan boolean,
Account_Length_in_months int,	
Intl_Active boolean,	
Intl_Plan boolean,	
State varchar(250),
Gender varchar(250),
Age int,	
Under_30 boolean,	
Senior boolean,
"Group" text,
Demographics varchar(250),
Contract_Type varchar(250),
Payment_Method varchar(250),
Churn_Category varchar(250),
Churn_Reason varchar(250),
Total_Customers	int,
Churned_Customers int,	
Avg_Monthly_Charges float,
Avg_Customer_Service_Calls float,	
Avg_Extra_International_Charges float,
Avg_Extra_Data_Charges	float,
Avg_Monthly_GB_Download	float,
Grouped_Consumption varchar(250)	
);

SELECT * 
FROM databel;

-- Calculate the total number of cutomers

SELECT COUNT(customer_id) AS total_customers
FROM Databel;

-- Calculate the total number of churned customers

SELECT SUM(churned) AS churned_customers
FROM databel;

-- Calculate the churn rate

SELECT ROUND((churned::numeric / total_customers) * 100, 2) AS churn_rate
FROM (
    SELECT SUM(churned) AS churned, 
		COUNT(customer_id) AS total_customers
    FROM databel
) AS subquery;

-- Calculate the number of churned customers by Churn reasons in descending order
-- churn reasons

SELECT churn_reason, 
		SUM(churned) AS churned_customers
FROM databel
GROUP BY churn_reason
ORDER BY churned_customers DESC;

-- Calculate the number of churned customers by churned_category in descending order
-- churn category

SELECT churn_category, 
		SUM(churned)AS churned_customers
FROM databel
WHERE churn_category IS NOT NULL
GROUP BY churn_category
ORDER BY churned_customers DESC;

-- Competitor has the highest churn category
-- Analyzing the churn reasons with the highest category
-- Competitor churn analysis

SELECT churn_reason, 
	SUM(churned) AS churned_customers
FROM databel
WHERE churn_category ILIKE '%Competitor%'
GROUP BY churn_reason
ORDER BY churned_customers DESC;

-- Churn rate by demographics
-- Under 30 indicates the customer is under 30 
-- Senior indicates the cutomer is above 65
-- Other indicates the customer is between 30 and 65
SELECT demographics,
       SUM(churned) AS churned_customers   
FROM databel AS d1
INNER JOIN databel_aggregate AS d2
USING(state)
GROUP BY demographics
ORDER BY churned_customers DESC;

-- churn rate per agegroups
-- Create age groups with a bin size of 10
WITH age_group AS (SELECT generate_series(19, 79, 10) AS lower,
				   		  generate_series(28, 88, 10) AS upper)
SELECT lower || '-' || upper AS age_group, 
		COUNT(d.Customer_ID) AS total_customers, 
		SUM(churned) AS churned_customer
FROM databel AS d
INNER JOIN age_group AS a
 ON d.age >= lower 
     AND d.age <= upper
GROUP BY lower, upper
ORDER BY age_group;

-- unlimimated data plan indicates if the...
-- customer has free unlimited download capacity with 'true' or 'false'
SELECT unlimited_data_plan, SUM(churned) AS churned_customers
FROM databel
GROUP BY unlimited_data_plan;

-- Consumption churned
-- Consumption is grouped into 3, customers that subscribed to;
-- "Less than 5GB", "10 or more GB", Between 5 and 10GB
SELECT d2.grouped_consumption, SUM(d1.churned) AS churned_customers
FROM databel AS d1
INNER JOIN databel_aggregate AS d2
	ON d1.state = d2.state
GROUP BY grouped_consumption;

--Top five states with the highest Churn rate
SELECT state, SUM(churned) AS churned_customers
FROM databel 
GROUP BY state
ORDER BY churned_customers DESC
LIMIT 5;

-- Churn Rate by contract type
WITH contract_type_cte AS (
    SELECT 
        contract_type,
        SUM(churned) AS churned_customers,
        COUNT(customer_id) AS total_customers
    FROM databel
    GROUP BY contract_type
)
SELECT 
    contract_type, 
    ROUND((churned_customers::numeric / total_customers) * 100, 2) AS churn_rate
FROM contract_type_cte
ORDER BY churn_rate DESC;


-- Churn rate by payment method
WITH payment_method_cte AS (
    SELECT 
        payment_method,
        SUM(churned) AS churned_customers,
        COUNT(customer_id) AS total_customers
    FROM databel
    GROUP BY payment_method
)
SELECT 
   payment_method, 
    ROUND((churned_customers::numeric / total_customers) * 100, 2) AS churn_rate
FROM payment_method_cte
ORDER BY churn_rate DESC;

-- Creating views for visualization

-- View 1:View the total number of customers
CREATE VIEW total_customers AS 
SELECT COUNT(customer_id) AS total_customers
FROM Databel;

-- View 2: View to get all customers who have churned
CREATE VIEW churned_customers AS
SELECT SUM(churned) AS churned_customers
FROM databel;

-- View 3: View the churn rate
CREATE VIEW churn_rate AS
SELECT ROUND((churned::numeric / total_customers) * 100, 2) AS churn_rate
FROM (
    SELECT SUM(churned) AS churned, COUNT(customer_id) AS total_customers
    FROM databel
) AS subquery;

-- View 4: View churn reasons
CREATE VIEW churn_reasons AS
SELECT churn_reason, SUM(churned) AS churned_customers
FROM databel
GROUP BY churn_reason
ORDER BY churned_customers DESC;

-- View 5: View demographics churn
CREATE VIEW demographics_churn AS
SELECT demographics, 
	SUM(churned) AS churned_customers
FROM databel AS d1
LEFT JOIN databel_aggregate AS d2
	ON d1.state = d2.state
GROUP BY demographics
ORDER BY churned_customers DESC;

-- View 6: View Competitor Churn Analysis
CREATE VIEW competitor_churn_analysis AS
SELECT churn_reason, SUM(churned) AS churned_customers
FROM databel
WHERE churn_category ILIKE '%Competitor%'
GROUP BY churn_reason
ORDER BY churned_customers DESC;

-- View 6: View the age group analysis 
CREATE VIEW age_group AS
WITH age_group AS (SELECT generate_series(19, 79, 10) AS lower,
				   		  generate_series(28, 88, 10) AS upper)
SELECT lower || '-' || upper AS age_group, 
		COUNT(d.Customer_ID) AS total_customers, 
		SUM(churned) AS churned_customer
FROM databel AS d
INNER JOIN age_group AS a
 ON d.age >= lower 
     AND d.age <= upper
GROUP BY lower, upper
ORDER BY age_group;

-- View 7: View the consumption churn analysi
CREATE VIEW consumption_churn AS
SELECT d2.grouped_consumption, SUM(d1.churned) AS churned_customers
FROM databel AS d1
INNER JOIN databel_aggregate AS d2
	ON d1.state = d2.state
GROUP BY grouped_consumption;

-- View 8: View the top five states with the highest Churn rate
CREATE VIEW state AS
SELECT state, SUM(churned) AS churned_customers
FROM databel 
GROUP BY state
ORDER BY churned_customers DESC
LIMIT 5;

--View 9: View Churn rate by contract type
CREATE VIEW contract_type AS
WITH contract_type_cte AS (
    SELECT 
        contract_type,
        SUM(churned) AS churned_customers,
        COUNT(customer_id) AS total_customers
    FROM databel
    GROUP BY contract_type
)
SELECT 
    contract_type, 
    ROUND((churned_customers::numeric / total_customers) * 100, 2) AS churn_rate
FROM contract_type_cte
ORDER BY churn_rate DESC;


--View 10: View Churn rate by payment method
CREATE VIEW payment_method AS
WITH payment_method_cte AS (
    SELECT 
        payment_method,
        SUM(churned) AS churned_customers,
        COUNT(customer_id) AS total_customers
    FROM databel
    GROUP BY payment_method
)
SELECT 
   payment_method, 
    ROUND((churned_customers::numeric / total_customers) * 100, 2) AS churn_rate
FROM payment_method_cte
ORDER BY churn_rate DESC;


