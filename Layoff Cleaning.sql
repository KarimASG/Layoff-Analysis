-- show the data 
SELECT * FROM dbo.layoffs

SELECT DISTINCT company FROM dbo.layoffs  

SELECT DISTINCT industry FROM dbo.layoffs  

SELECT DISTINCT location FROM dbo.layoffs  

SELECT DISTINCT stage FROM dbo.layoffs  


-- create temp Table

SELECT * INTO Layoff_1
FROM dbo.layoffs
WHERE 2=1

INSERT INTO dbo.Layoff_1
SELECT * FROM dbo.layoffs



-- check if we found any duplicate 
SELECT * FROM (
SELECT company,industry,date,stage ,ROW_NUMBER() OVER (PARTITION BY company,industry,date,stage ORDER BY company) AS Row_num
FROM dbo.Layoff_1) AS duplicate
WHERE duplicate.Row_num>1

--check the Oda Company and we found that the data is real not duplicated
SELECT * FROM dbo.Layoff_1 WHERE company='Oda'



--final check to go to remove the duplicated columns 
SELECT * FROM (SELECT * ,ROW_NUMBER() OVER (PARTITION BY company,location,industry,total_laid_off,percentage_laid_off,date,stage,country,funds_raised_millions ORDER BY company)AS Row_Num
FROM dbo.Layoff_1) Duplicated WHERE Duplicated.Row_Num>1


--Deleteition Step

WITH Delete_CTE AS (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, date, stage, country, funds_raised_millions
               ORDER BY company
           ) AS Row_Num
    FROM dbo.Layoff_1
)
DELETE FROM Delete_CTE WHERE Row_Num > 1;


-- check again
SELECT * FROM dbo.Layoff_1


-- check the industry values 
SELECT DISTINCT industry FROM dbo.Layoff_1
SELECT * FROM dbo.Layoff_1 WHERE industry IS NULL OR industry=''


--now we will change any '' with Null to be easy to check about it 
UPDATE dbo.Layoff_1 SET	industry =NULL WHERE industry = '' OR industry='Null'


--After check we will Replace the Values of Null 
UPDATE t1
SET t1.industry = t2.industry
FROM dbo.Layoff_1 t1
INNER JOIN dbo.Layoff_1 t2
ON t1.company = t2.company
WHERE t1.industry IS NULL
AND t2.industry IS NOT NULL;


-- Crypto Currency are rewrite without spaces
SELECT DISTINCT industry FROM dbo.Layoff_1 
UPDATE dbo.Layoff_1 SET industry ='Crypto' WHERE industry='CryptoCurrency' OR industry='Crypto Currency'


SELECT * FROM dbo.Layoff_1


--update Country United Status and United Status. to US
SELECT DISTINCT country FROM dbo.Layoff_1 

UPDATE dbo.Layoff_1 SET country = 'US' WHERE country='United States' OR country= 'United States.'



UPDATE dbo.Layoff_1
SET date = TRY_CONVERT(DATE, date, 101);

ALTER TABLE dbo.Layoff_1
ALTER COLUMN date DATE;

DELETE FROM dbo.Layoff_1
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;


UPDATE dbo.Layoff_1 SET total_laid_off=0 WHERE total_laid_off = 'NULL' 

SELECT * FROM dbo.Layoff_1
--Get Max Total Laid off and max Percentage laid off
SELECT MAX(TRY_CAST(total_laid_off AS INT ))[Max Laid Off] FROM dbo.Layoff_1

SELECT MIN(TRY_CAST(total_laid_off AS DECIMAL(10,2 )))[Min Laid Off] FROM dbo.Layoff_1
WHERE percentage_laid_off>0

-- Which companies had 1 which is basically 100 percent of they company laid off
SELECT * FROM dbo.Layoff_1
WHERE percentage_laid_off ='1' AND funds_raised_millions <>'NULL'	
ORDER BY funds_raised_millions DESC


-- Top 5 Companies that have biggest total laid off
SELECT TOP (5) company,CAST(total_laid_off AS INT ) AS [Total Laid Off] FROM dbo.Layoff_1
ORDER BY 2 desc;


---- Companies with the most Total Layoffs
SELECT TOP(10) company,SUM(CAST(total_laid_off AS INT)) AS [Total Laid off]
FROM dbo.Layoff_1
GROUP BY company 
ORDER BY 2 desc

---- Locaations with the most Total Layoffs
SELECT TOP(10) location,SUM(CAST(total_laid_off AS INT ))[Total Laid off] FROM dbo.Layoff_1
GROUP BY location 
ORDER BY 2 DESC	


-- Country with the most Total Layoffs
SELECT TOP(10)country,SUM(CAST(total_laid_off AS INT))[Total Laid Offs] FROM dbo.Layoff_1
GROUP BY country 
ORDER BY 2 DESC	

-- Year with the most Total Layoffs
SELECT YEAR(date) AS Date,SUM(CAST(total_laid_off AS int))[Total Laid Off] FROM dbo.Layoff_1 
WHERE Date IS NOT NULL	
GROUP BY YEAR(date)
ORDER BY 2 DESC	


--Industries with the most Total Layoffs
SELECT industry,SUM(CAST(total_laid_off AS int))[Total Laid Off] FROM dbo.Layoff_1
GROUP BY industry 
ORDER BY 2 DESC



-- Company over years with the most Total Layoffs 

WITH Company_Years AS (
SELECT company,YEAR(date) [Dates] , SUM(CAST(total_laid_off AS int))[Total Laid Off] FROM dbo.Layoff_1 
GROUP BY company,YEAR(date)
),
Ranked_Company AS (
SELECT *,DENSE_RANK() OVER (PARTITION BY  Dates ORDER BY [Total Laid Off] )AS Ranked  FROM Company_Years
)
SELECT * FROM Ranked_Company WHERE Ranked_Company.Ranked<=3 
AND Dates IS NOT NULL 
ORDER BY Dates ASC,[Total Laid Off] DESC




-- Rolling Total of Layoffs Per Month over Years
WITH MonthDate AS (
    SELECT 
        FORMAT(date, 'MMMM yyyy') AS MonthName, 
        YEAR(date) AS YearNumber, 
        MONTH(date) AS MonthNumber,
        SUM(CAST(total_laid_off AS INT)) AS [Total Laid Off]
    FROM dbo.Layoff_1
    GROUP BY FORMAT(date, 'MMMM yyyy'), YEAR(date), MONTH(date)
)

SELECT 
    MonthDate.MonthName, 
    SUM(MonthDate.[Total Laid Off]) OVER (ORDER BY MonthDate.YearNumber, MonthDate.MonthNumber ASC) AS rolling_total_layoffs
FROM MonthDate
WHERE MonthDate.MonthName IS NOT NULL 
ORDER BY MonthDate.YearNumber, MonthDate.MonthNumber;
