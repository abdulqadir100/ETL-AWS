
  
    

  create  table "d2b_accessment"."abduafol4283_analytics"."agg_public_holiday__dbt_tmp"
  
  
    as
  
  (
    with base_order as (
	select 	order_id,
			customer_id,
			date(order_date) as order_date  -- convert from text to date	
	from abduafol4283_staging.orders
),

base_date as (
	select 	calendar_dt,
			day_of_the_week_num,
			month_of_the_year_num,
			working_day
	from if_common.dim_dates
),
	
orders_date as (
select *
from base_order
left join base_date
on base_order.order_date = base_date.calendar_dt
where base_date.day_of_the_week_num  between 1 and 5
and working_day = false 
),

orders_count_agg as (
	select 	month_of_the_year_num month_,
			count(1) num_hol_orders
	from orders_date
	group by month_of_the_year_num
)
	
select 
		current_date as ingestion_date,
		max(case when month_ = 1 then num_hol_orders else 0 end )as tt_order_hol_jan,
		max(case when month_ = 2 then num_hol_orders else 0 end) as tt_order_hol_feb,
		max(case when month_ = 3 then num_hol_orders else 0 end) as tt_order_hol_mar,
		max(case when month_ = 4 then num_hol_orders else 0 end) as tt_order_hol_apr,
		max(case when month_ = 5 then num_hol_orders else 0 end) as tt_order_hol_may,
		max(case when month_ = 6 then num_hol_orders else 0 end) as tt_order_hol_jun,
		max(case when month_ = 7 then num_hol_orders else 0 end) as tt_order_hol_jul,
		max(case when month_ = 8 then num_hol_orders else 0 end) as tt_order_hol_aug,
		max(case when month_ = 9 then num_hol_orders else 0 end) as tt_order_hol_sep,
		max(case when month_ = 10 then num_hol_orders else 0 end) as tt_order_hol_oct,
		max(case when month_ = 11 then num_hol_orders else 0 end) as tt_order_hol_nov,
		max(case when month_ = 12 then num_hol_orders else 0 end) as tt_order_hol_dec
from orders_count_agg
  );
  