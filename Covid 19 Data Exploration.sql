use DataExplorationProject

select * 
from CovidDeaths
order by 3, 4

select * 
from CovidVaccinations
order by 3, 4

-- Select Data that I will going to be using
select location, date, total_cases, new_cases, total_deaths, population
from CovidDeaths
order by 1, 2

-- Looking at Total Cases vs Total Deaths For India
select location, 
		date, 
		total_cases, 
		total_deaths,
		DeathPercentage = ROUND((total_deaths/total_cases)*100,2) 
from CovidDeaths
where location = 'India' 
order by 1, 2

-- Countries with Highest Infection Rate compared to Population
select	location,
		population,
		[Highest Infection Rate] = MAX(total_cases)
from CovidDeaths
--where location = 'India'
group by location, population
order by 3 desc

-- Countries with Highest Death Count per Population
select	location,
		[Highest Death Count] = MAX(cast(total_deaths as bigint))
from CovidDeaths
--where location = 'India'
where continent is not null
group by location
order by [Highest Death Count] desc

-- Showing contintents with the highest death count per population
select	continent,
		[Highest Death Count] = MAX(cast(total_deaths as bigint))
from CovidDeaths
--where location = 'India'
where continent is not null
group by continent
order by [Highest Death Count] desc

-- Showing contintents with Highest Infection Rate compared to Population
select	continent,
		population,
		[Highest Infection Rate] = MAX(total_cases) 
from CovidDeaths
where continent is not null
group by continent, population
order by 3 desc 

-- GLOBAL NUMBERS
select	date,
		SUM(new_cases) as total_cases,
		SUM(cast(new_deaths as bigint)) as total_deaths,
		round((SUM(cast(new_deaths as bigint))/SUM(new_cases))*100,2) as total_death_percentage
from CovidDeaths
--where location = 'India' and new_cases not like '0%'
where continent is not null
group by date
--order by date

-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine
select  d.continent, d.location, d.date, d.population, v.new_vaccinations
		,sum(cast(v.new_vaccinations as int)) as TotalPeopleVaccinated 
		,round((sum(convert(int,v.new_vaccinations)/d.population))*100,2) as [% of Population recieved at least one Covid Vaccine]
from CovidDeaths d, CovidVaccinations v
where d.location = v.location and d.date = v.date and v.new_vaccinations not like '0%' and d.continent is not null
group by d.continent, d.location, d.date, d.population, v.new_vaccinations
order by 2,3

-- USING WINDOWS FUNCTION - Rolling count
select  d.continent, d.location, d.date, d.population, v.new_vaccinations
		,rollingPeopleVaccinated = sum(cast(v.new_vaccinations as bigint)) over(partition by d.location order by d.location, d.date)
		,round((sum(cast(v.new_vaccinations as bigint)) over(partition by d.location order by d.location, d.date)/d.population)*100,2) as [% of Population recieved at least one Covid Vaccine]
from CovidDeaths d, CovidVaccinations v
where d.location = v.location and d.date = v.date and d.continent is not null
order by 2,3

--ERROR_NOTE: i got errors in above query : 
--1.ORDER BY list of RANGE window frame has total size of 1020 bytes. Largest size supported is 900 bytes. so i did this:
--ALTER TABLE [DataExplorationProject].[dbo].[CovidDeaths] ALTER COLUMN [location] nvarchar(150)
--2.:Arithmetic overflow error converting expression to data type int. To solve this i replaced int->bigint

-- Using CTE to perform Calculation on Partition By in previous query
with popvsvac as
(
select  d.continent, d.location, d.date, d.population, v.new_vaccinations
		,TotalPeopleVaccinated = sum(cast(v.new_vaccinations as bigint)) over(partition by d.location order by d.location, d.date)
from CovidDeaths d, CovidVaccinations v		
where d.location = v.location and d.date = v.date and d.continent is not null

)

select *,round(TotalPeopleVaccinated/population*100,2) as [% of Population recieved at least one Covid Vaccine]
from popvsvac
order by 2,3

-- Using Temp Table to perform Calculation on Partition By in previous query

drop table if exists #totalpeoplevaccinated
create table #totalpeoplevaccinated
( continent nvarchar(255) null,
location nvarchar(150) null,
date nvarchar(255) null,
population float null,
new_vaccinations nvarchar(255) null,
TotalPeopleVaccinated numeric
)
insert into #totalpeoplevaccinated

select  d.continent, d.location, d.date, d.population, v.new_vaccinations
		,TotalPeopleVaccinated = sum(cast(v.new_vaccinations as bigint)) over(partition by d.location order by d.location, d.date)
from CovidDeaths d, CovidVaccinations v
where d.location = v.location and d.date = v.date and d.continent is not null

select *, round((TotalPeopleVaccinated/population)*100,2) as [% of Population recieved at least one Covid Vaccine]
from #totalpeoplevaccinated
order by 2,3

-- Creating View to store data 

create view PercentagePopulationVaccinated as

select  d.continent, d.location, d.date, d.population, v.new_vaccinations
		,rollingPeopleVaccinated = sum(cast(v.new_vaccinations as bigint)) over(partition by d.location order by d.location, d.date)
		,round((sum(cast(v.new_vaccinations as bigint)) over(partition by d.location order by d.location, d.date)/d.population)*100,2) as [% of Population recieved at least one Covid Vaccine]
from CovidDeaths d, CovidVaccinations v
where d.location = v.location and d.date = v.date and d.continent is not null

--select * from PercentagePopulationVaccinated order by 2,3

--drop view PercentagePopulationVaccinated

