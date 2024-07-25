-- Create table in Nexa_Sat schema
CREATE TABLE "Nexa_Sat".nexa_sat(
			Customer_ID VARCHAR(50),
			gender VARCHAR(10),
			Partner VARCHAR(3),
			Dependents VARCHAR(3),
			Senior_Citizen INT,
			Call_Duration FLOAT,
			Data_Usage FLOAT,
			Plan_Type VARCHAR(20),
			Plan_Level VARCHAR(20),
			Monthly_Bill_Amount FLOAT,
			Tenure_Months INT,
			Multiple_Lines VARCHAR(3),
			Tech_Support VARCHAR(3),
			Churn INT);
			
-- Confirm current schema			
SELECT current_schema();

-- Set path for queries
SET search_path TO "Nexa_Sat"

-- View data
SELECT *
FROM nexa_sat;

-- Data cleaning 
-- Checking for duplicates
WITH duplicates AS(
			SELECT *, 
			ROW_NUMBER() OVER(
			PARTITION BY customer_id, gender, partner,
			 			dependents, senior_citizen, call_duration,
			 			data_usage, plan_type, plan_level,
			  		 	monthly_bill_amount, tenure_months,
			  			multiple_lines, tech_support, churn) AS row_num
			FROM nexa_sat)
SELECT *
FROM duplicates
WHERE row_num > 1;---filters out duplicate row

-- checking for null values
SELECT *
FROM nexa_sat
WHERE customer_id IS NULL
OR gender IS NULL
OR partner IS NULL
OR dependents IS NULL
OR senior_citizen IS NULL
OR call_duration IS NULL
OR data_usage IS NULL
OR plan_type IS NULL 
OR plan_level IS NULL
OR monthly_bill_amount IS NULL
OR tenure_months IS NULL
OR multiple_lines IS NULL 
OR tech_support IS NULL 
OR churn IS NULL;

-- Conclusion: the datasets contain no duplicates or null values

-- EDA
-- total users
SELECT COUNT(customer_id) AS total_users
FROM nexa_sat;

-- current users
SELECT COUNT(customer_id) AS current_users
FROM nexa_sat
WHERE churn = 0;

-- total churn customers
SELECT SUM(churn) AS churned_customer
FROM nexa_sat;

-- churn rate
SELECT ROUND((churned_customer::numeric/current_users) * 100, 2) AS churn_rate
FROM (
	SELECT SUM(churn) churned_customer, 
 			COUNT(customer_id) AS current_users
		FROM nexa_sat
) AS subquery

-- total users by level
SELECT plan_level, COUNT(customer_id) AS current_users
FROM nexa_sat
WHERE churn = 0
GROUP BY 1;

-- total revenue
SELECT ROUND(SUM(monthly_bill_amount::numeric), 2) AS revenue
FROM nexa_sat;

-- revenue by plan_level
SELECT plan_level,
		ROUND(SUM(monthly_bill_amount::numeric), 2) AS revenue
FROM nexa_sat
GROUP BY 1
ORDER BY 2 DESC;

-- churn count by plan level and plan type
SELECT plan_type,
		plan_level,
		COUNT(*) AS total_customers,
		SUM(churn) AS churned_customers
FROM nexa_sat
GROUP BY 1,2
ORDER BY 4 DESC;

-- average tenure by plan level
SELECT plan_level,
		ROUND(AVG(tenure_months), 2)
FROM nexa_sat
GROUP BY 1;

-- churn count by tech_support
SELECT tech_support, SUM(churn) AS churned_customers
FROM nexa_sat
GROUP BY 1
ORDER BY 2 DESC;

-- marketing segments
-- create table of existing users
CREATE TABLE existing_users AS
SELECT *
FROM nexa_sat
WHERE churn = 0

-- view new table
SELECT *
FROM existing_users;

-- calculate the average revenue for existing users
SELECT ROUND(AVG(monthly_bill_amount::INT), 2) AS avg_revenue
FROM existing_users;

-- calculate Customer Lifetime Value(clv) and add column
ALTER TABLE existing_users
ADD COLUMN clv FLOAT;

UPDATE existing_users
SET clv = monthly_bill_amount * tenure_months;

-- view clv column
SELECT customer_id, clv
FROM existing_users;

-- calculate clv score
-- monthlhy_bill = 40%, tenure  30%, call_duration = 10%, 
-- data_usage = 10%, premium = 10%
ALTER TABLE existing_users
ADD COLUMN clv_score NUMERIC(10, 2);

UPDATE existing_users
SET clv_score =
				(0.4 * monthly_bill_amount) +
				(0.3 * tenure_months) +
				(0.1 * call_duration) +
				(0.1 * data_usage) + 
				(0.1 * CASE WHEN plan_level = 'Premium'
				 		THEN 1 ELSE 0
				 		END);

-- view the new clv_score column
SELECT customer_id, clv_score
FROM existing_users;

-- group users into different segments based on their clv_sores
ALTER TABLE existing_users
ADD COLUMN clv_segments VARCHAR;

UPDATE existing_users
SET clv_segments =
		CASE WHEN clv_score >  (SELECT PERCENTILE_CONT(0.85)
							   WITHIN GROUP (ORDER BY clv_score)
							   FROM existing_users) THEN 'High Value'
			 WHEN clv_score >= (SELECT PERCENTILE_CONT(0.50)
							   WITHIN GROUP (ORDER BY clv_score)
							   FROM existing_users) THEN 'Moderate Value'
			 WHEN clv_score >= (SELECT PERCENTILE_CONT(0.25)
							   WITHIN GROUP (ORDER BY clv_score)
							   FROM existing_users) THEN 'Low Value'
		ELSE 'Churn Risk' 
		END;

-- view the new clv_segments column
SELECT customer_id, clv, clv_score, clv_segments
FROM existing_users;
				
-- Analyzing clv_segments
-- average monthly_bill and tenure per segments
SELECT clv_segments,
		ROUND(AVG(monthly_bill_amount::numeric), 2) AS avg_monthly_charges,
		ROUND(AVG(tenure_months::numeric), 2) AS avg_tenure
FROM existing_users
GROUP BY 1
ORDER BY 2 DESC,3 DESC;

-- SELECT clv_segments, plan_level, count(*)
-- FROM existing_users
-- GROUP BY 1, 2
-- Order by 3 desc

-- tech support and multiple lines percent
SELECT clv_segments,
		ROUND(AVG(CASE WHEN tech_support = 'Yes' THEN 1 ELSE 0 END), 2) AS tech_support_pct,
		ROUND(AVG(CASE WHEN multiple_lines = 'Yes' THEN 1 ELSE 0 END), 2) AS multiple_lines_pct
FROM existing_users
GROUP BY 1
ORDER BY 2 DESC;

-- revenue per segment
SELECT clv_segments,
		ROUND(SUM(monthly_bill_amount * tenure_months)::NUMERIC, 2) AS total_revenue
FROM existing_users
GROUP BY 1
ORDER BY 2 DESC;
		
-- cross-selling and up-selling 
-- cross_selling: tech support to senior citizens whose clv is at churn risk or low value and...
-- ...who have no dependants
SELECT customer_id
FROM existing_users
WHERE senior_citizen = 1 --senior citizens
AND dependents = 'No' --no children or tech savy helpers
AND tech_support = 'No' --no tech support
AND (clv_segments = 'Churn Risk' OR clv_segments = 'Low Value')

-- cross_selling: multiple lines to customers on basic plan who has partners and dependents 
SELECT customer_id
FROM existing_users
WHERE multiple_lines = 'No'
AND plan_level = 'Basic'
AND (partner = 'Yes' OR dependents = 'Yes')

-- cross_selling: premium discounts for basic users with churn risk
SELECT customer_id
FROM existing_users
WHERE plan_level = 'Basic'
AND clv_segments = 'Churn Risk';


-- cross_selling: basic to premium with customers with high and moderate values...
-- ...for longer lock in period and higher average revenue 
SELECT plan_level, 
		ROUND(AVG(monthly_bill_amount::numeric), 2) AS avg_bill,
		ROUND(AVG(tenure_months::numeric), 2) AS avg_tenure
FROM existing_users
WHERE (clv_segments = 'High Value' OR clv_segments = 'Moderate Value')
GROUP BY 1;

-- select customers
SELECT customer_id, monthly_bill_amount
FROM existing_users
WHERE plan_level = 'Basic'
AND (clv_segments = 'High Value' OR clv_segments = 'Moderate Value')
AND monthly_bill_amount > 150;


-- Stored procedures: storing the query in a procedure to automate my process
-- senior citizen who will be offered tech support
CREATE FUNCTION tech_support_snr_citizen()
RETURNS TABLE (customer_id VARCHAR(50))
AS $$
BEGIN
	RETURN QUERY 
	SELECT eu.customer_id
	FROM existing_users eu
	WHERE eu.senior_citizen = 1 --senior citizens
	AND eu.dependents = 'No' --no children or tech savy helpers
	AND eu.tech_support = 'No' --no tech support
	AND (eu.clv_segments = 'Churn Risk' OR eu.clv_segments = 'Low Value');
END;
$$ LANGUAGE plpgsql;

-- basic users with partners and dependents who will be offered multiple lines 
CREATE FUNCTION dependents_partners_users()
RETURNS TABLE (customer_id VARCHAR(50))
AS $$
BEGIN
	RETURN QUERY
	SELECT eu.customer_id
	FROM existing_users eu
	WHERE eu.multiple_lines = 'No'
	AND eu.plan_level = 'Basic'
	AND (eu.partner = 'Yes' OR eu.dependents = 'Yes');
END;
$$ LANGUAGE plpgsql;

-- basic users at churn risk who will be offered premium discounts
CREATE FUNCTION churn_risk_discount()
RETURNS TABLE (customer_id VARCHAR(50))
AS $$
BEGIN
	RETURN QUERY
	SELECT eu.customer_id
	FROM existing_users eu
	WHERE eu.plan_level = 'Basic'
	AND eu.clv_segments = 'Churn Risk';
END;
$$ LANGUAGE plpgsql;

-- high usage customers who will be offered premium upgrade
CREATE FUNCTION high_usage_basic_users()
RETURNS TABLE (customer_id VARCHAR(50))
AS $$
BEGIN 
	RETURN QUERY 
	SELECT eu.customer_id
	FROM existing_users eu
	WHERE eu.plan_level = 'Basic'
	AND (eu.clv_segments = 'High Value' OR eu.clv_segments = 'Moderate Value')
	AND eu.monthly_bill_amount > 150;
END;
$$ LANGUAGE plpgsql;

-- use procedures
-- tech support snr citizen
SELECT *
FROM tech_support_snr_citizen()

--basic dependents and partners users offered multiple lines
SELECT *
FROM dependents_partners_users()

-- churn risk doiscounts
SELECT *
FROM churn_risk_discount()

-- high usage basic customers
SELECT *
FROM high_usage_basic_users()








