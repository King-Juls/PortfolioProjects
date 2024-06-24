SELECT *
FROM covid_deaths
WHERE continent IS NOT NULL
ORDER BY 3,4;

SELECT *
FROM covidvaccinations
ORDER BY 3,4;

-- Select Data to explore in covid_deaths table

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM covid_deaths
WHERE continent IS NOT NULL
ORDER BY 1,2;

-- Looking at total cases vs total deaths in Nigeria

SELECT location, date, total_cases, total_deaths, 
	(total_deaths::NUMERIC/total_cases::NUMERIC)*100 AS death_percentage
FROM covid_deaths
WHERE location = 'Nigeria'
ORDER BY 1,2;

-- Total Cases vs Population
-- shows the percentage of population with covid in Nigeria

SELECT location, date,  population, total_cases,
	(total_cases::NUMERIC/population::NUMERIC)*100 AS percent_population_infected
FROM covid_deaths
WHERE location = 'Nigeria'
AND continent IS NOT NULL
ORDER BY 1,2;

SELECT location, population, date, MAX(total_cases) AS ,
	(total_cases::NUMERIC/population::NUMERIC)*100 AS percent_population_infected
FROM covid_deaths
WHERE location = 'Nigeria'
AND continent IS NOT NULL
ORDER BY 1,2;


-- Looking at countries with Highest infection Rate compared to Population

SELECT location, population, date, MAX(total_cases) AS highest_infected_count,
	MAX((total_cases::NUMERIC/population::NUMERIC))*100 AS percent_population_infected
FROM covid_deaths
-- WHERE continent IS NOT NULL
GROUP BY 1,2,3
ORDER BY percent_population_infected DESC;

-- Showing the country with highest death rate per population

SELECT location, SUM(total_deaths) AS total_death_count
FROM covid_deaths
WHERE continent IS NOT NULL
AND total_deaths IS NOT NULL
GROUP BY location
ORDER BY total_death_count DESC;

-- LET'S BREAK IT DOWN BY CONTINENT
-- Showing continents with highest death count per population

SELECT continent, MAX(total_deaths) AS total_death_count
FROM covid_deaths
WHERE continent IS NOT NULL
GROUP BY 1
ORDER BY total_death_count DESC;

-- new cases

SELECT SUM(new_cases) AS total_cases, SUM(new_deaths::INT) AS total_deaths, 
		SUM(new_deaths::NUMERIC)/SUM(new_cases::NUMERIC)*100 AS death_percentage
FROM covid_deaths
WHERE continent IS NOT NULL
ORDER BY 1,2;

-- Looking at moving totals of population vaccinated per country

SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations,
		SUM(v.new_vaccinations::INT) OVER (
			PARTITION BY d.location
			ORDER BY d.location, d.date) AS rolling_people_vaccinated
FROM covid_deaths AS d
-- Joining the covid_death table to the covidvaccinations table
INNER JOIN covidvaccinations AS v
	ON d.location = v.location
	AND d.date = v.date
WHERE d.continent IS NOT NULL AND v.new_vaccinations IS NOT NULL
ORDER BY 2,3;

-- Looking at the percentage of moving totals of the population vaccinated

WITH PopvsVac AS
(
	SELECT d.continent, d.location, d.date, d.population, 
			v.new_vaccinations,
		SUM(v.new_vaccinations::INT) OVER (
			PARTITION BY d.location
			ORDER BY d.location, d.date) AS rolling_people_vaccinated
FROM covid_deaths AS d
INNER JOIN covidvaccinations AS v
	ON d.location = v.location
	AND d.date = v.date
WHERE d.continent IS NOT NULL
)
SELECT *, (rolling_people_vaccinated::numeric/population::numeric)*100
FROM PopvsVac;

-- TEMP TABLE

DROP TABLE IF exists PercentPopulationVaccinated
CREATE TEMPORARY TABLE PercentPopulationVaccinated 
(
    continent VARCHAR(255),
    location VARCHAR(255),
    date DATE,
    population NUMERIC,
    new_vaccinations NUMERIC,
    rolling_people_vaccinated NUMERIC
);

-- Insert data into the temporary table
INSERT INTO PercentPopulationVaccinated
SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations,
       SUM(v.new_vaccinations) OVER (
           PARTITION BY d.location
           ORDER BY d.date
       ) AS rolling_people_vaccinated
FROM covid_deaths AS d
INNER JOIN covidvaccinations AS v
ON d.location = v.location AND d.date = v.date
WHERE d.continent IS NOT NULL;

-- Select data from the temporary table
SELECT *,
       (rolling_people_vaccinated / population) * 100 AS percent_population_vaccinated
FROM PercentPopulationVaccinated;

-- Creating view to store data for data visualization

CREATE VIEW PercentPopulationVaccinated AS
SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations,
       SUM(v.new_vaccinations) OVER (
           PARTITION BY d.location
           ORDER BY d.date
       ) AS rolling_people_vaccinated
FROM covid_deaths AS d
INNER JOIN covidvaccinations AS v
ON d.location = v.location AND d.date = v.date
WHERE d.continent IS NOT NULL

-- Number of deaths per location

SELECT location, SUM(new_deaths) AS total_death_count
FROM covid_deaths
WHERE continent IS NULL
AND location NOT IN ('World', 'European Union', 'International')
GROUP BY location
ORDER BY total_death_count DESC

-- Number of people vaccinated by loaction

SELECT location, SUM(people_vaccinated) AS sum_of_people_vaccinated
FROM covidvaccinations
WHERE continent IS NULL
AND location NOT IN ('World', 'European Union', 'International')
GROUP BY location
ORDER BY sum_of_people_vaccinated DESC









