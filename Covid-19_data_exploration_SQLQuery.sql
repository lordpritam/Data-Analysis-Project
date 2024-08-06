/*
Covid 19 Data Exploration 

Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

*/


USE DataAnalysisProject;
GO

select *
from DataAnalysisProject..CovidDeaths
where location = 'world'
order by 3,4;


--Select Data that we are going to be using.

select location, date, total_cases, new_cases, total_deaths, population
from DataAnalysisProject..CovidDeaths
order by 1,2;


-- checking data types of all columns.
SELECT 
    COLUMN_NAME,
    DATA_TYPE
FROM 
    INFORMATION_SCHEMA.COLUMNS
WHERE 
    TABLE_NAME = 'CovidDeaths' AND 
    COLUMN_NAME IN ('location', 'date', 'total_cases', 'new_cases', 'total_deaths', 'population');


-- all the coloumns in our table is of varchr data type so we will convert all coloumns to their respective data type.

ALTER TABLE CovidDeaths
ALTER COLUMN date DATE;

ALTER TABLE CovidDeaths
ALTER COLUMN total_cases bigint;

ALTER TABLE CovidDeaths
ALTER COLUMN new_cases bigint;

ALTER TABLE CovidDeaths
ALTER COLUMN total_deaths bigint;

ALTER TABLE CovidDeaths
ALTER COLUMN new_deaths bigint;

ALTER TABLE CovidDeaths
ALTER COLUMN population bigint;
                                                                                                                                                                                                                                                                                      


-- total case vs total deaths

Select Location, date, total_cases,total_deaths, (cast(total_deaths as float) / nullif(total_cases,0))*100 
as DeathPercentage
From DataAnalysisProject..CovidDeaths
Where location like 'india'
and continent is not null 
order by 1,2

/* we converted total_deaths to float beacuse, If total_cases and total_deaths are both integers, dividing one integer by
another in many SQL dialects results in an integer division, which truncates the decimal part.
For example, if total_deaths is 5 and total_cases is 100, the division 5/100 would result in 0 rather than 0.05 because 
integer division does not include decimal places.

NULLIF(total_cases, 0): Prevents division by zero by returning NULL if total_cases is 0.
This way, the division will return NULL instead of causing an error. */



-- total cases vs population
-- shows what percentage of population are infected. 
select location, date, total_cases, population, (cast(total_cases as float) / population) * 100 as PercentPopInfected
from DataAnalysisProject..covidDeaths
--where location like '%india%'
order by 1,2;

select location, population,date, max(total_cases) as highest_infection_count, max(cast(total_cases as float) / population) * 100 as PercentPopInfected
from DataAnalysisProject..CovidDeaths
where location not in ('European union', 'High Income', 'Europe', 'Oceania', 'South America', 'Upper middle income', 'world',
'lower middle', 'income', 'africa', 'low income','asia', 'england', 'hong kong', 'wales','scotland','northern ireland','macao',
'western sahara', 'Northern Cyprus', 'Taiwan')
group by location, population, date
order by PercentPopInfected desc;


-- Countries with Highest Infection Rate compared to Population

select location, population, max(total_cases) as highest_infection_count, max(cast(total_cases as float) / population) * 100 as PercentPopInfected
from DataAnalysisProject..CovidDeaths
where location not in ('European union', 'High Income', 'Europe', 'Oceania', 'South America', 'Upper middle income', 'world',
'lower middle', 'income', 'africa', 'low income','asia', 'england', 'hong kong', 'wales','scotland','northern ireland','macao',
'western sahara', 'Northern Cyprus', 'Taiwan')
group by location, population
order by PercentPopInfected desc;


-- countries with highest death counts per population
select location, max(total_deaths) as total_death_count
from DataAnalysisProject..CovidDeaths
where continent is not null
group by location
order by total_death_count desc;


-- BREAKING THINGS DOWN BY CONTINENT

-- Showing contintents with the highest death count per population

select continent, sum(new_deaths) as total_death_count
from DataAnalysisProject..CovidDeaths
WHERE continent IS NOT NULL AND continent <> ''
group by continent
order by total_death_count desc;


--Total global cases, deaths and their percentage.

select sum(new_cases) as Total_GlobalCases, sum(cast(new_deaths as float)) as Total_GlobalDeaths,
SUM(cast(new_deaths as float))/SUM(new_Cases)*100 as Global_DeathPercentage
from DataAnalysisProject..CovidDeaths
where location = 'world' and continent is not null
 
 /* reason for location = 'world' because when we did sum on new cases it included new cases 
 + world and country cases also so to eliminate that we filtered by 'world' only. */



ALTER TABLE DataAnalysisProject..CovidVaccinations
ALTER COLUMN date DATE;


ALTER TABLE DataAnalysisProject..CovidVaccinations
ALTER COLUMN new_vaccinations float;


 -- Showing Percentage of Population that has recieved at least one Covid Vaccine

 select d.continent, d.location, d.date, d.population, v.new_vaccinations,
 sum(convert(bigint, v.new_vaccinations)) over (partition by d.location order by d.location, d.date) as Rolling_people_vacc
 from DataAnalysisProject..CovidDeaths d 
 join DataAnalysisProject..CovidVaccinations v
 on d.location = v.location and d.date = v.date
 where d.continent is not null
 order by 2,3


 
 -- Using CTE to perform Calculation on Partition By in previous query


 With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, Rolling_people_vacc)
as
(
 select d.continent, d.location, d.date, d.population, v.new_vaccinations,
 sum(v.new_vaccinations) over (partition by d.location order by d.location, d.date) as Rolling_people_vacc
 from DataAnalysisProject..CovidDeaths d 
 join DataAnalysisProject..CovidVaccinations v
 on d.location = v.location and d.date = v.date
 where d.continent is not null
 )

 select *, (Rolling_people_vacc/Population)*100
From PopvsVac
--where Location = 'india'
--order by 2,3



-- Using Temp Table to perform Calculation on Partition By in previous query

create table #Percent_pop_vacc
( continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
Rolling_people_vacc numeric
)

insert into #Percent_pop_vacc
select d.continent, d.location, d.date, d.population, v.new_vaccinations,
 sum(v.new_vaccinations) over (partition by d.location order by d.location, d.date) as Rolling_people_vacc
 from DataAnalysisProject..CovidDeaths d 
 join DataAnalysisProject..CovidVaccinations v
 on d.location = v.location and d.date = v.date
 where d.continent is not null

 select *, (Rolling_people_vacc/Population)*100
From #Percent_pop_vacc



-- create a view to store data for later visualization

create view Percent_pop_vacc as
select d.continent, d.location, d.date, d.population, v.new_vaccinations,
sum(v.new_vaccinations) over (partition by d.location order by d.location, d.date) as Rolling_people_vacc
from DataAnalysisProject..CovidDeaths d 
 join DataAnalysisProject..CovidVaccinations v
 on d.location = v.location and d.date = v.date
 where d.continent is not null

