# * Задача 5.
Немного усложним наш первоначальный запрос и отдельно посчитаем ежедневную выручку с заказов новых пользователей нашего сервиса. Посмотрим, какую долю она составляет в общей выручке с заказов всех пользователей — и новых, и старых.

## Задание:

Для каждого дня в таблицах orders и user_actions рассчитайте следующие показатели:

 - Выручку, полученную в этот день.
 - Выручку с заказов новых пользователей, полученную в этот день.
 - Долю выручки с заказов новых пользователей в общей выручке, полученной за этот день.
 - Долю выручки с заказов остальных пользователей в общей выручке, полученной за этот день.

Колонки с показателями назовите соответственно **revenue**, **new_users_revenue**, **new_users_revenue_share**, **old_users_revenue_share**. Колонку с датами назовите **date**. 

Все показатели долей необходимо выразить в процентах. При их расчёте округляйте значения до двух знаков после запятой.

Результат должен быть отсортирован по возрастанию даты.

Поля в результирующей таблице:

**date**, **revenue**, **new_users_revenue**, **new_users_revenue_share**, **old_users_revenue_share**

```
with 
-- Разделим список заказов построчно
orders_split as (
    SELECT 
        order_id,
        unnest(product_ids) as product_id
    FROM   orders
    WHERE  order_id not in (SELECT order_id FROM   user_actions WHERE  action = 'cancel_order')
), 
-- Получим стоимость каждого заказа
order_price as (
    SELECT 
        order_id,
        sum(price) as price
    FROM   orders_split 
    JOIN products USING(product_id)
    GROUP BY order_id
), 
-- Дополним информацию о заказах датой и идентификатором пользователя
order_info as (
    SELECT 
        time::date as date,
        user_id,
        order_id,
        price
    FROM   order_price 
    JOIN user_actions USING(order_id)
),
-- Найдем первую дату заказа
users_start_date as (
    SELECT 
        user_id,
        min(time::date) as start_date
    FROM   user_actions
    GROUP BY user_id
), 
-- Посчитаем прибыль от пользователей в первую их дату заказов
new_user_revenue as (
    SELECT 
        date,
        sum(price) as new_users_revenue
    FROM   order_info
    RIGHT JOIN users_start_date ON start_date = date 
        AND order_info.user_id = users_start_date.user_id
    GROUP BY date), revenue as (SELECT 
                                    date,
                                    sum(price) as revenue
                                FROM   order_info
                                GROUP BY date)
-- Соберем все вместе и посчитаем показатели
SELECT date,
       revenue,
       new_users_revenue,
       round(new_users_revenue*100/revenue, 2) as new_users_revenue_share,
       round((revenue - new_users_revenue)*100/revenue, 2) as old_users_revenue_share
FROM   revenue join new_user_revenue using(date)
ORDER BY date
```