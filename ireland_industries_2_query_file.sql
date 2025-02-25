select * from Ireland_industries;

CREATE TABLE ireland_industries_2 AS
SELECT ogc_fid,wkb_geometry
FROM ireland_industries;

select * from ireland_industries_2;

---web scraped data from UN reports during past disasters
select * from ireland_suppliers_2;

-- Add a sequential ID column in the table
ALTER TABLE ireland_suppliers_2 ADD COLUMN sequential_id SERIAL;

select * from ireland_suppliers_2;

---nonspatial join performed on two tables 
---ireland_suppliers_2 and ireland_industries_2
---to create another table ireland_suppliers
CREATE TABLE ireland_suppliers AS
SELECT t1.*, t2.*
FROM ireland_suppliers_2 t1
JOIN ireland_industries_2 t2
ON t1.sequential_id = t2.ogc_fid;

select * from ireland_suppliers;

---dropping the unnecessary columns in the table ireland_suppliers
ALTER TABLE ireland_suppliers 
DROP COLUMN latitude,
DROP COLUMN longitude,
DROP COLUMN geom;

select * from ireland_suppliers;

select st_srid(wkb_geometry) from ireland_suppliers;
select st_srid(wkb_geometry) from counties;


COPY (
    SELECT *
    FROM ireland_suppliers
) TO 'D:/MAYNOOTH/SEM 1/SPATIAL DATABASES/PROJECT/IRELAND/output1.csv' WITH CSV HEADER;

---creating a view "supplier_distribution"
CREATE VIEW supplier_distribution AS
SELECT 
    id,
    supplier_name,
    organization_partner,
    wkb_geometry
FROM 
    ireland_suppliers;


DROP VIEW IF EXISTS procurement_by_industry;
CREATE OR REPLACE VIEW procurement_by_industry AS
SELECT resource_category,
    ST_SetSRID(ST_Centroid(ST_Union(ST_Transform(wkb_geometry, 32629))), 32629) AS geom,
    SUM(total_procurement_value) AS total_procurement_value,
    COUNT(id) AS number_of_suppliers
FROM
    ireland_suppliers
GROUP BY
    resource_category
ORDER BY
    total_procurement_value DESC;

INSERT INTO geometry_columns (f_table_catalog, f_table_schema, f_table_name, f_geometry_column, srid, type)
SELECT '', 'public', 'procurement_by_industry', 'geom', 32629, 'POINT';

---larger procurement value
SELECT 
    supplier_name,
    SUM(total_procurement_value) AS total_procurement_value, resource_category
FROM 
    ireland_suppliers
where
total_procurement_value>10000000
GROUP BY 
    supplier_name, resource_category
ORDER BY 
    total_procurement_value DESC ;


select * from counties;
select st_srid(wkb_geometry) from counties;

---spatial join to find the number of suppliers in each county
select polys.ogc_fid,polys.name_tag,count(*) as NumSuppliers
from counties as polys,ireland_suppliers as pts
where st_contains(polys.wkb_geometry,pts.wkb_geometry)
group by polys.ogc_fid 
order by NumSuppliers desc;

---add a new column NumSuppliers 
ALTER TABLE counties add column NumSuppliers integer default 0;

---Subquery to update the counties table column 'NumSuppliers'
With PolygonQuery as (
select polys.ogc_fid,polys.name_tag,count(*) as NumSuppliers
from counties as polys,ireland_suppliers as pts
where st_contains(polys.wkb_geometry,pts.wkb_geometry)
group by polys.ogc_fid
)
update counties
set NumSuppliers = PolygonQuery.NumSuppliers
from PolygonQuery
where PolygonQuery.ogc_fid=counties.ogc_fid;

---looking for whether updated
select ogc_fid,name_tag,NumSuppliers from counties;


---add a new column called NumSuppliersDensity
ALTER TABLE counties add column NumSuppliersDensity real default 0;

---spatial join query to calculate the DENSITY of suppliers in each county
select polys.ogc_fid,polys.name_tag,
count(*)/(st_area(st_transform(polys.wkb_geometry,32629))/1000000) 
as SuppliersPerKM2
from counties as polys,ireland_suppliers as pts
where st_contains(polys.wkb_geometry,pts.wkb_geometry)
group by polys.ogc_fid;

---Subquery to update the counties table column 'NumSuppliersDensity'
With PolygonQuery as (
select polys.ogc_fid,polys.name_tag,
count(*)/(st_area(st_transform(polys.wkb_geometry,32629))/1000000) 
as SuppliersPerKM2
from counties as polys,ireland_suppliers as pts
where st_contains(polys.wkb_geometry,pts.wkb_geometry)
group by polys.ogc_fid
)
update counties
set NumSuppliersDensity = round(cast(PolygonQuery.SuppliersPerKM2 as numeric),3)
from PolygonQuery
where PolygonQuery.ogc_fid=counties.ogc_fid;

---checking whether it is updated
select ogc_fid,name_tag,NumSuppliersDensity from counties
order by NumSuppliersDensity desc limit 10;


---The coordinates POINT(34.4655 31.5013) correspond to a location 
---near the city of Rafah in the southern Gaza.
DROP VIEW IF EXISTS to_gaza;
CREATE OR REPLACE VIEW to_gaza as 
select *,ST_Distance(ST_Transform(St_GeomFromText('POINT(34.4655 31.5013)
',4326),32632),ST_Transform(wkb_geometry,32632))/1000 as tdistance from
ireland_suppliers order by tdistance asc;

---Spatial clustering of suppliers 
DROP VIEW IF EXISTS supplier_clusters;
CREATE OR REPLACE VIEW supplier_clusters AS
SELECT 
    id,
    supplier_name,
    organization_partner,
    ST_ClusterDBSCAN(wkb_geometry, eps := 0.1, minpoints := 20) 
	OVER () AS cluster_id,
    wkb_geometry
FROM 
    ireland_suppliers; 

---View of Procurement by Year
CREATE VIEW procurement_by_year AS
SELECT 
    UNNEST(year) AS procurement_year,
    SUM(total_procurement_value) AS yearly_procurement_value
FROM 
    ireland_suppliers
GROUP BY 
    procurement_year
ORDER BY 
    procurement_year desc;

---Create a new table for suppliers in Dublin
CREATE TABLE dublin_suppliers AS
SELECT s.*
FROM ireland_suppliers s
JOIN counties c
ON ST_Contains(c.wkb_geometry, s.wkb_geometry)
WHERE c.name_tag = 'Dublin';

---Add a spatial index to the new table for better performance in QGIS
CREATE INDEX idx_dublin_suppliers_geom
ON dublin_suppliers
USING GIST (wkb_geometry);

CREATE TABLE dublin_suppliers_projected AS
SELECT 
    id,
    supplier_name,
    organization_partner,
    ST_Transform(wkb_geometry, 2157) AS wkb_geometry
FROM dublin_suppliers;


select * from dublin_suppliers;
select st_srid(wkb_geometry) from dublin_suppliers;

---Measure the distance of suppliers from the Dublin county boundary.
---Use Case: Check for suppliers near the edge of the county for cross-boundary operations.
SELECT 
    id, 
    supplier_name, 
    ST_Distance(wkb_geometry, (SELECT ST_Boundary(wkb_geometry) FROM counties WHERE name_tag = 'Dublin')) AS distance_to_boundary
FROM dublin_suppliers
order by distance_to_boundary asc;

CREATE VIEW supplier_distance_to_boundary AS
SELECT 
    id, 
    supplier_name, 
    wkb_geometry,
    ST_Distance(wkb_geometry, 
	(SELECT ST_Boundary(wkb_geometry) 
	FROM counties WHERE name_tag = 'Dublin')) 
	AS distance_to_boundary
FROM dublin_suppliers;


---Proximity Analysis
---Objective: Identify the nearest suppliers to a specific location in Dublin.
---Use Case: Determine which suppliers can respond quickly to emergencies.
SELECT 
    s1.id AS supplier_id,
    s2.id AS nearest_supplier_id,
    ST_Distance(s1.wkb_geometry, s2.wkb_geometry) AS distance
FROM dublin_suppliers s1, dublin_suppliers s2
WHERE s1.id != s2.id and s1.id<s2.id
ORDER BY distance ASC;

SELECT 
    s1.id AS supplier_id,
    s2.id AS other_supplier_id,
    ST_Distance(s1.wkb_geometry, s2.wkb_geometry) AS distance,
    CASE
        WHEN ST_Distance(s1.wkb_geometry, s2.wkb_geometry) <= 50 THEN '0-0.05km'
        WHEN ST_Distance(s1.wkb_geometry, s2.wkb_geometry) <= 100 THEN '0.05-0.1 km'
        WHEN ST_Distance(s1.wkb_geometry, s2.wkb_geometry) <= 150 THEN '0.1-0.15 km'
        WHEN ST_Distance(s1.wkb_geometry, s2.wkb_geometry) <= 200 THEN '0.15-.2 km'
        
        ELSE '>.2 km'
    END AS distance_category,
    s1.wkb_geometry AS supplier_geom,
    s2.wkb_geometry AS other_supplier_geom,
    COUNT(CASE WHEN ST_Distance(s1.wkb_geometry, s2.wkb_geometry) <= 50 THEN 1 END) OVER () AS count_0_0_05_km,
    COUNT(CASE WHEN ST_Distance(s1.wkb_geometry, s2.wkb_geometry) <= 100 AND ST_Distance(s1.wkb_geometry, s2.wkb_geometry) <= 100 THEN 1 END) OVER () AS count_0_05_0_1_km,
    COUNT(CASE WHEN ST_Distance(s1.wkb_geometry, s2.wkb_geometry) <= 150 AND ST_Distance(s1.wkb_geometry, s2.wkb_geometry) <= 150 THEN 1 END) OVER () AS count_0_1_0_15_km,
    COUNT(CASE WHEN ST_Distance(s1.wkb_geometry, s2.wkb_geometry) <= 200 AND ST_Distance(s1.wkb_geometry, s2.wkb_geometry) <= 200 THEN 1 END) OVER () AS count_0_15_2_km,
    COUNT(CASE WHEN ST_Distance(s1.wkb_geometry, s2.wkb_geometry) > 200 AND ST_Distance(s1.wkb_geometry, s2.wkb_geometry) > 200 THEN 1 END) OVER () AS count_2_km
FROM 
    dublin_suppliers s1, dublin_suppliers s2
WHERE 
    s1.id != s2.id AND s1.id < s2.id;


---creating a table 'supplier_proximity' to view in QGIS
CREATE TABLE supplier_proximity AS
SELECT 
    s1.id AS supplier_id,
    s2.id AS nearest_supplier_id,
    ST_Distance(s1.wkb_geometry, s2.wkb_geometry) AS distance,
    s1.wkb_geometry AS supplier_geom,
    s2.wkb_geometry AS nearest_supplier_geom
FROM dublin_suppliers s1, dublin_suppliers s2
WHERE s1.id != s2.id AND s1.id < s2.id
ORDER BY distance ASC;


---Buffer Analysis
---Objective: Create buffer zones around suppliers to analyze their coverage.
---Use Case: Determine areas well-covered by suppliers and gaps in coverage.
CREATE TABLE supplier_buffers AS
SELECT 
    id, 
    supplier_name, 
    ST_Buffer(wkb_geometry, .25) AS buffer_geometry
FROM dublin_suppliers;


---Analyze Resources by Category: Breakdown by resource type
---Objective: Quantify the types of resources provided by suppliers.
---Use Case: Evaluate the diversity and adequacy of resources.
CREATE VIEW top_resource_categories AS
SELECT 
    UNNEST(resource_category) AS category, 
    SUM(total_procurement_value) AS total_value
FROM 
    dublin_suppliers
GROUP BY 
    category
ORDER BY 
    total_value DESC
LIMIT 7;
COPY (
SELECT 
    UNNEST(resource_category) AS category, 
    SUM(total_procurement_value) AS total_value
FROM 
    dublin_suppliers
GROUP BY 
    category
ORDER BY 
    total_value DESC
LIMIT 7
) TO 'D:/MAYNOOTH/SEM 1/SPATIAL DATABASES/PROJECT/IRELAND/procurement_by_resources_dublin.csv' WITH CSV HEADER;



---View of Procurement by Year
CREATE VIEW procurement_by_year_dublin AS
SELECT 
    UNNEST(year) AS procurement_year,
    SUM(total_procurement_value) AS yearly_procurement_value
FROM 
    dublin_suppliers
GROUP BY 
    procurement_year
ORDER BY 
    procurement_year desc;

COPY (
   SELECT 
    UNNEST(year) AS procurement_year,
    SUM(total_procurement_value) AS yearly_procurement_value
FROM 
    dublin_suppliers
GROUP BY 
    procurement_year
ORDER BY 
    procurement_year desc
) TO 'D:/MAYNOOTH/SEM 1/SPATIAL DATABASES/PROJECT/IRELAND/procurement_by_year_dublin.csv' WITH CSV HEADER;


---Analyze Partnerships Frequency
---Count how many times each organization appears in the dataset
SELECT 
    UNNEST(organization_partner) AS partner, 
    COUNT(*) AS partnership_count
FROM dublin_suppliers
GROUP BY partner
ORDER BY partnership_count DESC;

COPY (
   SELECT 
    UNNEST(organization_partner) AS partner, 
    COUNT(*) AS partnership_count
FROM dublin_suppliers
GROUP BY partner
ORDER BY partnership_count DESC
) TO 'D:/MAYNOOTH/SEM 1/SPATIAL DATABASES/PROJECT/IRELAND/partnership_freuency.csv' WITH CSV HEADER;



select * from dublin_suppliers;
select * from counties where name_tag='Dublin';


DROP VIEW IF EXISTS organization_partner_dublin;
CREATE OR REPLACE VIEW organization_partner_dublin AS
SELECT 
    c.name_tag AS county_name,
	c.ogc_fid,
    UNNEST(s.organization_partner) AS partner,
    COUNT(*) AS count
FROM dublin_suppliers s
JOIN counties c
ON ST_Contains(c.wkb_geometry, s.wkb_geometry)
where c.ogc_fid=5
GROUP BY c.name_tag, partner,c.ogc_fid
ORDER BY county_name, count DESC;

































