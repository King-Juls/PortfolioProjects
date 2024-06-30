SELECT *
FROM layoffs;

-- 1. Remove duplicates
-- 2. Standardize the Data
-- 3. Null values
-- 4. Remove any columns


-- Creating an alternate table for data cleaning

CREATE TABLE layoffs_staging
(LIKE layoffs);

INSERT INTO layoffs_staging
SELECT *
FROM layoffs;

SELECT *
FROM layoffs_staging;

-- Checking for duplicates

WITH duplicates AS (
SELECT *,
	ROW_NUMBER() OVER(
		PARTITION BY company, location, industry,
		total_laid_off, percentage_laid_off, date,
		stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging
)
SELECT *
FROM duplicates
WHERE row_num > 1

-- Removing the dupliactes

-- Creating layoffs_staging2 table to add row_num for duplicate removal.

CREATE TABLE layoffs_staging2 (
company VARCHAR(100),	
location VARCHAR(100),
industry VARCHAR(100),	
total_laid_off INT,
percentage_laid_off NUMERIC,	
date DATE,
stage VARCHAR(100),
country	VARCHAR(100),
funds_raised_millions INT,
row_num INT
)
INSERT INTO layoffs_staging2
SELECT *,
	ROW_NUMBER() OVER(
		PARTITION BY company, location, industry,
		total_laid_off, percentage_laid_off, date,
		stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging;

DELETE
FROM layoffs_staging2
WHERE row_num >1

SELECT *
FROM layoffs_staging2;

-- Standardizing the data

-- 	Working on the company column

SELECT DISTINCT company, TRIM(company)
FROM layoffs_staging2;

UPDATE layoffs_staging2
SET company = TRIM(company);

-- Working on the industry column

SELECT DISTINCT industry
FROM layoffs_staging2
ORDER BY 1;

SELECT DISTINCT industry
FROM layoffs_staging2
WHERE industry LIKE 'Crypto%';

UPDATE layoffs_staging2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';

-- Working on the country column

SELECT DISTINCT country, TRIM(country, '.')
FROM layoffs_staging2
WHERE country LIKE 'United States%'
ORDER BY 1;

UPDATE layoffs_staging2
SET country = TRIM(country, '.')
WHERE country LIKE 'United States%';

-- Removing the nulls value

-- 	Working on the nulls value
SELECT *
FROM layoffs_staging2
WHERE industry IS NULL

SELECT *
FROM layoffs_staging2
WHERE company = 'Juul'

SELECT *
FROM layoffs_staging2 AS t1
INNER JOIN layoffs_staging2 AS t2
ON t1.company = t2.company
WHERE t1.industry IS NULL
AND t2.industry IS NOT NULL;

-- Filling up the null values

WITH IndustryUpdates AS (
    SELECT t1.company, t2.industry
    FROM layoffs_staging2 t1
    INNER JOIN layoffs_staging2 t2
    ON t1.company = t2.company
    WHERE t1.industry IS NULL
    AND t2.industry IS NOT NULL
)
UPDATE layoffs_staging2
SET industry = IndustryUpdates.industry
FROM IndustryUpdates
WHERE layoffs_staging2.company = IndustryUpdates.company
AND layoffs_staging2.industry IS NULL;

-- Removing unnecessary null values

SELECT *
FROM layoffs_staging2
WHERE total_laid_off IS NULL 
AND percentage_laid_off IS NULL;

DELETE
FROM layoffs_staging2
WHERE total_laid_off IS NULL 
AND percentage_laid_off IS NULL;

-- Dropping the row_num column used for duplicate removal.

ALTER TABLE layoffs_staging2
DROP COLUMN row_num;



