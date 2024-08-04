-- select data we are going to use

SELECT [location],[date],total_cases, new_cases,total_deaths,population
FROM projectPortfolio..CovidDeaths 
ORDER BY 1,2 


-- EVERYWHERE YOU CAN REPLACE LOCATION WITH CONTINENT AND YOU CAN GET DIVISION BASED ON CONTINENT THEN

-- total cases vs total deaths or likelihood of dying if you get covid

SELECT 
    [location],
    total_cases,
    total_deaths,
    (total_deaths/total_cases)*100 AS deathRatio
FROM projectPortfolio..CovidDeaths
WHERE [location] LIKE '%states%'
ORDER BY
    [location]


-- total cases vs population

SELECT
    [location],
    [date],
    total_cases,
    population,
    (total_cases/population)*100 AS affectedRatioInPopulation
FROM projectPortfolio..CovidDeaths
ORDER BY
    [location]


--highest infection rate compared to population

SELECT
    [location],
    MAX(total_cases) AS HighestInfectionCount,
    MAX(total_cases/population)*100 AS PercentPopulationInfected
FROM projectPortfolio..CovidDeaths
GROUP BY
    [location]
ORDER BY
    [PercentPopulationInfected] DESC


-- countries with highest death count per population

SELECT
    [location],
    MAX(total_deaths) AS HighestDeathCount,
    MAX(total_deaths/population)*100 AS PercentPopulationDeath
FROM projectPortfolio..CovidDeaths
WHERE continent is not NULL 
GROUP BY
    [location]
ORDER BY    
    HighestDeathCount DESC


-- showing continents with highest death count

SELECT
    continent,
    MAX(total_deaths) as HighestDeathCountInContinent
FROM projectPortfolio..CovidDeaths
WHERE continent is not null
GROUP BY 
    continent
ORDER BY    
    HighestDeathCountInContinent DESC


-- global numbers

SELECT
    [date],
    SUM(new_cases) as totalCases,
    SUM(new_deaths) as totalDeaths,
    SUM(new_deaths)/SUM(new_cases)*100 AS deathPercentage
FROM projectPortfolio..CovidDeaths
WHERE new_cases != 0 
GROUP BY [date]
ORDER BY  
    1 


-- joining covid deaths and covid vaccinations table
-- looking at total population vs vaccination
-- using sum/order statement to get rolling people vaccinated by using new_vaccinations column
-- using Create View to store the table elsewhere
/*
Create View PercentPopulationVaccinated as
SELECT 
    cvd.continent,
    cvd.[location],
    cvd.[date],
    cvd.population,
    cvv.new_vaccinations,
    SUM(cvv.new_vaccinations) OVER (PARTITION BY cvd.location ORDER BY cvd.[location], cvd.date) AS rolling_people_vaccinated
FROM projectPortfolio..CovidDeaths as cvd
JOIN projectPortfolio..[Covid Vaccinations] as cvv --full outer join and normal join are the same
 ON cvd.[location] = cvv.[location] AND cvd.[date] = cvv.[date]
WHERE cvd.continent is not NULL
-- ORDER BY 1,2
*/


-- now using the above as a temp table to find the total vaccinations (using the end of rolling people)


WITH rollingVaccinationsFilled AS (
    SELECT 
        cvd.continent,
        cvd.[location],
        cvd.[date],
        cvd.population,
        cvv.new_vaccinations,
        SUM(cvv.new_vaccinations) OVER (PARTITION BY cvd.location ORDER BY cvd.[location], cvd.date) AS rolling_people_vaccinated
    FROM projectPortfolio..CovidDeaths as cvd
    JOIN projectPortfolio..[Covid Vaccinations] as cvv --full outer join and normal join are the same
    ON cvd.[location] = cvv.[location] AND cvd.[date] = cvv.[date]
    WHERE cvd.continent is not NULL
)
SELECT 
    *,
    (temp.rolling_people_vaccinated/temp.population)*100 AS percentPeopleVaccinated
FROM rollingVaccinationsFilled AS temp
-- GROUP BY temp.location
