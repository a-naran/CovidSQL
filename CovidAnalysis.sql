--Checking correct data is displayed when calling table
SELECT *
FROM CovidProject..CovidDeaths
ORDER BY 3,4;

--WHERE continent  is NULL => values for continents not countries
--Select data to be used
SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM CovidProject..CovidDeaths
ORDER BY 1,2;

--Total Cases vs Total Deaths (Mortaliy Rate)
SELECT Location, date, total_cases, new_cases, total_deaths, (total_deaths/total_cases) * 100 AS DeathPercentage
FROM CovidProject..CovidDeaths
ORDER BY 1,2;

--Total Cases vs Population 
SELECT Location, date, total_cases, population, (total_cases/population) *100 AS PercentPopulationInfected
FROM CovidProject..CovidDeaths
ORDER BY 1,2;

--Country with highest infection rate compared to population
SELECT Location, Max(total_cases) AS HighestInfectionCount, population, Max((total_cases/population)) *100 AS PercentPopulationInfected
FROM CovidProject..CovidDeaths
GROUP BY Location, population
ORDER BY PercentPopulationInfected DESC;

-- Countries with highest death count per population
SELECT Location, MAX(cast(total_deaths AS INT)) AS TotalDeathCount
FROM CovidProject..CovidDeaths
Where continent IS NOT NULL
Group by Location
Order by TotalDeathCount DESC;

--Highest Death Count per Population 
SELECT continent, MAX(cast(total_deaths AS INT)) AS TotalDeathCount
FROM CovidProject..CovidDeaths
Where continent IS NOT NULL
Group by continent
Order by TotalDeathCount DESC;


--GLOBAL NUMBERS
SELECT date, SUM(new_cases) AS total_cases, SUM(cast(new_deaths AS INT)) AS total_deaths, SUM(CAST(new_deaths AS INT)) / SUM(new_cases) * 100 AS DeathPercentage
FROM CovidProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1,2;

--JOINS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingVaccinatedPeoplee
FROM CovidProject..CovidDeaths dea
JOIN CovidProject..CovidVaccinations vac
	ON dea.Location = vac.Location
	and dea.date = vac.date
ORDER BY 2,3;


--USE CTE	
WITH PopsvsVac (Continent, Location, Date, Population, new_vaccinations, RollingVaccinatedPeople) 
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingVaccinatedPeople
FROM CovidProject..CovidDeaths dea
JOIN CovidProject..CovidVaccinations vac
	ON dea.location = vac.location 
	and dea.date = vac.date
WHERE dea.continent is not null
--ORDER BY 2,3
)
SELECT *, (RollingVaccinatedPeople/Population) * 100
FROM PopsvsVac

--USE TEMP TABLE
DROP TABLE if exists #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255), 
Date datetime,
Population numeric,
New_Vaccinations numeric,
RollingVaccinatedPeople numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingVaccinatedPeople
FROM CovidProject..CovidDeaths dea
JOIN CovidProject..CovidVaccinations vac
	ON dea.location = vac.location 
	and dea.date = vac.date
--WHERE dea.continent is not null
--ORDER BY 2,3

SELECT *, (RollingVaccinatedPeople/Population) * 100
FROM #PercentPopulationVaccinated
ORDER BY 2,3

--Creating view to store data for late visualizations
DROP VIEW if exists PercentPopulationVaccinated

USE CovidProject
GO
CREATE VIEW PercentPopulationVaccinated as
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingVaccinatedPeople
FROM CovidProject..CovidDeaths dea
JOIN CovidProject..CovidVaccinations vac
	ON dea.location = vac.location 
	and dea.date = vac.date
WHERE dea.continent is not null
--ORDER BY 2,3