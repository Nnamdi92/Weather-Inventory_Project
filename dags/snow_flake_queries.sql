CREATE WAREHOUSE maxi_wh
warehouse_size = 'small'
auto_suspend = 30
auto_resume = True;

CREATE DATABASE maxi_store_db;

CREATE SCHEMA staging_schema;
CREATE SCHEMA maxistore_schema;


-- CREATING USER

CREATE USER data_analyst
PASSWORD = 'StrongPassword'
MUST_CHANGE_PASSWORD = true;


CREATE ROLE data_analyst_role;

use role data_analyst_role;

-- To grant roles to user

GRANT USAGE ON DATABASE MAXI_STORE_DB TO ROLE data_analyst_role;
GRANT USAGE ON SCHEMA maxistore_schema TO ROLE data_analyst_role;
GRANT SELECT ON ALL TABLES IN SCHEMA MAXISTORE_SCHEMA TO ROLE data_analyst_role;
GRANT ROLE data_analyst_role to user data_analyst;


-- Creating an integration

CREATE OR REPLACE  STORAGE INTEGRATION maxi_gcp_integration
  TYPE = EXTERNAL_STAGE
  STORAGE_PROVIDER = 'GCS'
  ENABLED = TRUE
  STORAGE_ALLOWED_LOCATIONS = ('gcs://maxi-sales-bucket92/' );




-- TO GET INTEGRATION PRINCIPAL
DESCRIBE INTEGRATION maxi_gcp_integration; 

SHOW STORAGE INTEGRATIONS;


CREATE OR REPLACE FILE FORMAT maxi_csv
type = 'CSV'
FIELD_OPTIONALLY_ENCLOSED_BY = '"'
SKIP_HEADER = 1;


-- CREATE STAGE 
CREATE OR REPLACE STAGE weather_stage
  URL = 'gcs://maxi-sales-bucket92/weather_data/'
  STORAGE_INTEGRATION = maxi_gcp_integration  -- This should be the Snowflake storage integration you've configured
  FILE_FORMAT = (TYPE = CSV FIELD_OPTIONALLY_ENCLOSED_BY = '"' SKIP_HEADER = 1);


CREATE OR REPLACE STAGE sales_stage
  URL = 'gcs://maxi-sales-bucket92/sales/'
  STORAGE_INTEGRATION = maxi_gcp_integration  -- This should be the Snowflake storage integration you've configured
  FILE_FORMAT = (TYPE = CSV FIELD_OPTIONALLY_ENCLOSED_BY = '"' SKIP_HEADER = 1);

  
-- TO DISPLAY THE STAGES
SHOW STAGES;


LIST @weather_stage;
LIST @sales_stage;




SELECT $1
FROM @weather_stage/berlin_weather_
(FILE_FORMAT => 'maxi_csv')
LIMIT 1


SELECT $1
FROM @sales_stage/customers
(FILE_FORMAT => 'maxi_csv')
LIMIT 1; 


-- Creating Weather tables
CREATE OR REPLACE TABLE maxi_store_db.staging_schema.berlin_weather (
    date TIMESTAMP_NTZ,
    location_name STRING,
    latitude FLOAT,
    longitude FLOAT,
    temperature_2m_mean FLOAT,
    weather_code INT,
    sunshine_duration FLOAT,
    temperature_2m_max FLOAT,
    temperature_2m_min FLOAT,
    sunrise TIMESTAMP_NTZ,
    sunset TIMESTAMP_NTZ
)
CLUSTER BY (date);


CREATE OR REPLACE TABLE maxi_store_db.staging_schema.london_weather (
    date TIMESTAMP_NTZ,
    location_name STRING,
    latitude FLOAT,
    longitude FLOAT,
    temperature_2m_mean FLOAT,
    weather_code INT,
    sunshine_duration FLOAT,
    temperature_2m_max FLOAT,
    temperature_2m_min FLOAT,
    sunrise TIMESTAMP_NTZ,
    sunset TIMESTAMP_NTZ
)
CLUSTER BY (date);

CREATE OR REPLACE TABLE maxi_store_db.staging_schema.los_angeles_weather (
    date TIMESTAMP_NTZ,
    location_name STRING,
    latitude FLOAT,
    longitude FLOAT,
    temperature_2m_mean FLOAT,
    weather_code INT,
    sunshine_duration FLOAT,
    temperature_2m_max FLOAT,
    temperature_2m_min FLOAT,
    sunrise TIMESTAMP_NTZ,
    sunset TIMESTAMP_NTZ
)
CLUSTER BY (date);

CREATE OR REPLACE TABLE maxi_store_db.staging_schema.new_york_weather (
    date TIMESTAMP_NTZ,
    location_name STRING,
    latitude FLOAT,
    longitude FLOAT,
    temperature_2m_mean FLOAT,
    weather_code INT,
    sunshine_duration FLOAT,
    temperature_2m_max FLOAT,
    temperature_2m_min FLOAT,
    sunrise TIMESTAMP_NTZ,
    sunset TIMESTAMP_NTZ
)
CLUSTER BY (date);


CREATE OR REPLACE TABLE maxi_store_db.staging_schema.paris_weather (
    date TIMESTAMP_NTZ,
    location_name STRING,
    latitude FLOAT,
    longitude FLOAT,
    temperature_2m_mean FLOAT,
    weather_code INT,
    sunshine_duration FLOAT,
    temperature_2m_max FLOAT,
    temperature_2m_min FLOAT,
    sunrise TIMESTAMP_NTZ,
    sunset TIMESTAMP_NTZ
)
CLUSTER BY (date);

ALTER TABLE maxi_store_db.staging_schema.los_angeles_weather
ADD (
  rain_sum FLOAT,
  snowfall_sum FLOAT
);


-- copying weather data
COPY INTO maxi_store_db.staging_schema.los_angeles_weather
FROM @weather_stage/los_angeles/los_angeles_daily_weather_20250728_110801.csv
FILE_FORMAT = (TYPE = CSV FIELD_OPTIONALLY_ENCLOSED_BY = '"' SKIP_HEADER = 1)

LIST @weather_stage;
DESC STAGE weather_stage;
DESC TABLE maxi_store_db.staging_schema.new_york_weather;


select COUNT(*) from maxi_store_db.staging_schema.london_weather limit 10;
select * from maxistore_db.staging_schema.customers limit 10;


--- craete maxi_sales Tables
CREATE OR REPLACE TABLE maxi_store_db.staging_schema.customers(
    customer_id NUMBER PRIMARY KEY,
    card_number STRING,
    address STRING,
    city STRING, 
    country STRING,
    postal_code STRING,
    created_at TIMESTAMP_NTZ,
    updated_at TIMESTAMP_NTZ
    )
    CLUSTER BY (country);

-- copying into tables
COPY INTO maxi_store_db.staging_schema.customers
FROM @sales_stage/customers.csv
FILE_FORMAT = (TYPE = CSV FIELD_OPTIONALLY_ENCLOSED_BY = '"' SKIP_HEADER = 1)


CREATE OR REPLACE TABLE maxi_store_db.staging_schema.stores (
    store_id NUMBER PRIMARY KEY,
    store_name STRING,
    city STRING,
    country STRING,
    latitude NUMBER,
    longitude NUMBER,
    created_at TIMESTAMP_NTZ,
    updated_at TIMESTAMP_NTZ
);

-- copying into tables
COPY INTO maxi_store_db.staging_schema.stores
FROM @sales_stage/stores.csv
FILE_FORMAT = (TYPE = CSV FIELD_OPTIONALLY_ENCLOSED_BY = '"' SKIP_HEADER = 1)


CREATE OR REPLACE TABLE maxi_store_db.staging_schema.products (
    product_id NUMBER PRIMARY KEY,
    sku STRING,
    product_name STRING,
    category STRING,
    price NUMBER,
    cost NUMBER,
    created_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    updated_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);
-- copying into tables
COPY INTO maxi_store_db.staging_schema.products
FROM @sales_stage/products.csv
FILE_FORMAT = (TYPE = CSV FIELD_OPTIONALLY_ENCLOSED_BY = '"' SKIP_HEADER = 1)


CREATE OR REPLACE TABLE maxi_store_db.staging_schema.sales_transactions (
    transaction_id NUMBER(38,0) PRIMARY KEY, 
    store_id NUMBER,
    customer_id NUMBER,
    product_id NUMBER,
    quantity NUMBER,
    unit_price NUMBER,
    payment_method STRING,
    sales_channel STRING,
    created_at TIMESTAMP_NTZ,
    updated_at TIMESTAMP_NTZ,
    customer_card STRING,
    
    -- Foreign key constraints
    CONSTRAINT fk_sales_store FOREIGN KEY (store_id) REFERENCES maxi_store_db.staging_schema.stores(store_id),
    CONSTRAINT fk_sales_customer FOREIGN KEY (customer_id) REFERENCES maxi_store_db.staging_schema.customers(customer_id),
    CONSTRAINT fk_sales_product FOREIGN KEY (product_id) REFERENCES maxi_store_db.staging_schema.products(product_id)
)
CLUSTER BY (updated_at);

-- copying into tables
COPY INTO maxi_store_db.staging_schema.sales_transactions
FROM @sales_stage/sale_transactions.csv
FILE_FORMAT = (TYPE = CSV FIELD_OPTIONALLY_ENCLOSED_BY = '"' SKIP_HEADER = 1)


-- Inventory table
CREATE OR REPLACE TABLE maxi_store_db.staging_schema.inventory (
    inventory_id NUMBER PRIMARY KEY,
    store_id NUMBER,
    product_id NUMBER,
    current_stock NUMBER,
    reorder_level NUMBER,
    max_stock NUMBER,
    last_restocked TIMESTAMP_NTZ,
    created_at TIMESTAMP_NTZ,
    updated_at TIMESTAMP_NTZ,
    
    -- Foreign key constraints
    CONSTRAINT fk_inventory_store FOREIGN KEY (store_id) REFERENCES maxi_store_db.staging_schema.stores(store_id),
    CONSTRAINT fk_inventory_product FOREIGN KEY (product_id) REFERENCES maxi_store_db.staging_schema.products(product_id)
) CLUSTER BY (updated_at,store_id );

-- copying into tables
COPY INTO maxi_store_db.staging_schema.inventory
FROM @sales_stage/inventory.csv
FILE_FORMAT = (TYPE = CSV FIELD_OPTIONALLY_ENCLOSED_BY = '"' SKIP_HEADER = 1)


-- Sales manager table (fixed syntax errors)
CREATE OR REPLACE TABLE maxi_store_db.staging_schema.sales_manager (
    manager_id NUMBER PRIMARY KEY,
    manager_name STRING,
    location STRING,
    store_id NUMBER,
    -- Foreign key constraints
    CONSTRAINT fk_manager_store FOREIGN KEY (store_id) REFERENCES maxi_store_db.staging_schema.stores(store_id)
);

-- copying into tables
COPY INTO maxi_store_db.staging_schema.sales_manager
FROM @sales_stage/sales_managers.csv
FILE_FORMAT = (TYPE = CSV FIELD_OPTIONALLY_ENCLOSED_BY = '"' SKIP_HEADER = 1)


select Count(*) from maxi_store_db.staging_schema.sales_transactions



CREATE OR REPLACE SCHEMA maxi_store_db.analytics;

CREATE OR REPLACE VIEW maxi_store_db.analytics.customer_weather_vw AS
SELECT 
    c.customer_id,
    c.city,
    c.country,
    c.postal_code,
    c.card_number,
    c.updated_at,

    w.date AS weather_date,
    w.location_name,
    w.temperature_2m_mean,
    w.latitude,
    w.longitude,
    w.temperature_2m_max,
    w.temperature_2m_min,
    w.weather_code,
    w.sunshine_duration

FROM maxi_store_db.staging_schema.customers AS c
INNER JOIN maxi_store_db.staging_schema.new_york_weather AS w
    ON DATE(c.updated_at) = DATE(w.date);


CREATE OR REPLACE TABLE maxi_store_db.analytics.customer_weather_cdc (
    customer_id INT,
    city STRING,
    country STRING,
    postal_code STRING,
    card_number STRING,
    updated_at TIMESTAMP_NTZ,

    -- Weather info
    weather_date TIMESTAMP_NTZ,
    location_name STRING,
    temperature_2m_mean FLOAT,
    temperature_2m_max FLOAT,
    temperature_2m_min FLOAT,
    weather_code INT,
    sunshine_duration FLOAT,

    -- CDC tracking
    cdc_insert_timestamp TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    cdc_update_timestamp TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    cdc_operation STRING,
    record_hash STRING
);

MERGE INTO maxi_store_db.analytics.customer_weather_cdc AS target
USING (
    SELECT 
        c.customer_id,
        c.city,
        c.country,
        c.postal_code,
        c.card_number,
        c.updated_at,
        w.date AS weather_date,
        w.location_name,
        w.temperature_2m_mean,
        w.temperature_2m_max,
        w.temperature_2m_min,
        w.weather_code,
        w.sunshine_duration,

        HASH(
            c.customer_id, c.city, c.country, c.postal_code, c.card_number, c.updated_at,
            w.date, w.location_name, w.temperature_2m_mean, w.temperature_2m_max,
            w.temperature_2m_min, w.weather_code, w.sunshine_duration
        ) AS record_hash

    FROM maxi_store_db.staging_schema.customers AS c
    INNER JOIN maxi_store_db.staging_schema.new_york_weather AS w
        ON DATE(c.updated_at) = DATE(w.date)
) AS source
ON target.customer_id = source.customer_id AND target.weather_date = source.weather_date

WHEN MATCHED AND target.record_hash != source.record_hash THEN
    UPDATE SET
        city = source.city,
        country = source.country,
        postal_code = source.postal_code,
        card_number = source.card_number,
        updated_at = source.updated_at,
        weather_date = source.weather_date,
        location_name = source.location_name,
        temperature_2m_mean = source.temperature_2m_mean,
        temperature_2m_max = source.temperature_2m_max,
        temperature_2m_min = source.temperature_2m_min,
        weather_code = source.weather_code,
        sunshine_duration = source.sunshine_duration,
        cdc_update_timestamp = CURRENT_TIMESTAMP(),
        cdc_operation = 'UPDATE',
        record_hash = source.record_hash

WHEN NOT MATCHED THEN
    INSERT (
        customer_id, city, country, postal_code, card_number, updated_at,
        weather_date, location_name, temperature_2m_mean, temperature_2m_max,
        temperature_2m_min, weather_code, sunshine_duration,
        cdc_insert_timestamp, cdc_update_timestamp, cdc_operation, record_hash
    )
    VALUES (
        source.customer_id, source.city, source.country, source.postal_code, source.card_number, source.updated_at,
        source.weather_date, source.location_name, source.temperature_2m_mean, source.temperature_2m_max,
        source.temperature_2m_min, source.weather_code, source.sunshine_duration,
        CURRENT_TIMESTAMP(), CURRENT_TIMESTAMP(), 'INSERT', source.record_hash
    );

-- View results
SELECT * FROM maxi_store_db.analytics.customer_weather_vw LIMIT 10;

-- CDC table results
SELECT * FROM maxi_store_db.analytics.customer_weather_cdc ORDER BY cdc_insert_timestamp DESC;

CREATE OR REPLACE TABLE maxi_store_db.analytics.customer_weather_analytics AS
SELECT 
    c.customer_id,
    c.city,
    c.country,
    c.card_number,
    DATE(c.updated_at) AS interaction_date,

    -- Weather
    w.date AS weather_date,
    w.location_name,
    w.temperature_2m_mean,
    w.temperature_2m_max,
    w.temperature_2m_min,
    w.weather_code,
    w.sunshine_duration,
    w.rain_sum,
    w.snowfall_sum,

    -- Derived values
    CASE 
        WHEN w.temperature_2m_mean >= 25 THEN 'HOT'
        WHEN w.temperature_2m_mean BETWEEN 15 AND 24.9 THEN 'MODERATE'
        ELSE 'COLD'
    END AS temperature_category,

    CASE 
        WHEN w.rain_sum > 0 THEN 'RAINY'
        ELSE 'DRY'
    END AS weather_type

FROM maxi_store_db.staging_schema.customers AS c
JOIN maxi_store_db.staging_schema.new_york_weather AS w
  ON DATE(c.updated_at) = DATE(w.date);

SELECT weather_type, COUNT(*) AS signups
FROM maxi_store_db.analytics.customer_weather_analytics
GROUP BY weather_type;

SELECT temperature_category, COUNT(*) AS customers
FROM maxi_store_db.analytics.customer_weather_analytics
GROUP BY temperature_category;


SELECT city, COUNT(*) AS rainy_signups
FROM maxi_store_db.analytics.customer_weather_analytics
WHERE weather_type = 'RAINY'
GROUP BY city
ORDER BY rainy_signups DESC
LIMIT 5;

DESC TABLE maxi_store_db.staging_schema.sales_transactions;

CREATE OR REPLACE TABLE maxi_store_db.analytics.product_analytics AS
SELECT 
    p.product_id,
    p.product_name,
    p.category,
    t.store_id,
    'berlin' AS city,  -- hardcoded
    t.created_at AS sale_date,
    SUM(t.quantity) AS total_quantity_sold,
    SUM(t.quantity * t.unit_price) AS total_revenue,

    -- Weather data
    w.temperature_2m_mean,
    w.temperature_2m_max,
    w.temperature_2m_min,
    w.weather_code,
    w.sunshine_duration,
    w.rain_sum,
    w.snowfall_sum

FROM maxi_store_db.staging_schema.sales_transactions t
JOIN maxi_store_db.staging_schema.products p
    ON t.product_id = p.product_id

JOIN maxi_store_db.staging_schema.berlin_weather w
    ON DATE(t.created_at) = DATE(w.date)

GROUP BY 
    p.product_id, p.product_name, p.category,
    t.store_id, t.created_at,
    w.temperature_2m_mean, w.temperature_2m_max, w.temperature_2m_min,
    w.weather_code, w.sunshine_duration, w.rain_sum, w.snowfall_sum;


SELECT product_name, SUM(total_revenue) AS revenue
FROM analytics.product_analytics
WHERE rain_sum > 0
GROUP BY product_name
ORDER BY revenue DESC;

SELECT 
  CASE 
    WHEN temperature_2m_mean >= 25 THEN 'HOT'
    WHEN temperature_2m_mean BETWEEN 15 AND 24.9 THEN 'MODERATE'
    ELSE 'COLD'
  END AS temperature_range,
  SUM(total_quantity_sold) AS quantity_sold,
  SUM(total_revenue) AS revenue
FROM analytics.product_analytics
GROUP BY temperature_range;

DESC TABLE maxi_store_db.staging_schema.inventory;

CREATE OR REPLACE TABLE maxi_store_db.analytics.product_weather_inventory_analytics AS
SELECT 
    t.product_id,
    p.product_name,
    p.category,
    t.store_id,
    s.city,
    t.created_at AS sale_date,
    t.quantity,
    t.unit_price,
    t.quantity * t.unit_price AS revenue,

    -- Weather data
    w.date AS weather_date,
    w.temperature_2m_mean,
    w.temperature_2m_max,
    w.temperature_2m_min,
    w.rain_sum,
    w.snowfall_sum,
    w.sunshine_duration,
    w.weather_code,

    -- Inventory data
    i.CURRENT_STOCK,
    i.REORDER_LEVEL,
    i.MAX_STOCK,
    i.LAST_RESTOCKED,
    i.CREATED_AT AS inventory_created_at

FROM maxi_store_db.staging_schema.sales_transactions t
JOIN maxi_store_db.staging_schema.products p
    ON t.product_id = p.product_id
JOIN maxi_store_db.staging_schema.stores s
    ON t.store_id = s.store_id
JOIN maxi_store_db.staging_schema.berlin_weather w
    ON DATE(t.created_at) = DATE(w.date)
    AND LOWER(s.city) = LOWER(w.location_name)
LEFT JOIN maxi_store_db.staging_schema.inventory i
    ON t.product_id = i.product_id
    AND t.store_id = i.store_id
    AND DATE(i.CREATED_AT) = DATE(t.created_at);
    


CREATE OR REPLACE TABLE maxi_store_db.analytics.product_weather_sales_analytics AS
SELECT 
    t.product_id,
    p.product_name,
    p.category,
    t.store_id,
    s.city,
    t.created_at AS sale_date,
    t.quantity,
    t.unit_price,
    t.quantity * t.unit_price AS revenue,
    
    -- Weather info
    w.date AS weather_date,
    w.temperature_2m_mean,
    w.temperature_2m_max,
    w.temperature_2m_min,
    w.rain_sum,
    w.snowfall_sum,
    w.sunshine_duration,
    w.weather_code,
    
    -- Inventory 
    i.CURRENT_STOCK,
    i.REORDER_LEVEL,
    i.MAX_STOCK,
    i.LAST_RESTOCKED,
    i.CREATED_AT AS inventory_created_at

FROM maxi_store_db.staging_schema.sales_transactions t
JOIN maxi_store_db.staging_schema.products p
    ON t.product_id = p.product_id
JOIN maxi_store_db.staging_schema.stores s
    ON t.store_id = s.store_id
JOIN maxi_store_db.staging_schema.berlin_weather w
    ON DATE(t.created_at) = DATE(w.date)
    AND LOWER(s.city) = LOWER(w.location_name)

-- inventory join
LEFT JOIN maxi_store_db.staging_schema.inventory i
    ON t.product_id = i.product_id
    AND t.store_id = i.store_id;

SELECT *
FROM analytics.product_weather_sales_analytics
WHERE CATEGORY = 'Summer Items'
  AND TEMPERATURE_2M_MEAN < 15
  AND CURRENT_STOCK > MAX_STOCK;

SELECT *
FROM analytics.product_weather_sales_analytics
WHERE CURRENT_STOCK <= REORDER_LEVEL;

SELECT *
FROM analytics.product_weather_sales_analytics
WHERE CURRENT_STOCK <= REORDER_LEVEL
  AND (
    (CATEGORY = 'Rain Gear' AND RAIN_SUM > 5)
    OR (CATEGORY = 'Winter Clothing' AND TEMPERATURE_2M_MEAN < 5)
    OR (CATEGORY = 'Summer Items' AND TEMPERATURE_2M_MEAN > 30)
  );
  


SELECT *
FROM analytics.product_weather_sales_analytics
LIMIT 20;

