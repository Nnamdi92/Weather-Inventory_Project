# 🌦 Weather Data Integration for Inventory Optimization

This project automates the extraction, transformation, and loading (ETL) of weather and business data into a Snowflake data warehouse to support **inventory optimization** decisions.  
The workflow integrates **Google Cloud Storage (GCS)**, **PostgreSQL**, and **Snowflake** using **Apache Airflow**, enabling analytics on the relationship between weather conditions and product sales/inventory levels.

---

## 📌 Objectives

- **Automate** weather data collection for multiple locations.
- **Integrate** weather data with sales and inventory data for advanced analytics.
- **Support** business logic to predict demand and optimize stock levels for weather-sensitive products.

---

## 🛠 Tech Stack

- **Orchestration**: Apache Airflow  
- **Cloud Storage**: Google Cloud Storage (GCS)  
- **Data Warehouse**: Snowflake  
- **Database Source**: PostgreSQL  
- **Data Processing**: Pandas, PyArrow  
- **Python Utilities**: python-dateutil, psycopg2-binary  
- **Development Tools**: isort, flake8  

---

## 📦 Installation

### 1️⃣ Clone the Repository
```bash
git clone https://github.com/Nnamdi92/Weather-Inventory_Project.git

```

### 2️⃣ Create Virtual Environment & Install Dependencies
```bash
python -m venv venv
source venv/bin/activate   # On Windows: venv\Scripts\activate
pip install -r requirements.txt
pip install -r requirements_dev.txt  # Development dependencies
```

---

## 📂 Requirements

**Production Requirements** (`requirements.txt`):
```
#apache-airflow-providers-google
#apache-airflow-providers-postgres
pandas
pyarrow
python-dateutil
psycopg2-binary
#great-expectations
google-cloud-storage
```

**Development Requirements** (`requirements_dev.txt`):
```
isort
flake8
```

---

## 🏗 Architectural Diagram

![Weather Integration Architecture](Untitled%20Diagram-Page-3.drawio.png)

**Workflow Overview:**
1. Extract sales, inventory, and customer data from PostgreSQL.
2. Upload raw data to Google Cloud Storage.
3. Fetch daily weather data from an API and store in GCS.
4. Load both business and weather data into Snowflake staging tables.
5. Transform and join data in Snowflake for analytics (e.g., stock optimization, weather impact).
6. Create analytics tables and run business logic queries.

---

## ▶️ Usage

- **Run Airflow DAG**: Triggers the ETL workflow end-to-end.

**Data Flow:**
- PostgreSQL → GCS (sales/inventory data)  
- API → GCS (weather data)  
- GCS → Snowflake (via external stages)  

**Analytics Output:**
- Combined weather-sales-inventory analytics tables  
- Business logic queries to detect stockouts, overstocking, and seasonal demand shifts.  

---

## 📊 Business Logic Examples (Snowflake SQL)

Below are practical SQL snippets you can run on top of the unified analytics table  
`analytics.product_weather_sales_analytics` to turn data into decisions.

---

### 1) Proactive Low-Stock Alerts During Weather-Driven Demand
```sql
SELECT *
FROM analytics.product_weather_sales_analytics
WHERE CURRENT_STOCK <= REORDER_LEVEL
  AND (
        (CATEGORY = 'Rain Gear'       AND RAIN_SUM > 5)
     OR (CATEGORY = 'Winter Clothing' AND TEMPERATURE_2M_MEAN < 5)
     OR (CATEGORY = 'Summer Items'    AND TEMPERATURE_2M_MEAN > 30)
  );
```
**Why it matters:** Catches problems before stockouts happen, reducing lost sales and complaints.

---

### 2) Overstock Risk: Summer Items in Cold Weather
```sql
SELECT *
FROM analytics.product_weather_sales_analytics
WHERE CATEGORY = 'Summer Items'
  AND TEMPERATURE_2M_MEAN < 15
  AND CURRENT_STOCK > MAX_STOCK;
```
**Why it matters:** Frees cash and storage space by reacting to seasonality.

---

### 3) Cold-Day Demand Adjustment for Winter Products
```sql
SELECT
  product_id,
  product_name,
  CATEGORY,
  SALE_DATE,
  QUANTITY AS base_quantity,
  CASE
    WHEN TEMPERATURE_2M_MEAN < 10 AND CATEGORY = 'Winter Clothing'
      THEN QUANTITY * 1.25
    ELSE QUANTITY
  END AS adjusted_quantity
FROM analytics.product_weather_sales_analytics;
```
**Why it matters:** Aligns forecasts with weather-sensitive demand.

---

### 4) Missed Opportunity (Post-Event): Low/No Stock in Extreme Weather
```sql
SELECT *
FROM analytics.product_weather_sales_analytics
WHERE (CURRENT_STOCK = 0 OR CURRENT_STOCK <= REORDER_LEVEL)
  AND (
        (CATEGORY = 'Rain Gear'       AND RAIN_SUM > 5)
     OR (CATEGORY = 'Winter Clothing' AND TEMPERATURE_2M_MEAN < 5)
     OR (CATEGORY = 'Summer Items'    AND TEMPERATURE_2M_MEAN > 30)
  );
```
**Why it matters:** Helps identify lost sales opportunities and improve ordering.

---

## 📄 License
This project is for educational and internal demonstration purposes only.
