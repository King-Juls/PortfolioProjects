-- Exploratory Data Analysis

SELECT *
FROM layoffs_staging2;

-- Maximum total laid off
SELECT MAX(total_laid_off) AS max_layoff, MIN(total_laid_off) AS min_layoff
FROM layoffs_staging2;

-- Total sum of layoff per company

SELECT company, SUM(total_laid_off)
FROM layoffs_staging2
WHERE total_laid_off IS NOT NULL
GROUP BY company
ORDER BY 2 DESC;

-- Total sum of layoff per industry

SELECT industry, SUM(total_laid_off)
FROM layoffs_staging2
WHERE total_laid_off IS NOT NULL
GROUP BY industry
ORDER BY 2 DESC;

-- Date is from 2020 to 2023

SELECT MIN(date), MAX(date)
FROM layoffs_staging2;

-- Total sum of layoff per country

SELECT country, SUM(total_laid_off)
FROM layoffs_staging2
WHERE total_laid_off IS NOT NULL
GROUP BY country
ORDER BY 2 DESC;

-- Company with the higest layoff in 2023

WITH layoff2023 AS
(
	SELECT company, TO_CHAR(date, 'YYYY') AS year,
		SUM(total_laid_off) AS sum_layoff
	FROM layoffs_staging2
	WHERE company IS NOT NULL 
		AND total_laid_off IS NOT NULL
	GROUP BY company, year
	ORDER BY sum_layoff DESC
)

SELECT *
FROM layoff2023
WHERE year::int = 2023
LIMIT 1;

--Top 5 Industry that raised the higest funds

SELECT industry, SUM(funds_raised_millions) AS total_funds_raised
FROM layoffs_staging2
WHERE funds_raised_millions IS NOT NULL
GROUP BY industry
ORDER BY total_funds_raised DESC
LIMIT 5;

--Top 10 company that raised the higest funds

SELECT company, SUM(funds_raised_millions) AS total_funds_raised
FROM layoffs_staging2
WHERE funds_raised_millions IS NOT NULL
GROUP BY company
ORDER BY total_funds_raised DESC
LIMIT 10;

-- Top 10 Countries with the highest lay off from 2020-2023

SELECT country, SUM(total_laid_off) AS sum_laid_off
FROM layoffs_staging2
WHERE total_laid_off IS NOT NULL
GROUP BY country
ORDER BY sum_laid_off DESC
LIMIT 10;

-- The year with the highest layoff

SELECT EXTRACT(year FROM date) AS year,
		SUM(total_laid_off) AS sum_laid_off
FROM layoffs_staging2
WHERE date IS NOT NULL
GROUP BY year
ORDER BY sum_laid_off DESC
LIMIT 1;

-- Total layoff by stage

SELECT stage, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY stage
ORDER BY 2 DESC;

-- Moving total laidoffs by month

SELECT TO_CHAR(date, 'YYYY-MM') AS month, SUM(total_laid_off)
FROM layoffs_staging2
WHERE TO_CHAR(date, 'YYYY-MM') IS NOT NULL
GROUP BY month
ORDER BY 1 ASC;

WITH Moving_Totals AS
(
	SELECT TO_CHAR(date, 'YYYY-MM') AS month, 
		SUM(total_laid_off) AS sum_laid_off
	FROM layoffs_staging2
	WHERE TO_CHAR(date, 'YYYY-MM') IS NOT NULL
	GROUP BY month
	ORDER BY month ASC
)
SELECT month, sum_laid_off,
	SUM(sum_laid_off) OVER(ORDER BY month) AS moving_totals
FROM Moving_Totals;


-- Ranking of the companies by total_laid off from 2020-2023

WITH Company_Year AS
(
	SELECT company, TO_CHAR(date, 'YYYY') AS year, 
		SUM(total_laid_off) AS sum_laid_off
	FROM layoffs_staging2
	WHERE total_laid_off IS NOT NULL
	GROUP BY company, year
)

SELECT *,
		DENSE_RANK() OVER(
		PARTITION BY year ORDER BY sum_laid_off DESC) AS rank
FROM Company_Year
WHERE year IS NOT NULL
ORDER BY rank, year;

-- The top 5 companies with highest layoff each year from 2020-2023

WITH Company_Year AS
(
	SELECT company, TO_CHAR(date, 'YYYY') AS year, 
		SUM(total_laid_off) AS sum_laid_off
	FROM layoffs_staging2
	WHERE total_laid_off IS NOT NULL
	GROUP BY company, year
),
	Company_Ranking AS
(	
	SELECT *,
		DENSE_RANK() OVER(
		PARTITION BY year ORDER BY sum_laid_off DESC) AS rank
	FROM Company_Year
	WHERE year IS NOT NULL
)
	
SELECT *
FROM Company_Ranking
WHERE rank <= 5

-- The top 5 industries with highest layoff each from 2020-2023

WITH Industry_Year AS
(
	SELECT industry, TO_CHAR(date, 'YYYY') AS year, 
		SUM(total_laid_off) AS sum_laid_off
	FROM layoffs_staging2
	WHERE total_laid_off IS NOT NULL
	GROUP BY industry, year
),
	Industry_Ranking AS
(	
	SELECT *,
		DENSE_RANK() OVER(
		PARTITION BY year ORDER BY sum_laid_off DESC) AS rank
	FROM Industry_Year
	WHERE year IS NOT NULL
)
	
SELECT *
FROM Industry_Ranking
WHERE rank <= 5

-- The top 5 countries with highest layoff each year from 2020-2023

WITH Country_Year AS
(
	SELECT country, TO_CHAR(date, 'YYYY') AS year, 
		SUM(total_laid_off) AS sum_laid_off
	FROM layoffs_staging2
	WHERE total_laid_off IS NOT NULL
	GROUP BY country, year
),
	Country_Ranking AS
(	
	SELECT *,
		DENSE_RANK() OVER(
		PARTITION BY year ORDER BY sum_laid_off DESC) AS rank
	FROM Country_Year
	WHERE year IS NOT NULL
)

SELECT *
FROM Country_Ranking
WHERE rank <= 5

