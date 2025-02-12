# * Задача 7.
Теперь попробуем учесть в наших расчётах затраты с налогами и посчитаем валовую прибыль, то есть ту сумму, которую мы фактически получили в результате реализации товаров за рассматриваемый период.

## Задание:

Для каждого дня в таблицах orders и courier_actions рассчитайте следующие показатели:

 - Выручку, полученную в этот день.
 - Затраты, образовавшиеся в этот день.
 - Сумму НДС с продажи товаров в этот день.
 - Валовую прибыль в этот день (выручка за вычетом затрат и НДС).
 - Суммарную выручку на текущий день.
 - Суммарные затраты на текущий день.
 - Суммарный НДС на текущий день.
 - Суммарную валовую прибыль на текущий день.
 - Долю валовой прибыли в выручке за этот день (долю п.4 в п.1).
 - Долю суммарной валовой прибыли в суммарной выручке на текущий день (долю п.8 в п.5).

Колонки с показателями назовите соответственно **revenue**, **costs**, **tax**, **gross_profit**, **total_revenue**, **total_costs**, **total_tax**, **total_gross_profit**, **gross_profit_ratio**, **total_gross_profit_ratio**

Колонку с датами назовите **date**.

Долю валовой прибыли в выручке необходимо выразить в процентах, округлив значения до двух знаков после запятой.

Результат должен быть отсортирован по возрастанию даты.

Поля в результирующей таблице: **date**, **revenue**, **costs**, **tax**, **gross_profit**, **total_revenue**, **total_costs**, **total_tax**, **total_gross_profit**, **gross_profit_ratio**, **total_gross_profit_ratio**

Чтобы посчитать затраты, в этой задаче введём дополнительные условия.

В упрощённом виде затраты нашего сервиса будем считать как сумму постоянных и переменных издержек. К постоянным издержкам отнесём аренду складских помещений, а к переменным — стоимость сборки и доставки заказа. Таким образом, переменные затраты будут напрямую зависеть от числа заказов.

Из данных, которые нам предоставил финансовый отдел, известно, что в августе 2022 года постоянные затраты составляли **120 000 рублей** в день. Однако уже в сентябре нашему сервису потребовались дополнительные помещения, и поэтому постоянные затраты возросли до **150 000 рублей** в день.

Также известно, что в августе 2022 года сборка одного заказа обходилась нам в **140 рублей**, при этом курьерам мы платили по 150 рублей за один доставленный заказ и ещё **400 рублей** ежедневно в качестве бонуса, если курьер доставлял не менее 5 заказов в день. В сентябре продакт-менеджерам удалось снизить затраты на сборку заказа до **115 рублей**, но при этом пришлось повысить бонусную выплату за доставку 5 и более заказов до **500 рублей**, чтобы обеспечить более конкурентоспособные условия труда. При этом в сентябре выплата курьерам за один доставленный заказ осталась неизменной.

```
with 
-- Получение товаров в заказах
order_items as (
    select creation_time::date as date, order_id, unnest(product_ids) as product_id 
    from orders
    where order_id not in (
        select order_id
        from user_actions
        where action = 'cancel_order')
),
-- Добавление названия продукта, налога и стоимости
order_with_price as (
    select
        date,
        order_id, 
        product_id,
        name,
        price,
        (
            case
                when lower(name)  = any(array['сахар', 'сухарики', 'сушки', 'семечки', 
                    'масло льняное', 'виноград', 'масло оливковое', 
                    'арбуз', 'батон', 'йогурт', 'сливки', 'гречка', 
                    'овсянка', 'макароны', 'баранина', 'апельсины', 
                    'бублики', 'хлеб', 'горох', 'сметана', 'рыба копченая', 
                    'мука', 'шпроты', 'сосиски', 'свинина', 'рис', 
                    'масло кунжутное', 'сгущенка', 'ананас', 'говядина', 
                    'соль', 'рыба вяленая', 'масло подсолнечное', 'яблоки', 
                    'груши', 'лепешка', 'молоко', 'курица', 'лаваш', 'вафли', 'мандарины'])
                    then 10
                else 20
            end) as tax
    from order_items
    join products using(product_id)
),
-- Группировка по номеру заказа
order_total as (
    select
        date,
        order_id,
        count(distinct order_id) * (
            case extract (month from date)
                when 8 then 140
                when 9 then 115
            end) as assembly_cost,
        sum(price) as order_price,
        sum(round(price / (100 + tax) * tax, 2)) as tax_amount
    from order_with_price
    group by order_id, date
),
-- Получение количества заказов в день по курьерам
courier_info as (
    select 
        courier_id,
        time::date as date,
        count(distinct order_id) as order_count
    from courier_actions
    where order_id not in (
        select order_id
        from user_actions
        where action = 'cancel_order'
    ) and action = 'deliver_order'
    group by courier_id, time::date
),
-- Высчитывание затрат на каждого курьера
courier_total as (
    select 
        date, 
        courier_id,
        order_count,
        order_count * 150 + (
            case 
                when extract (month from date) = 8 and order_count >= 5 then 400
                when extract (month from date) = 9 and order_count >= 5 then 500
                else 0
            end) as courier_money
    from courier_info
),
-- 
order_grouped as (
    select 
        date,
        sum(order_price) as revenue,
        sum(tax_amount) as tax,
        sum(assembly_cost) as assembly_cost
    from order_total
    group by date
),
courier_grouped as (
    select
        date,
        sum(courier_money) as costs
    from courier_total
    group by date
)
    

-- Собираем все вместе и делаем расчеты
select
    date,
    revenue,
    costs,
    tax,
    revenue - costs - tax as gross_profit,
    sum(revenue) over(order by date) as total_revenue,
    sum(costs) over(order by date) as total_costs,
    sum(tax) over(order by date) as total_tax,
    sum(revenue - costs - tax) over(order by date) as total_gross_profit,
    round((revenue - costs - tax) * 100 / revenue, 2) as gross_profit_ratio,
    round(sum(revenue - costs - tax) over(order by date) * 100 / sum(revenue) over(order by date), 2) as total_gross_profit_ratio
from (
    select 
        date,
        revenue,
        costs + assembly_cost +
        (
            case extract (month from date)
                when 8 then 120000
                when 9 then 150000
            end) as costs,
        tax
    from order_grouped
    join courier_grouped using(date)
    order by date
) as t1
```