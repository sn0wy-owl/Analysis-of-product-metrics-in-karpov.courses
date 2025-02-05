with 
-- Считаем сумму каждого выполненного заказа
order_price as (
    SELECT 
        order_id,
        max(date) as date,
        sum(price) as order_price
    FROM (SELECT order_id,
                creation_time::date as date,
                unnest(product_ids) as product_id
            FROM   orders) as o
        LEFT JOIN products using(product_id)
    WHERE  order_id not in (SELECT order_id
                            FROM   user_actions
                            WHERE  action = 'cancel_order')
    GROUP BY order_id), 
-- Нумеруем каждое действие пользователя по его заказам
users as (
    SELECT 
        user_id,
        time,
        row_number() OVER(PARTITION BY user_id
                        ORDER BY time) as num
    FROM user_actions), 
-- Считаем первые действия пользователя
new_users as (
    SELECT 
        time::date as date,
        count(user_id) as users
    FROM   users
    WHERE  num = 1
    GROUP BY date), 
-- Нумеруем только оплаченные заказы пользователя по порядку
paying_users as (
    SELECT 
        user_id,
        time,
        row_number() OVER(PARTITION BY user_id
                            ORDER BY time) as num
    FROM   user_actions
    WHERE  order_id not in (SELECT order_id
                            FROM   user_actions
                            WHERE  action = 'cancel_order')), 
-- Считаем только первую оплату пользователей
new_paying_users as (
    SELECT 
        time::date as date,
        count(user_id) as paying_users
    FROM   paying_users
    WHERE  num = 1
    GROUP BY date)

-- Дальше сделаем в подзапросе накопленный итоговый результат и считаем метрики
SELECT date,
       round(running_revenue::decimal / running_users, 2) as running_arpu,
       round(running_revenue::decimal / running_paying_users, 2) as running_arppu,
       round(running_revenue::decimal / running_order_count, 2) as running_aov
FROM   (SELECT date,
               sum(revenue) OVER(ORDER BY date) as running_revenue,
               sum(order_count) OVER(ORDER BY date) as running_order_count,
               sum(users) OVER(ORDER BY date) as running_users,
               sum(paying_users) OVER(ORDER BY date) as running_paying_users
        FROM   (SELECT count(order_id) as order_count,
                       sum(order_price) as revenue,
                       date
                FROM   order_price
                GROUP BY date) as o
            LEFT JOIN new_users using(date)
            LEFT JOIN new_paying_users using(date)) as t1