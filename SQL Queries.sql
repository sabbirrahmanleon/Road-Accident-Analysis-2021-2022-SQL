
/* 1. KPIs
Retrieve key accident statistics such as total fatalities, serious, and slight casualties. */

SELECT 
    SUM(CASE WHEN accident_severity = 'Fatal' THEN number_of_casualties ELSE 0 END) AS total_fatal_casualties,
    SUM(CASE WHEN accident_severity = 'Serious' THEN number_of_casualties ELSE 0 END) AS total_serious_casualties,
    SUM(CASE WHEN accident_severity = 'Slight' THEN number_of_casualties ELSE 0 END) AS total_slight_casualties,
    SUM(CASE WHEN vehicle_type IN ('Car', 'Taxi/Private hire car') THEN number_of_casualties ELSE 0 END) AS car_casualties,
    SUM(CASE WHEN area = 'Urban' THEN number_of_casualties ELSE 0 END) AS urban_casualties,
    SUM(CASE WHEN area = 'Rural' THEN number_of_casualties ELSE 0 END) AS rural_casualties
FROM road_accidents;


------------------------------------

/* 2. Total Casualties by Vehicle Type
Categorize vehicle types and compute total casualties for each category. */

SELECT 
    CASE 
        WHEN vehicle_type = 'Agricultural vehicle' THEN 'Agricultural'
        WHEN vehicle_type IN ('Bus or coach (17 or more pass seats)', 'Minibus (8 - 16 passenger seats)') THEN 'Bus'
        WHEN vehicle_type IN ('Car', 'Taxi/Private hire car') THEN 'Car'
        WHEN vehicle_type IN ('Goods 7.5 tonnes mgw and over', 'Goods over 3.5t. and under 7.5t', 'Van / Goods 3.5 tonnes mgw or under') THEN 'Van'
        WHEN vehicle_type IN ('Motorcycle 125cc and under', 'Motorcycle 50cc and under', 'Motorcycle over 125cc and up to 500cc', 'Motorcycle over 500cc', 'Pedal cycle') THEN 'Bike'
        WHEN vehicle_type = 'Ridden horse' THEN 'Horse'
        ELSE 'Other'
    END AS vehicle_category,
    SUM(number_of_casualties) AS total_casualties
FROM road_accidents
GROUP BY vehicle_category
ORDER BY total_casualties DESC;


------------------------------------

-- 3. Year-on-Year Monthly Trend of Casualties (2021 vs 2022)

WITH yearly_casualties AS (
    -- Aggregate casualties for each year and month
    SELECT   
        year,  
        month,  
        SUM(number_of_casualties) AS total_casualties  
    FROM road_accidents  
    WHERE year IN (2021, 2022)  
    GROUP BY year, month  
),  
month_order AS (
    -- Create a reference table to order months correctly
    SELECT unnest(ARRAY['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',   
                       'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']) AS month,  
           generate_series(1, 12) AS month_num  
)  
SELECT   
    m.month,  
    y2021.total_casualties AS casualties_2021,  
    y2022.total_casualties AS casualties_2022,  
    -- Calculate percentage change with proper formatting
    CASE   
        WHEN y2021.total_casualties = 0 THEN NULL  
        ELSE CONCAT(
            ROUND(((y2022.total_casualties - y2021.total_casualties)::numeric /   
            NULLIF(y2021.total_casualties, 0) * 100)::numeric, 2), '%'
        )  
    END AS percentage_change  
FROM month_order m  
LEFT JOIN (SELECT * FROM yearly_casualties WHERE year = 2021) y2021 ON m.month = y2021.month  
LEFT JOIN (SELECT * FROM yearly_casualties WHERE year = 2022) y2022 ON m.month = y2022.month  
ORDER BY m.month_num;



------------------------------------

-- 4. Total Casualties by Road Type

WITH road_casualties AS (
    -- Aggregate casualties per road type
    SELECT 
        road_type, 
        SUM(number_of_casualties) AS total_casualties
    FROM road_accidents
    GROUP BY road_type
)
SELECT 
    road_type, 
    total_casualties,
    -- Calculate percentage of total casualties
    ROUND((total_casualties * 100.0) / SUM(total_casualties) OVER(), 2) || '%' AS percentage_of_total
FROM road_casualties
ORDER BY total_casualties DESC;


------------------------------------

/* 5. Total Casualties by Road Surface Conditions
Get total casualties grouped by road surface conditions */

SELECT 
    road_surface_conditions, 
    SUM(number_of_casualties) AS total_casualties
FROM road_accidents
GROUP BY road_surface_conditions
ORDER BY total_casualties DESC;



------------------------------------

-- 6. Casualties by Light Condition

WITH light_casualties AS (
    -- Aggregate casualties per light condition
    SELECT 
        light_conditions, 
        SUM(number_of_casualties) AS total_casualties
    FROM road_accidents
    GROUP BY light_conditions
)
SELECT 
    light_conditions, 
    total_casualties,
    -- Calculate percentage share of each light condition
    ROUND((total_casualties * 100.0) / SUM(total_casualties) OVER(), 2) || '%' AS percentage_of_total
FROM light_casualties
ORDER BY total_casualties DESC;


------------------------------------

/* 7. Count of Police Forces by Carriageway Hazards
Count number of police force interventions per carriageway hazard type and calculate percentage. */

SELECT 
    carriageway_hazards,
    COUNT(police_force) AS police_forces,
    CONCAT(
        ROUND((COUNT(police_force) * 100.0) / SUM(COUNT(police_force)) OVER (), 2), '%'
    ) AS percentage_of_total
FROM road_accidents
GROUP BY carriageway_hazards
ORDER BY COUNT(police_force) DESC;
