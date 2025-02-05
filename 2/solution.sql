SELECT date,
       round(orders_sum / all_users, 2) as arpu, -- считаем метрики
       round(orders_sum / users_paying, 2) as arppu,
       round(orders_sum / order_count, 2) as aov
FROM   (SELECT time::date as date,
               count(distinct user_id) as all_users, -- собираем данные для подсчета
               count(distinct user_id) filter (WHERE status = 'success') as users_paying,
               count(order_id) filter (WHERE status = 'success') as order_count,
               sum(order_sum) filter (WHERE status = 'success') as orders_sum
        FROM   (SELECT order_id,
                       sum(price) as order_sum, -- считаем сумму заказа
                       case when order_id in (SELECT order_id
                                       FROM   user_actions
                                       WHERE  action = 'cancel_order') then 'cancelled' else 'success' end as status -- опредеяем итоговый статус заказа
                FROM   (SELECT order_id,
                               unnest(product_ids) as product_id -- делим список товаров построчно
                        FROM   orders) as o join (SELECT product_id,
                                                 price
                                          FROM   products) as p using(product_id) -- забираем цену каждого товара
                GROUP BY order_id) as o join user_actions using(order_id)
        GROUP BY date) as o
ORDER BY date