--1. Route Efficiency & Delay Drivers:
--   Identifying which road type & trffic condition leads to major bottlenecks & high travel time wrt to distnace.
select r.road_type as Road_type, tr.traffic_level as Traffic_Level,
cast(round(avg(t.distance_km),2) AS decimal(10,2)) as Average_Distance_km, 
cast(round(avg(t.travel_time_min),2) AS decimal(10,2)) as Average_Travel_Time_minutes,
cast(round(avg(t.distance_km/nullif(t.travel_time_min/60,0)),2) AS decimal(10,2)) as Actaul_Average_speed  
from trips_ as t                                                                                         
LEFT JOIN roads as r                                                                                    
ON t.road_id = r.road_id                                                                                
LEFT JOIN traffic as tr
ON t.traffic_id = tr.traffic_id
WHERE tr.traffic_level IS NOT NULL
group by r.road_type,tr.traffic_level
order by Average_Travel_Time_minutes DESC

--2. Total delivery & Average distance by zone type.
-- Which zone type sees highest orders & longer delivery routes.
SELECT r.zone_type as Zone_type, count(t.trip_id) as Total_Deliveries, 
cast(round(avg(t.distance_km),2) AS decimal(10,2)) AS Average_Distance,
cast(round(avg(t.travel_time_min),2) AS decimal(10,2)) AS Average_Travel_Time
FROM trips_ as t
JOIN roads as r
ON t.road_id = r.road_id
group by r.zone_type
order by Total_Deliveries DESC

--3. Commute & Time Efficiecy:
-- Categorizing distance travelled by the drivers to see how long it took for a quick delivery vs Long-route delivery.
WITH DistanceBucket AS(
SELECT trip_id, distance_km,travel_time_min,
CASE WHEN distance_km <= 5 THEN 'Short Distance(<=5 kms)'
      WHEN distance_km <= 15 THEN 'Medium Distance(<=15 kms)'
	  ELSE 'Long Distance(>15 kms)'
	  END AS trip_category
from trips_)
SELECT trip_category AS Trip_Category, count(trip_id) AS Total_Trips,
cast(round(avg(distance_km),2) AS decimal(10,2)) AS Average_Distance_km,
cast(round(avg(travel_time_min),2) AS decimal(10,2)) AS Average_Travel_Time_min
FROM DistanceBucket
GROUP BY trip_category
ORDER BY Average_Distance_km DESC

--4. Weather Imapct & Delivery Time Degradation:
-- Measuring how delivery speed impacted during adverse weather condition(Rain,Fog) vs Claer weather.
WITH WeatherCTE AS(
SELECT w.weather_type,
cast(round(avg(t.distance_km),2) AS decimal(10,2)) AS Average_Distance_km,
cast(round(avg(t.travel_time_min),2) AS decimal(10,2)) AS Average_Travel_Time_min
FROM trips_ as t
JOIN weather as w
ON t.weather_id = w.weather_id
GROUP BY w.weather_type)
SELECT weather_type, Average_Distance_km,Average_Travel_Time_min
FROM WeatherCTE
ORDER BY Average_Travel_Time_min DESC

--5. Infrastructure Bottlenecks:
-- Classifying roads into bottleneck severity tiers based on signal density & lane counts.
WITH InfrastructureDetails AS(
SELECT r.road_type, r.num_lanes, r.num_signals, count(t.trip_id) as total_trips,
cast(round(avg(t.distance_km/(t.travel_time_min/60)),2) AS decimal(10,2)) AS Average_road_speed
FROM trips_ as t
JOIN roads as r
ON t.road_id = r.road_id
GROUP BY  r.road_type, r.num_lanes, r.num_signals
HAVING count(t.trip_id) >=3),
BenchamarkDetails AS(
SELECT road_type, num_lanes, num_signals, total_trips,Average_road_speed,
cast(round(avg(Average_road_speed) OVER (partition by road_type),2) AS decimal(10,2)) as road_type_benchmark_speed
FROM InfrastructureDetails)
SELECT road_type,total_trips,num_lanes,num_signals,road_type_benchmark_speed,
CASE WHEN Average_road_speed < (road_type_benchmark_speed*0.8) THEN 'Severe Bottleneck'                                  
     WHEN Average_road_speed BETWEEN (road_type_benchmark_speed*0.8) AND Average_road_speed THEN 'Modearte Bottleneck'  
	 ELSE 'Optimal'
	 END AS Severity_Status
FROM BenchamarkDetails
WHERE num_lanes IS NOT NULL AND num_signals IS NOT NULL
ORDER BY road_type_benchmark_speed

--6. Lingering Delay(means when a delivery driver gets delayed on a specific road, does that road stay congested & slow down the NEXT driver who arrive shortly after?):
-- Finding which specific road id lingers & impact subsequent trips occuring shortly on the same road id.
WITH SubsequentTrip AS(
SELECT trip_id,road_id, timestamp, travel_time_min,
LAG(travel_time_min) OVER(partition by road_id order by timestamp) AS previous_trip_time,
LAG(timestamp) OVER(partition by road_id order by timestamp) AS previous_trip_timestamp
FROM trips_
WHERE timestamp IS NOT NULL AND travel_time_min IS NOT NULL AND road_id <> 'Not Available'),
DelayDetails AS(
SELECT  trip_id,road_id, timestamp,travel_time_min,previous_trip_time,
DATEDIFF(minute,previous_trip_timestamp,timestamp) AS gap_between_trips
FROM SubsequentTrip
WHERE previous_trip_timestamp IS NOT NULL)
SELECT road_id,count(trip_id) as Total_Trips,
cast(round(avg(travel_time_min),2) as decimal(10,2)) as current_trip_time,
cast(round(avg(previous_trip_time),2) as decimal(10,2)) as previous_trip_time,
count(case when previous_trip_time > 20 AND travel_time_min > 20 THEN 1 END) AS Delay_Count
FROM DelayDetails
WHERE gap_between_trips <= 30
GROUP BY road_id
ORDER BY Total_Trips
