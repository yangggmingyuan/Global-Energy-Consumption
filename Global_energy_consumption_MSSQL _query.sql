--1. Data Cleanup and Formatting


--1.1 Renaming Columns for Accessibility

-- Alters column names to a more accessible format, replacing spaces and parentheses with underscores.
EXEC sp_rename '[global_energy_consumption$].[Total Energy Consumption (TWh)]', 'Total_Energy_Consumption_TWh', 'COLUMN';
EXEC sp_rename '[global_energy_consumption$].[Per Capita Energy Use (kWh)]', 'Per_Capita_Energy_Use_kWh', 'COLUMN';
EXEC sp_rename '[global_energy_consumption$].[Renewable Energy Share (%)]', 'Renewable_Energy_Share_Percent', 'COLUMN';
EXEC sp_rename '[global_energy_consumption$].[Fossil Fuel Dependency (%)]', 'Fossil_Fuel_Dependency_Percent', 'COLUMN';
EXEC sp_rename '[global_energy_consumption$].[Industrial Energy Use (%)]', 'Industrial_Energy_Use_Percent', 'COLUMN';
EXEC sp_rename '[global_energy_consumption$].[Household Energy Use (%)]', 'Household_Energy_Use_Percent', 'COLUMN';
EXEC sp_rename '[global_energy_consumption$].[Carbon Emissions (Million Tons)]', 'Carbon_Emissions_Million_Tons', 'COLUMN';
EXEC sp_rename '[global_energy_consumption$].[Energy Price Index (USD/kWh)]', 'Energy_Price_Index_USD_per_kWh', 'COLUMN';

--1.2 Transforming Industrial and Household Energy Use into Exact Numbers

-- Add new columns for exact energy consumption values.
ALTER TABLE [dbo].[global_energy_consumption$]
ADD Industrial_Energy_Use_kWh FLOAT, Household_Energy_Use_kWh FLOAT;

-- Convert Industrial Energy Use Percentage to an absolute number.
UPDATE [dbo].[global_energy_consumption$]
SET Industrial_Energy_Use_kWh = ROUND((Industrial_Energy_Use_Percent / 100) * Total_Energy_Consumption_TWh, 2);

-- Convert Household Energy Use Percentage to an absolute number.
UPDATE [dbo].[global_energy_consumption$]
SET Household_Energy_Use_kWh = ROUND((Household_Energy_Use_Percent / 100) * Total_Energy_Consumption_TWh, 2);

-------------------------------------------------------------------------------------------------------------------------------------

--2. Data Exploration

--2.1 Checking Total Records per Country

SELECT Country, COUNT(*) AS Total_Records
FROM [dbo].[global_energy_consumption$]
GROUP BY Country
ORDER BY Total_Records DESC;

--2.2 Checking Total Energy Consumption per Country

SELECT Country, ROUND(SUM(Total_Energy_Consumption_TWh), 0) AS Total_Energy_Consumption
FROM [dbo].[global_energy_consumption$]
GROUP BY Country
ORDER BY Total_Energy_Consumption DESC;

------------------------------------------------------------------------------------------------------------------------------------

--3. Top3 Energy Consumers by Category

SELECT TOP 3 
    Country, 
    ROUND(SUM(Per_Capita_Energy_Use_kWh), 0) AS Total_Energy_Consumption_Per_Capita
FROM [dbo].[global_energy_consumption$]
GROUP BY Country
ORDER BY Total_Energy_Consumption_Per_Capita DESC;



--3.2 Top 3 Countries by Industrial Energy Use

SELECT TOP 3 
	Country,
	ROUND(SUM(Industrial_Energy_Use_kWh), 0) AS Total_Industrial_Energy_Use
FROM [dbo].[global_energy_consumption$]
GROUP BY Country
ORDER BY Total_Industrial_Energy_Use DESC;

--3.3 Top 3 Countries by Household Energy Use

SELECT TOP 3
	Country,
	ROUND(SUM(Household_Energy_Use_kWh), 0) AS Total_Household_Energy_Use
FROM [dbo].[global_energy_consumption$]
GROUP BY Country
ORDER BY Total_Household_Energy_Use DESC;

------------------------------------------------------------------------------------------------------------------------------------

--4. Impact of Energy Prices on Energy Consumption (China, 2010-2020)

WITH YearlyEnergy AS (
    -- Aggregate energy data per year
    SELECT 
        Country,
        Year,
        SUM(Total_Energy_Consumption_TWh) AS Total_Energy_Sum_TWh,
        AVG(Energy_Price_Index_USD_per_kWh) AS Avg_Energy_Price_USD_per_kWh
    FROM [dbo].[global_energy_consumption$]
    WHERE Year BETWEEN 2010 AND 2020 AND Country = 'China'
    GROUP BY Country, Year
),
RankedData AS (
    -- Rank each year based on total energy consumption
    SELECT 
        Country,
        Year,
        Total_Energy_Sum_TWh,
        Avg_Energy_Price_USD_per_kWh,
        RANK() OVER (ORDER BY Total_Energy_Sum_TWh DESC) AS Yearly_Rank
    FROM YearlyEnergy
)
-- Retrieve results
SELECT 
    Country,
    Year,
    ROUND(Total_Energy_Sum_TWh, 0) AS Rounded_Total_Energy_Consumption_TWh,
    ROUND(Avg_Energy_Price_USD_per_kWh, 2) AS Avg_Energy_Price_USD_per_kWh,
    Yearly_Rank
FROM RankedData
ORDER BY Avg_Energy_Price_USD_per_kWh, Yearly_Rank;


--Observation:

--From the results, we can see that energy prices may have influenced energy consumption in China between 2010 and 2020.

------------------------------------------------------------------------------------------------------------------------------------

--5. Impact of Time on Renewable Energy Share

SELECT 
    Country,
    Year,
    CONCAT(ROUND(AVG(Renewable_Energy_Share_Percent), 2), '%') AS Avg_Renewable_Energy_Share
FROM [dbo].[global_energy_consumption$]
WHERE Country = 'China' AND Year BETWEEN 2000 AND 2020
GROUP BY Country, Year
ORDER BY Year;

--Observation:

--Time does not have a significant impact on China's renewable energy share, as the values remain relatively stable.

------------------------------------------------------------------------------------------------------------------------------------

--6. Carbon Emissions & Fossil Fuel Dependency Analysis

--6.1 Countries with the Highest Carbon Emissions

SELECT 
    Country,
    SUM(Carbon_Emissions_Million_Tons) AS Total_Emission,
    CASE 
        WHEN SUM(Carbon_Emissions_Million_Tons) > 2600000 THEN 'High Emission'
        WHEN SUM(Carbon_Emissions_Million_Tons) BETWEEN 2500000 AND 2600000 THEN 'Middle Emission'
        ELSE 'Low Emission' 
    END AS Emission_Category
FROM [dbo].[global_energy_consumption$]
GROUP BY Country
ORDER BY Total_Emission DESC;

--6.2 Year When China Had the Highest Carbon Emissions

SELECT TOP 1
	Country,
	Year, 
	MAX(Carbon_Emissions_Million_Tons) AS Highest_Carbon_Emissions
FROM [dbo].[global_energy_consumption$]
WHERE Country = 'China'
GROUP BY Year,Country
ORDER BY Highest_Carbon_Emissions DESC;

--6.3 Year When China Had the Highest Fossil Fuel Dependency

SELECT TOP 1
	Country,
	Year,
	MAX(Fossil_Fuel_Dependency_Percent) AS Highest_Fossil_Fuel_Dependency
FROM [dbo].[global_energy_consumption$]
WHERE Country = 'China'
GROUP BY Year,Country
ORDER BY Highest_Fossil_Fuel_Dependency DESC;

--6.4 Year When China Had the Lowest Fossil Fuel Dependency

SELECT 
	Year, 
	Country,
	MIN(Fossil_Fuel_Dependency_Percent) AS Lowest_Fossil_Fuel_Dependency
FROM [dbo].[global_energy_consumption$]
WHERE Country = 'China'
GROUP BY Year, Country
ORDER BY Lowest_Fossil_Fuel_Dependency ASC;

------------------------------------------------------------------------------------------------------------------------------------

--7. Classifying Energy Consumption Levels
--(I have defined that if Total_Energy_Consumption_TWh greater than 5200000 THEN 'High Consumption'
					  --if Total_Energy_Consumption_TWh BETWEEN 5000000 AND 5200000 THEN 'Moderate Consumption'
					 --else then'Low Consumption')

SELECT 
    Country,
    ROUND(SUM(Total_Energy_Consumption_TWh), 0) AS Total_Energy,
    CASE 
        WHEN SUM(Total_Energy_Consumption_TWh) > 5200000 THEN 'High Consumption'
        WHEN SUM(Total_Energy_Consumption_TWh) BETWEEN 5000000 AND 5200000 THEN 'Moderate Consumption'
        ELSE 'Low Consumption'
    END AS Energy_Consumption_Category
FROM [dbo].[global_energy_consumption$]
GROUP BY Country
ORDER BY Total_Energy DESC;














