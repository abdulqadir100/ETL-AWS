with base_shipment as (
    select
        shipment_id,
        order_id,
        date(shipment_date) as shipment_date,
        -- convert to a date column from text 
        date(delivery_date) as delivery_date -- convert to a date column from text 
    from
        abduafol4283_staging.shipment_deliveries
),
base_order as (
    select
        order_id,
        date(order_date) as order_date -- convert to a date column from text 
    from
        abduafol4283_staging.orders
),
order_shipments as (
    select
        base_shipment.shipment_id,
        base_shipment.order_id,
        base_shipment.shipment_date,
        base_shipment.delivery_date,
        base_order.order_date,
        (date(base_order.order_date) + INTERVAL '6 days') :: date as delivery_due_date,
        -- create a column for the delivery due date as 6 days after order_date
        (date(base_order.order_date) + INTERVAL '15 days') :: date as shipment_due_date,
        -- create a column for the shipment due date as 15 days after order_date
        '2022-09-01' :: date as "current-date" -- create a column for current date as specified
    from
        base_shipment
        left join base_order on base_shipment.order_id = base_order.order_id
),
late_shipment as (
    select
        current_date as ingestion_date,
        count(1) as tt_late_shipments
    from
        order_shipments
    where
        shipment_date >= delivery_due_date
        and delivery_date is NULL
),
undelivered_shipment as (
    select
        current_date as ingestion_date,
        count(1) as tt_undelivered_shipments
    from
        order_shipments
    where
        "current-date" > delivery_due_date
        and delivery_date is NULL
        and shipment_date is NULL
)
select
    late_shipment.ingestion_date,
    late_shipment.tt_late_shipments,
    undelivered_shipment.tt_undelivered_shipments
from
    late_shipment
    left join undelivered_shipment on late_shipment.ingestion_date = undelivered_shipment.ingestion_date