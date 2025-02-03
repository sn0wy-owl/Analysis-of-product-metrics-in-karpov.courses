-- Сделаем подзапрос, в котором посчитаем сумму для каждого заказа
with order_price as (SELECT o.order_id,
                            creation_time::date as date,
                            sum(p.price) as order_price
                     FROM   (SELECT *,
                                    unnest(product_ids) as product_id -- Раскрываем список продуктов
                             FROM   orders) as o join (SELECT *
                                               FROM   products) as p using(product_id) -- присоеденяем стоимость продуктов
                     GROUP BY order_id, date)

SELECT date,
       revenue,
       sum(revenue) OVER(ORDER BY date) as total_revenue, -- сумма заказов накопительным итогом
       round((revenue - lag(revenue, 1) OVER(ORDER BY date)::decimal) / lag(revenue, 1) OVER(ORDER BY date)::decimal * 100,
             2) as revenue_change -- считаем процент изменения суммы заказов
FROM   (SELECT date,
               sum(order_price) as revenue -- считаем сумму заказов за день
        FROM   order_price 
        WHERE  order_id not in (SELECT order_id
                                FROM   user_actions
                                WHERE  action = 'cancel_order') -- отфильтровываем отмененные заказы
        GROUP BY date) as o
ORDER BY date