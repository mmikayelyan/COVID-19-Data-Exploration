/*
Covid 19 Data Exploration 
Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, 
          Creating Views, Converting Data Types
*/

--**********************************************************--

SELECT
  * 
FROM
  covid_deaths 
WHERE
  continent IS NOT NULL 
ORDER BY
  2,
  3,
  4;
  
--**********************************************************--

--Get columns and data types of covid deaths
SELECT
  column_name,
  data_type 
FROM
  information_schema.columns 
WHERE
  table_name = 'covid_deaths';
  
--**********************************************************--

--Get columns and data types of covid vaccinations
SELECT
  column_name,
  data_type 
FROM
  information_schema.columns 
WHERE
  table_name = 'covid_vaccinations';
  
--**********************************************************--

-- Select Data that we are going to be starting with
SELECT
  location,
  date,
  total_cases,
  new_cases,
  total_deaths,
  population 
FROM
  covid_deaths 
WHERE
  continent IS NOT NULL 
ORDER BY
  1,
  2;
  
--**********************************************************--

-- Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in your country
SELECT
  location,
  date,
  total_cases,
  total_deaths,
  (
    total_deaths / total_cases 
  )
  *100 AS death_percentage 
FROM
  covid_deaths 
WHERE
  location LIKE '%Armenia%' 
  AND continent IS NOT NULL 
ORDER BY
  1,
  2;
  
--**********************************************************--

-- Total Cases vs Population
-- Shows what percentage of population infected with Covid
SELECT
  location,
  date,
  population,
  total_cases,
  (total_cases/population)*100 AS pop_infected_percentage
FROM
  covid_deaths 
WHERE
  continent IS NOT NULL 	
ORDER BY
  1,2;
  
--**********************************************************--

-- Countries with Highest Infection Rate compared to Population
SELECT
  location,
  population,
  MAX(total_cases) AS highes_infection_count,
  MAX(total_deaths / population)*100 AS pop_infected_percentage 
FROM
  covid_deaths 
WHERE
  continent IS NOT NULL 	
GROUP BY
  1,
  2 
ORDER BY
  pop_infected_percentage DESC;
  
--**********************************************************--

-- Countries with Highest Death Count per Population
SELECT
  location,
  MAX(total_deaths) AS total_death_count 
FROM
  covid_deaths 
WHERE
  continent IS NOT NULL 	
GROUP BY
  1 
HAVING
  MAX(total_deaths) IS NOT NULL 
ORDER BY
  2 DESC;
  
--**********************************************************--

-- BREAKING THINGS DOWN BY CONTINENT
-- Showing contintents with the highest death count per population
SELECT
  continent,
  MAX(CAST(total_deaths AS INT)) AS total_death_count 
FROM
  covid_deaths 	
WHERE
  continent IS NOT NULL 
GROUP BY
  continent 
ORDER BY
  total_death_count DESC;
  
--**********************************************************--

-- GLOBAL NUMBERS
SELECT
  SUM(new_cases) AS total_cases,
  SUM(new_deaths)AS total_deaths,
  SUM(new_deaths) / SUM(new_cases)*100 AS death_percentage 
FROM
  covid_deaths 	
WHERE
  continent IS NOT NULL; 	
  
--**********************************************************--

-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine
  SELECT
    dea.continent,
    dea.location,
    dea.date,
    dea.population,
    vac.new_vaccinations,
    SUM(vac.new_vaccinations::INTEGER) OVER (PARTITION BY dea.Location 
  ORDER BY
    dea.location, dea.date) AS RollingPeopleVaccinated 
  FROM
    covid_deaths dea 
    JOIN
      covid_vaccinations vac 
      ON dea.location = vac.location 
      AND dea.date = vac.date
  WHERE dea.continent IS NOT NULL 
  ORDER BY
    2,
    3; 		
	
--**********************************************************--

-- Using CTE to perform Calculation on Partition By in previous query
    WITH PopvsVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated) AS 
    (
      SELECT
        dea.continent,
        dea.location,
        dea.date,
        dea.population,
        vac.new_vaccinations,
        SUM(vac.new_vaccinations) OVER (PARTITION BY dea.Location 
      ORDER BY
        dea.location, dea.date) AS RollingPeopleVaccinated
      FROM
        covid_deaths dea 
        JOIN
          covid_vaccinations vac 
          ON dea.location = vac.location 
          AND dea.date = vac.date 
      WHERE
        dea.continent IS NOT NULL 				
    )
    SELECT
      *,
      (
        RollingPeopleVaccinated / Population 
      )
      *100 
    FROM
      PopvsVac 		
	  
--**********************************************************--

-- Using Temp Table to perform Calculation on Partition By in previous query
DROP TABLE IF EXISTS PercentPopulationVaccinated;
CREATE TABLE PercentPopulationVaccinated ( continent VARCHAR(255), 
										  location VARCHAR(255),
										  date TIMESTAMP,
										  population 
										  NUMERIC, 
										  new_vaccinations NUMERIC, 
										  RollingPeopleVaccinated NUMERIC );

INSERT INTO
  PercentPopulationVaccinated 
  SELECT
    dea.continent,
    dea.location,
    dea.date::TIMESTAMP,
    dea.population,
    vac.new_vaccinations,
    SUM(vac.new_vaccinations) OVER (PARTITION BY dea.Location 
  ORDER BY
    dea.location, dea.date) AS RollingPeopleVaccinated 
  FROM
    covid_deaths dea 
    JOIN
      covid_vaccinations vac 
      ON dea.location = vac.location 
      AND dea.date = vac.date 
  WHERE
    dea.continent IS NOT NULL; 		
    
	SELECT *,
      (
        RollingPeopleVaccinated / Population 
      )
      *100 
    FROM
      PercentPopulationVaccinated; 		
	  
--**********************************************************--

-- Creating View to store data for later visualizations
      DROP VIEW IF EXISTS PercentPopulationVaccinated_view; 
	  CREATE View PercentPopulationVaccinated_view AS 
      SELECT
        dea.continent,
        dea.location,
        dea.date,
        dea.population,
        vac.new_vaccinations,
        SUM(vac.new_vaccinations) OVER (PARTITION BY dea.Location 
      ORDER BY
        dea.location, dea.date) AS RollingPeopleVaccinated 				
      FROM
        covid_deaths dea 
        JOIN
          covid_vaccinations vac 
          ON dea.location = vac.location 
          AND dea.date = vac.date 
      WHERE
        dea.continent IS NOT NULL; 