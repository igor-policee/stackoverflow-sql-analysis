/*
1. Выведите общую сумму просмотров постов за каждый месяц 2008 года. Если данных за какой-либо месяц в базе нет, такой месяц можно пропустить. Результат отсортируйте по убыванию общего количества просмотров.
*/

SELECT
    DATE_TRUNC('month', p.creation_date)::date as "month",
    SUM(p.views_count) as "views_count_sum"
FROM
    stackoverflow.posts as p
WHERE
    EXTRACT(YEAR FROM p.creation_date) = 2008
GROUP BY
    "month"
ORDER BY
    "views_count_sum" DESC;
   
/*
2. Выведите имена самых активных пользователей, которые в первый месяц после регистрации (включая день регистрации) дали больше 100 ответов. Вопросы, которые задавали пользователи, не учитывайте. Для каждого имени пользователя выведите количество уникальных значений user_id. Отсортируйте результат по полю с именами в лексикографическом порядке.
*/

WITH users_answers_cte as
(
    SELECT
        u.display_name as "user_name",
        u.id as "user_id"
    FROM
        stackoverflow.users as u
        INNER JOIN stackoverflow.posts as p ON u.id = p.user_id
        INNER JOIN stackoverflow.post_types as pt ON p.post_type_id = pt.id
    WHERE
        pt.type = 'Answer'
        AND p.creation_date::date BETWEEN u.creation_date::date AND (u.creation_date + INTERVAL '1 month')::date
)

SELECT
    user_name,
    COUNT(DISTINCT user_id) as "user_id_uniq_count"
FROM
    users_answers_cte
GROUP BY
    user_name
HAVING
    COUNT(1) > 100
ORDER BY
    user_name ASC;

/*
3. Выведите количество постов за 2008 год по месяцам. Отберите посты от пользователей, которые зарегистрировались в сентябре 2008 года и сделали хотя бы один пост в декабре того же года. Отсортируйте таблицу по значению месяца по убыванию.
*/

WITH users_reg_2008_09_cte as
(
    SELECT
        u.id as "user_id"
    FROM
        stackoverflow.users as u
    WHERE
        DATE_TRUNC('month', u.creation_date)::date = '2008-09-01'::date
),

users_post_2008_12_cte as
(
    SELECT
        p.user_id as "user_id"
    FROM
        stackoverflow.posts as p
    WHERE
        DATE_TRUNC('month', p.creation_date)::date = '2008-12-01'::date
)

SELECT
    DATE_TRUNC('month', p.creation_date)::date as "month",
    COUNT(1) as "posts_count"
FROM
    stackoverflow.posts as p
WHERE
    EXTRACT(YEAR FROM p.creation_date) = 2008
    AND p.user_id IN
(
    SELECT
        users_reg_2008_09_cte.user_id as "user_id"
    FROM
        users_reg_2008_09_cte
        INNER JOIN users_post_2008_12_cte USING(user_id)
)
GROUP BY
    "month"
ORDER BY
    "month" DESC;
       
/*
4. Используя данные о постах, выведите несколько полей:
- идентификатор пользователя, который написал пост;
- дата создания поста;
- количество просмотров у текущего поста;
- сумма просмотров постов автора с накоплением.
Данные в таблице должны быть отсортированы по возрастанию идентификаторов пользователей, а данные об одном и том же пользователе — по возрастанию даты создания поста.
*/

SELECT
    p.user_id as "user_id",
    p.creation_date as "creation_date",
    p.views_count as "views_count",
    SUM(views_count) OVER (PARTITION BY p.user_id ORDER BY p.creation_date::timestamp ASC) as "views_count_sum"
FROM
    stackoverflow.posts as p
ORDER BY
    "user_id" ASC;
  
/*    
5. Сколько в среднем дней в период с 1 по 7 декабря 2008 года включительно пользователи взаимодействовали с платформой? Для каждого пользователя отберите дни, в которые он или она опубликовали хотя бы один пост. Нужно получить одно целое число — не забудьте округлить результат.
*/

WITH interaction_platform_cte as
(
    SELECT
        p.user_id,
        CARDINALITY(ARRAY_AGG(DISTINCT DATE_TRUNC('day', p.creation_date)::date)) as day_count
    FROM
        stackoverflow.posts as p
    WHERE
        DATE_TRUNC('day', p.creation_date)::date BETWEEN '2008-12-01'::date AND '2008-12-07'::date
    GROUP BY
        p.user_id
)

SELECT
    ROUND(AVG(day_count)) as day_count_avg
FROM
    interaction_platform_cte;
      
/*
6.
На сколько процентов менялось количество постов ежемесячно с 1 сентября по 31 декабря 2008 года? 
Отобразите таблицу со следующими полями:
- номер месяца;
- количество постов за месяц;
- процент, который показывает, насколько изменилось количество постов в текущем месяце по сравнению с предыдущим.
Если постов стало меньше, значение процента должно быть отрицательным, если больше — положительным. Округлите значение процента до двух знаков после запятой.
Напомним, что при делении одного целого числа на другое в PostgreSQL в результате получится целое число, округлённое до ближайшего целого вниз. Чтобы этого избежать, переведите делимое в тип numeric.
*/

SELECT
    EXTRACT(MONTH FROM p.creation_date) as "month",
    COUNT(1) as "posts_count",
    ROUND(COUNT(1)::numeric * 100 / LAG(COUNT(1)) OVER (ORDER BY EXTRACT(MONTH FROM p.creation_date))::numeric - 100, 2) as "monthly_dynamics"
FROM
    stackoverflow.posts as p
WHERE
    DATE_TRUNC('day', p.creation_date)::date BETWEEN '2008-09-01'::date AND '2008-12-31'::date
GROUP BY
    "month";
    
/*
7. Найдите пользователя, который опубликовал больше всего постов за всё время с момента регистрации. 
Выведите данные его активности за октябрь 2008 года в таком виде:
- номер недели;
- дата и время последнего поста, опубликованного на этой неделе.
*/

SELECT
    EXTRACT(WEEK FROM p.creation_date::date) as "week_number",
    MAX(p.creation_date::timestamp) as "last_activity"
FROM
    stackoverflow.posts as p
WHERE
    p.user_id =
    (
        SELECT
            p.user_id as "user_id"
        FROM
            stackoverflow.posts as p
        GROUP BY
            "user_id"
        ORDER BY
            COUNT(1) DESC
        LIMIT 
            1
    )
    AND DATE_TRUNC('month', p.creation_date)::date = '2008-10-01'::date
GROUP BY
    "week_number";
