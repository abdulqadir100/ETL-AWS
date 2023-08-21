with base_order as (
    select
        order_id,
        product_id,
        date(order_date) as order_date -- convert to a date column from text 
    from
        abduafol4283_staging.orders
),
rank_orders as (
    select
        product_id,
        order_date as most_ordered_day,
        count(product_id) as num_of_orders,
        row_number() over (
            partition by product_id
            order by
                count(product_id) desc
        ) rank
    from
        base_order
    group by
        order_date,
        product_id
),
agg_order as (
    select
        *
    from
        rank_orders
    where
        rank = 1
),
base_shipment as (
    select
        shipment_id,
        order_id,
        date(shipment_date) as shipment_date,
        -- convert to a date column from text 
        date(delivery_date) as delivery_date -- convert to a date column from text 
    from
        abduafol4283_staging.shipment_deliveries
),
order_shipments as (
    select
        base_shipment.shipment_id,
        base_shipment.order_id,
        base_order.product_id,
        base_shipment.shipment_date,
        base_shipment.delivery_date,
        base_order.order_date,
        (date(base_order.order_date) + interval '6 days') :: date as delivery_due_date,
        -- create a column for the delivery due date as 6 days after order_date
        (date(base_order.order_date) + interval '15 days') :: date as shipment_due_date,
        -- create a column for the shipment due date as 15 days after order_date
        '2022-09-01' :: date as "current-date" -- create a column for current date
    from
        base_shipment
        left join base_order on base_shipment.order_id = base_order.order_id
),
late_shipment as (
    select
        current_date as ingestion_date,
        order_date,
        product_id,
        count(product_id) count_late_shipment --count() as tt_late_shipments
    from
        order_shipments
    where
        shipment_date >= delivery_due_date
        and delivery_date is null
    group by
        order_date,
        product_id
),
undelivered_shipment as (
    select
        current_date as ingestion_date,
        order_date,
        product_id,
        count(product_id) count_undelivered_shipment --count(1) as tt_undelivered_shipments
    from
        order_shipments
    where
        "current-date" > delivery_due_date
        and delivery_date is null
        and shipment_date is null
    group by
        order_date,
        product_id
),
base_date as (
    select
        calendar_dt,
        day_of_the_week_num,
        month_of_the_year_num,
        working_day,
        case
            when day_of_the_week_num between 1
            and 5
            and working_day = false then true
            else false
        end as is_public_holiday
    from
        if_common.dim_dates
),
base_product as (
    select
        product_id,
        product_name
    from
        if_common.dim_products
),
product_orders_date as (
    select
        agg_order.product_id,
        base_product.product_name,
        agg_order.num_of_orders,
        agg_order.most_ordered_day,
        base_date.is_public_holiday
    from
        agg_order
        left join base_date on agg_order.most_ordered_day = base_date.calendar_dt
        left join base_product on agg_order.product_id = base_product.product_id
),
agg_review as (
    select
        product_id,
        sum(
            case
                when review = 1 then 1
                else 0
            end
        ) as star_1_count,
        sum(
            case
                when review = 2 then 1
                else 0
            end
        ) as star_2_count,
        sum(
            case
                when review = 3 then 1
                else 0
            end
        ) as star_3_count,
        sum(
            case
                when review = 4 then 1
                else 0
            end
        ) as star_4_count,
        sum(
            case
                when review = 5 then 1
                else 0
            end
        ) as star_5_count,
        count(*) as total_reviews
    from
        abduafol4283_staging.reviews
    group by
        product_id
),
highest_review_pct as (
    select
        product_id,
        total_reviews,
        round(star_1_count / total_reviews :: numeric * 100, 2) as pct_one_star_review,
        round(star_2_count / total_reviews :: numeric * 100, 2) as pct_two_star_review,
        round(star_3_count / total_reviews :: numeric * 100, 2) as pct_three_star_review,
        round(star_4_count / total_reviews :: numeric * 100, 2) as pct_four_star_review,
        round(star_5_count / total_reviews :: numeric * 100, 2) as pct_five_star_review
    from
        agg_review
    order by
        total_reviews desc
    limit
        1
), final as (
    select
        current_date as ingestion_date,
        product_orders_date.product_name,
        product_orders_date.most_ordered_day,
        product_orders_date.is_public_holiday,
        highest_review_pct.total_reviews as tt_review_points,
        highest_review_pct.pct_one_star_review,
        highest_review_pct.pct_two_star_review,
        highest_review_pct.pct_three_star_review,
        highest_review_pct.pct_four_star_review,
        highest_review_pct.pct_five_star_review,
        round(
            case
                when count_late_shipment is not null then count_late_shipment
                else 0
            end / product_orders_date.num_of_orders :: numeric * 100,
            2
        ) as pct_early_shipments,
        round(
            case
                when count_undelivered_shipment is not null then count_undelivered_shipment
                else 0
            end / product_orders_date.num_of_orders :: numeric * 100,
            2
        ) as pct_late_shipments
    from
        highest_review_pct
        left join product_orders_date on highest_review_pct.product_id = product_orders_date.product_id
        left join late_shipment on highest_review_pct.product_id = late_shipment.product_id
        and product_orders_date.most_ordered_day = late_shipment.order_date
        left join undelivered_shipment on highest_review_pct.product_id = undelivered_shipment.product_id
        and product_orders_date.most_ordered_day = undelivered_shipment.order_date
)
select
    *
from
    final