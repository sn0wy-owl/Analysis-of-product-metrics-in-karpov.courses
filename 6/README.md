# Задача 6.
Также было бы интересно посмотреть, какие товары пользуются наибольшим спросом и приносят нам основной доход.

## Задание:

Для каждого товара, представленного в таблице **products**, за весь период времени в таблице **orders** рассчитайте следующие показатели:

 - Суммарную выручку, полученную от продажи этого товара за весь период.
 - Долю выручки от продажи этого товара в общей выручке, полученной за весь период.

Колонки с показателями назовите соответственно **revenue** и **share_in_revenue**. Колонку с наименованиями товаров назовите **product_name**.

Долю выручки с каждого товара необходимо выразить в процентах. При её расчёте округляйте значения до двух знаков после запятой.

Товары, округлённая доля которых в выручке составляет менее 0.5%, объедините в общую группу с названием «ДРУГОЕ» (без кавычек), просуммировав округлённые доли этих товаров.

Результат должен быть отсортирован по убыванию выручки от продажи товара.

Поля в результирующей таблице: **product_name**, **revenue**, **share_in_revenue**

```
with 
-- Найдем Цену каждого товара и количество продаж
product_info as (
    SELECT 
        name as product_name,
        max(price) as price,
        count(*) as count_sales
    FROM (SELECT unnest(product_ids) as product_id
        FROM orders
        WHERE order_id not in ( SELECT order_id
                                FROM   user_actions
                                WHERE  action = 'cancel_order')
    ) as product_list 
    join products using(product_id)
    GROUP BY product_name), 

-- Посчитаем выручку с каждого товара
product_sales as (
    SELECT 
        product_name,
        (price * count_sales) as total_sales
    FROM product_info)


SELECT product_name,
       sum(revenue) as revenue,
       sum(shere_in_revenue) as share_in_revenue
FROM (
    -- Переименуем продукты, подходящие под условия "ДРУГОЕ"
    SELECT 
        (case 
        when share_in_revenue <= 0.5 then 'ДРУГОЕ'
        else product_name 
        end) as product_name,
        sum(revenue) as revenue,
        sum(share_in_revenue) as shere_in_revenue
    FROM ( 
        -- Считаем наши показатели без "ДРУГОЕ"
        SELECT 
            product_name,
            total_sales as revenue ,
            round(total_sales * 100 / sum(total_sales) OVER(), 2) as share_in_revenue
    FROM product_sales) as t1
    GROUP BY product_name, share_in_revenue) as t2
GROUP BY product_name
ORDER BY revenue desc
```