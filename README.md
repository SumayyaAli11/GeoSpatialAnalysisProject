# GeoSpatial Analysis Project

## Overview

This project focuses on **Geospatial Analysis** using **PostgreSQL**, **PostGIS**, and **QGIS** to analyze, visualize, and interpret spatial data.  
The primary objective is to explore the **distribution of resources for disaster management in Ireland**, providing valuable insights for planning and decision-making.

---

## Tools & Technologies

- **PostgreSQL:** Relational database for storing and managing spatial data.  
- **PostGIS:** Spatial database extender for PostgreSQL to handle geospatial queries.  
- **QGIS:** Open-source Geographic Information System for visualizing spatial data.  

---

## Project Structure

```bash
GeoSpatialAnalysisProject/ 
├── LICENSE # Project license information 
├── README.md # Project overview and instructions 
├── counties.geojson # GeoJSON file containing county boundaries 
├── disaster supply networks.qgz # QGIS project file with disaster network analysis 
├── ireland_industries_table.sql # SQL script to create and populate industries table 
├── ireland_industries_2_query_file.sql # SQL queries for industry-related analysis 
├── ireland_suppliers_2_table.sql # SQL script to create suppliers table 
└── presentation link to the project.txt # Link to the project presentation
```

## Setup Instructions

### Prerequisites

- PostgreSQL (with PostGIS extension)  
- QGIS  

---

### Steps

1. **Clone the Repository**

```bash
git clone https://github.com/SumayyaAli11/GeoSpatialAnalysisProject.git
cd GeoSpatialAnalysisProject
```


2. **Set up PostgreSQL Database:**
- Create and connect to a new database:
  
  ```sql
  CREATE DATABASE geospatial_db;
  \\c geospatial_db
  CREATE EXTENSION postgis;
  ```

3. **Import Data:**
- Run the SQL scripts to set up tables and queries:
  
  ```bash
  psql -d geospatial_db -f ireland_industries_table.sql
  psql -d geospatial_db -f ireland_industries_2_query_file.sql
  psql -d geospatial_db -f ireland_suppliers_2_table.sql
  ```

4. **Visualize with QGIS:**

- Open `disaster supply networks.qgz` in QGIS to view and analyze spatial data layers.
- Load `counties.geojson` for geographic boundaries.

---

## ✨ Features
- 🗺️ Mapping of resource distribution networks in Ireland.
- 📊 Spatial queries for analyzing industry and supplier data.
- 📍 Visualization of optimal resource allocation for disaster management.

---

## 📈 Results
- 🌍 Interactive maps displaying resource locations and supply networks.
- 📑 Analytical reports based on spatial queries.
- 📝 Recommendations for improved disaster response strategies.

---

## 🎥 Presentation
For a detailed project overview, refer to the presentation link provided in:
> **`presentation link to the project.txt`**

---

## 🙏 Acknowledgments
- Open-source communities and tool developers.
- **Maynooth University** for academic guidance.

---

## 👩‍💻 Created by [Sumayya Ali](https://github.com/SumayyaAli11)
