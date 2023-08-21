
  
    

  create  table "d2b_accessment"."abduafol4283_analytics"."late_shp__dbt_tmp"
  
  
    as
  
  (
    with base_shipment as (
 select shipment_id,
	order_id,
	date(shipment_date) as shipment_date,  -- convert to a date column from text 
	date(delivery_date) as delivery_date  -- convert to a date column from text 
	
from abduafol4283_staging.shipment_deliveries
),

base_order as (
	select 	order_id,
			date(order_date) as order_date  -- convert to a date column from text 
	from abduafol4283_staging.orders
),

order_shipments as (
	select base_shipment.shipment_id,
			base_shipment.order_id,
	base_shipment.shipment_date,
	base_shipment.delivery_date,
	base_order.order_date,
	(date(base_order.order_date) + INTERVAL '6 days')::date as delivery_due_date   -- create a column for the delivery due date as 6 days after order_date
	
	from base_shipment 
	left join base_order
	on base_shipment.order_id = base_order.order_id
 
),
late_shipment as (
select *
from order_shipments
where shipment_date >= delivery_due_date)

select count(1)   --538
from late_shipment
  );
  