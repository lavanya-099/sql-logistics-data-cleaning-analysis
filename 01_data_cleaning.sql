---checking for duplicate records.
with cte as (select *, row_number() over(partition by traffic_id order by traffic_id) as ranking
from traffic)
select *
from cte 

---checking data type of each columns of traffic table.
SELECT COLUMN_NAME,DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME ='traffic'

----changing the data type from float to INT.
ALTER TABLE traffic     
ALTER COLUMN hour INT

--Replacing negetive values with its ABSOLUTE & modular opearotor(%) in 'hour' column.
UPDATE traffic
SET hour = ABS(hour) % 24 
WHERE hour <0 OR hour >24


--Updating numbers, abbrevaiations into correct TEXT form in 'day_of_week' column.
UPDATE traffic
SET day_of_week = CASE
WHEN LOWER(day_of_week) IN('0', 'sun', 'sunday') THEN 'Sunday'
WHEN LOWER(day_of_week) IN('1', 'mon', 'monday') THEN 'Monday'
WHEN LOWER(day_of_week) IN('2', 'tue', 'tuesday') THEN 'Tuesday'
WHEN LOWER(day_of_week) IN('3', 'wed', 'wednesday') THEN 'Wednesday'
WHEN LOWER(day_of_week) IN('4', 'thu', 'thursday') THEN 'Thursday'
WHEN LOWER(day_of_week) IN('5', 'fri', 'friday') THEN 'Friday'
WHEN LOWER(day_of_week) IN('6', 'sat', 'saturday') THEN 'Saturday'
ELSE NULL
END

--Replacing NULL with 'Unknown'
UPDATE traffic
SET day_of_week = 'Unknown'
WHERE day_of_week is null

--cleaning negetive, 0 & impossible speeds(cleaning extreme outliers) in 'avg_speed_kmph' column.
UPDATE traffic                  
SET avg_speed_kmph = NULL
WHERE ISNUMERIC(avg_speed_kmph) = 0   
              
ALTER TABLE traffic
ALTER COLUMN avg_speed_kmph DECIMAL(10,2)

UPDATE traffic
SET avg_speed_kmph = CASE
WHEN avg_speed_kmph <=0 OR avg_speed_kmph >=90 THEN NULL
ELSE avg_speed_kmph
END

--Checking VARCHAR datatype of 'timestamp' column can be converted to DATE datatype using try_cast().
SELECT timestamp
from weather
where try_cast(timestamp AS datetime2) IS NULL AND timestamp IS NOT NULL

--Since the above query returned British date format(DD/MM/YY HH:MM), converting date type using convert() & try_convert()
UPDATE weather
SET timestamp = CONVERT(VARCHAR,try_convert(datetime2,timestamp,3),120)                         
WHERE try_cast(timestamp AS datetime2) IS NULL AND try_convert(datetime2,timestamp,3) IS NOT NULL

ALTER TABLE weather
ALTER COLUMN timestamp DATETIME
