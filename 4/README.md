# Задача 4.
Давайте посчитаем те же показатели, но в другом разрезе — не просто по дням, а по дням недели.

## Задание:

Для каждого дня недели в таблицах **orders** и **user_actions** рассчитайте следующие показатели:

 - Выручку на пользователя (**ARPU**).
 - Выручку на платящего пользователя (**ARPPU**).
 - Выручку на заказ (**AOV**).

При расчётах учитывайте данные только за период с 26 августа 2022 года по 8 сентября 2022 года включительно — так, чтобы в анализ попало одинаковое количество всех дней недели (ровно по два дня).

В результирующую таблицу включите как наименования дней недели (например, Monday), так и порядковый номер дня недели (от 1 до 7, где 1 — это Monday, 7 — это Sunday).

Колонки с показателями назовите соответственно **arpu**, **arppu**, **aov**. Колонку с наименованием дня недели назовите weekday, а колонку с порядковым номером дня недели **weekday_number**.

При расчёте всех показателей округляйте значения до двух знаков после запятой.

Результат должен быть отсортирован по возрастанию порядкового номера дня недели.

Поля в результирующей таблице: 

**weekday**, **weekday_number**, **arpu**, **arppu**, **aov**

```
SELECT weekday,
       case weekday_number when 0 then 7 else weekday_number end as weekday_number,
       round(orders_sum / all_users, 2) as arpu,
       round(orders_sum / users_payed, 2) as arppu,
       round(orders_sum / order_count, 2) as aov
-- выделим дни недели  и подсчитаем данные
FROM   (SELECT max(date_part('isodow', time)) as weekday_number,
               to_char(time, 'Day') as weekday,
               count(distinct user_id) as all_users,
               count(distinct user_id) filter (WHERE status = 'success') as users_payed,
               count(order_id) filter (WHERE status = 'success') as order_count,
               sum(order_sum) filter (WHERE status = 'success') as orders_sum
        -- Получим стоимость заказов и добавим статус заказа
        FROM   (SELECT order_id,
                       sum(price) as order_sum,
                       case when order_id in (SELECT order_id
                                       FROM   user_actions
                                       WHERE  action = 'cancel_order') then 'cancelled' else 'success' end as status
                -- Разделим список заказов построчно
                FROM   (SELECT order_id,
                               unnest(product_ids) as product_id
                        FROM   orders) as o join (SELECT product_id,
                                                 price
                                          FROM   products) as p using(product_id)
                GROUP BY order_id) as o join user_actions using(order_id)
        WHERE  time::date between '2022-08-26'
           and '2022-09-9'
        GROUP BY weekday) as o
ORDER BY weekday_number
```