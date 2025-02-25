CREATE TABLE suppliers_2 AS
SELECT * FROM suppliers;


select * from suppliers_2;

SELECT *
FROM suppliers
WHERE supplier_country ILIKE '%Ireland%' ;



update suppliers_2 
set supplier_country='Ireland'
where supplier_country ILIKE '%Ireland%' ;

SELECT *
FROM suppliers_2
WHERE supplier_country='Ireland' ;

CREATE TABLE ireland_suppliers_2 AS
SELECT *
FROM suppliers_2
WHERE supplier_country = 'Ireland';

select * from ireland_suppliers_2;

select * from ireland_suppliers_2 order by total_procurement_value desc;









