create database superstore_sales_db;
select * from sales_data;
describe sales_data; 


-- order_date 2012-02-30
-- Formated date varchar to date 
select 
    order_date, 
    STR_TO_DATE(order_date, '%Y-%m-%d') AS formatted_date
from sales_data
order by order_date;


-- update order_date
set sql_safe_updates = 0;
update sales_data
set order_date =  STR_TO_DATE(order_date, '%Y-%m-%d');

-- first and last order_date and their difference
select Customer_Name,
max(order_date) as last_order_date,
min(order_date) as first_order_date,
datediff(max(order_date),min(order_date)) as difference_date
from sales_data
group by Customer_Name
order by last_order_date desc;

-- difference between max order_date and customer last order_date in indivitual customers  
create or replace view rfm_score_data_view as 
with customer_aggregated_data as 
(
select customer_name,
count(distinct Order_ID ) as customer_frequency,
round(sum(Sales),0) as customer_monetary,
datediff((select max(order_date) from sales_data),max(order_date)) as customer_Recency
from sales_data
group by customer_name

),
rfm_score as
(
select c.*,
ntile(4) over(order by customer_Recency desc) as Recency_score,
ntile(4) over(order by customer_frequency asc) as Frequency_score,
ntile(4) over(order by customer_monetary asc) as Monetary_score
from customer_aggregated_data as c
)
select r.*,
(Recency_score +Frequency_score+Monetary_score) as Total_acore,
concat('',Recency_score,Frequency_score,Monetary_score) as rfm_score_combinarion
from rfm_score as r;

SELECT * FROM rfm_score_data_view
WHERE rfm_score_combinarion = '111';

create view rfm_analysis as 
select 
    rfm_score_data_view.*,
    CASE
        WHEN rfm_score_combinarion IN (111, 112, 121, 132, 211, 211, 212, 114, 141) THEN 'CHURNED CUSTOMER'
        WHEN rfm_score_combinarion IN (133, 134, 143, 224, 334, 343, 344, 144) THEN 'SLIPPING AWAY, CANNOT LOSE'
        WHEN rfm_score_combinarion IN (311, 411, 331) THEN 'NEW CUSTOMERS'
        WHEN rfm_score_combinarion IN (222, 231, 221,  223, 233, 322) THEN 'POTENTIAL CHURNERS'
        WHEN rfm_score_combinarion IN (323, 333,321, 341, 422, 332, 432) THEN 'ACTIVE'
        WHEN rfm_score_combinarion IN (433, 434, 443, 444) THEN 'LOYAL'
    ELSE 'Other'
    END AS customer_segment_result
FROM rfm_score_data_view;


select
customer_segment_result,
count(*) as Total_number_of_customer
from rfm_analysis
group by customer_segment_result



