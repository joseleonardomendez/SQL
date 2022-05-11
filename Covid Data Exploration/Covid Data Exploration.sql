/*
Covid 19 Data Exploration 
Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views
*/


-- World Total Cases 

SELECT SUM(new_cases) AS World_Total_Cases
FROM CovidProject..CovidDeaths

-- World Total Deaths 

SELECT SUM(new_deaths) AS World_Total_Deaths
FROM CovidProject..CovidDeaths

-- Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in your country

SELECT Location, date, total_cases,total_deaths,(total_deaths/total_cases)*100 AS DeathPercentage
FROM CovidProject..CovidDeaths
ORDER BY 1,2

-- Countries with Highest Infection Rate compared to Population

SELECT Location, Population, MAX(total_cases) AS HighestInfectionCount,  MAX((total_cases/population))*100 AS PercentPopulationInfected
FROM CovidProject..CovidDeaths
GROUP BY Location, Population
ORDER BY PercentPopulationInfected DESC


-- Countries with Highest Death Count per Population

SELECT Location, MAX(Total_deaths) AS TotalDeathCount
FROM CovidProject..CovidDeaths
GROUP BY Location
ORDER BY TotalDeathCount DESC

-- BREAKING DOWN BY CONTINENT
-- Showing contintents with the highest death count per population

SELECT continent, MAX(Total_deaths) AS TotalDeathCount
FROM CovidProject..CovidDeaths
GROUP BY continent
ORDER BY TotalDeathCount DESC

-- GLOBAL NUMBERS

SELECT SUM(new_cases) AS total_cases, SUM(new_deaths) AS total_deaths, (SUM(new_deaths)/SUM(New_Cases))*100 as DeathPercentage
FROM CovidProject..CovidDeaths
ORDER BY 1,2


-- Total Population vs People Vaccinated
-- Shows Percentage of Population Fully Vaccinated

SELECT deaths.continent, deaths.location, deaths.date, deaths.population, people_fully_vaccinated
, MAX(vaccinations.people_fully_vaccinated) OVER (PARTITION BY deaths.Location ORDER BY deaths.location, deaths.Date) as PeopleFullyVaccinated
--, (PeopleFullyVaccinated/population)*100
FROM CovidProject..CovidDeaths deaths
JOIN CovidProject..CovidVaccinations vaccinations
	ON deaths.location = vaccinations.location
	AND deaths.date = vaccinations.date
ORDER BY 2,3

-- Using CTE to perform Calculation on Partition By in previous query

WITH PopulationvsPeopleFullyVaccinated (Continent, Location, Date, Population, people_fully_vaccinated, PeopleFullyVaccinated)
AS
(
SELECT deaths.continent, deaths.location, deaths.date, deaths.population, people_fully_vaccinated
, MAX(vaccinations.people_fully_vaccinated) OVER (PARTITION BY deaths.Location ORDER BY deaths.location, deaths.date) AS PeopleFullyVaccinated
--, (PeopleFullyVaccinated/population)*100
FROM CovidProject..CovidDeaths deaths
JOIN CovidProject..CovidVaccinations vaccinations
	ON deaths.location = vaccinations.location
	AND deaths.date = vaccinations.date
)
SELECT *, (PeopleFullyVaccinated/Population)*100
FROM PopulationvsPeopleFullyVaccinated


-- Using Temp Table to perform Calculation on Partition By in previous query

DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
People_fully_vaccinated numeric,
PeopleFullyVaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT deaths.continent, deaths.location, deaths.date, deaths.population, people_fully_vaccinated
, MAX(vaccinations.people_fully_vaccinated) OVER (PARTITION BY deaths.Location ORDER BY deaths.location, deaths.date) AS PeopleFullyVaccinated
--, (PeopleFullyVaccinated/population)*100
FROM CovidProject..CovidDeaths deaths
JOIN CovidProject..CovidVaccinations vaccinations
	ON deaths.location = vaccinations.location
	AND deaths.date = vaccinations.date

SELECT *, (PeopleFullyVaccinated/Population)*100
FROM #PercentPopulationVaccinated


-- Creating View to store data for later visualizations

CREATE VIEW Percent_Population_Vaccinated AS
SELECT deaths.continent, deaths.location, deaths.date, deaths.population, vaccinations.people_fully_vaccinated
, MAX(vaccinations.people_fully_vaccinated) OVER (PARTITION BY deaths.Location Order BY deaths.location, deaths.Date) AS PeopleFullyVaccinated
--, (PeopleFullyVaccinated/population)*100
FROM CovidProject..CovidDeaths deaths
JOIN CovidProject..CovidVaccinations vaccinations
	ON deaths.location = vaccinations.location
	AND deaths.date = vaccinations.date