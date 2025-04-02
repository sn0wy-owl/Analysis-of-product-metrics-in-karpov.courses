# Задача 11.
Давайте сразу же закрепим на практике методику расчёта **Retention** и попробуем самостоятельно написать похожий запрос, руководствуясь материалами лекции.

## Задание:

На основе данных в таблице **user_actions** рассчитайте показатель дневного **Retention** для всех пользователей, разбив их на когорты по дате первого взаимодействия с нашим приложением.

В результат включите четыре колонки: месяц первого взаимодействия, дату первого взаимодействия, количество дней, прошедших с даты первого взаимодействия (порядковый номер дня начиная с 0), и само значение **Retention**.

Колонки со значениями назовите соответственно **start_month**, **start_date**, **day_number**, **retention**.

```
SELECT
    DATE_TRUNC('month', start_date)::DATE AS start_month,
    start_date,
    order_date - start_date AS day_number,
    ROUND(
        COUNT(DISTINCT user_id)::DECIMAL / MAX(COUNT(DISTINCT user_id)) OVER(PARTITION BY start_date)
    , 2) AS retention
FROM (
    SELECT 
        user_id,
        time::DATE AS order_date,
        MIN(time::DATE) OVER(PARTITION BY user_id) AS start_date
    FROM user_actions) AS t1
GROUP BY start_month, start_date, day_number
ORDER BY start_date, day_number
```
