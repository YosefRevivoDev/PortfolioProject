--ALTER TABLE PortfolioProject..CovidVaccinations
--ALTER COLUMN new_vaccinations int;

--SELECT location, date, total_cases, new_cases, total_deaths, population
--FROM CovidDeath
--ORDER BY 1,2

--total cases vs total death
SELECT location, date, total_cases, total_deaths, (total_cases/total_deaths)*100 AS DeathPercentage
FROM PortfolioProject..CovidDeath
WHERE location like '%state%'
ORDER BY 1,2

--total cases vs population
SELECT location,total_cases,population, (total_cases/population)*100 AS ChanceToGotCovid
FROM PortfolioProject..CovidDeath
ORDER BY 1,2

 --countries whit higest infaction rate compared to population
SELECT location,population, MAX(total_cases) as HigestInfactionCount, MAX((total_cases/population))*100 AS ChanceToGotCovid
FROM PortfolioProject..CovidDeath
group by population, location
ORDER BY 4 desc

--countries with higest death count per population
SELECT location,MAX(total_deaths)AS HigestDeath
FROM CovidDeath
where continent is not null
group by location
order by 2 desc

--By Continent
SELECT continent,MAX(total_deaths)AS HigestDeath
FROM CovidDeath
where continent is not null
group by continent
order by 2 desc

--GLOBAL NUMBERS
SELECT date, SUM(new_cases)as TotalCases,SUM(new_deaths)as TotalDeath, SUM(new_deaths)/SUM(new_cases)*100 AS DeathPercentage
FROM PortfolioProject..CovidDeath
WHERE continent is not null and total_cases is not null and total_deaths is not null
group by date
ORDER BY 1,2

-- Without date
SELECT SUM(new_cases)as TotalCases,SUM(new_deaths)as TotalDeath, SUM(new_deaths)/SUM(new_cases)*100 AS DeathPercentage
FROM PortfolioProject..CovidDeath
WHERE continent is not null and total_cases is not null and total_deaths is not null
ORDER BY 1,2


select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
sum(CAST(vac.new_vaccinations AS bigint)) over (partition by dea.location order by dea.location, dea.date ROWS UNBOUNDED PRECEDING)
as RollingPeopleVaccinations
from PortfolioProject..CovidDeath dea
join PortfolioProject..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
order by 2,3

--Use cte
with PopvsVac (continent, location,date, population, new_vaccinations, RollingPeopleVaccinations)
as 
(select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
sum(CAST(vac.new_vaccinations AS bigint)) over (partition by dea.location order by dea.location, dea.date ROWS UNBOUNDED PRECEDING)
as RollingPeopleVaccinations
from PortfolioProject..CovidDeath dea
join PortfolioProject..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null and new_vaccinations is not null
--order by 2,3
)
select * , (RollingPeopleVaccinations/population)*100
from PopvsVac

--USE TEMP TABLE
DROP TABLE if exists #PercentPopulationVaccinated
create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_Vaccinations numeric,
RollingPeopleVaccinated numeric
)
insert into #PercentPopulationVaccinated
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
sum(CAST(vac.new_vaccinations AS bigint)) over (partition by dea.location order by dea.location, dea.date ROWS UNBOUNDED PRECEDING)
as RollingPeopleVaccinations
from PortfolioProject..CovidDeath dea
join PortfolioProject..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
--where dea.continent is not null
--order by 2,3
select * , (RollingPeopleVaccinated/population)*100 
from #PercentPopulationVaccinated

-- creating view to store data for later visualizations

create view PercentPopulationVaccinated as

select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
sum(CAST(vac.new_vaccinations AS bigint)) over (partition by dea.location order by dea.location, dea.date ROWS UNBOUNDED PRECEDING)
as RollingPeopleVaccinations
from PortfolioProject..CovidDeath dea
join PortfolioProject..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
--order by 2,3

select *
from PercentPopulationVaccinated