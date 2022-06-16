/*
1. Найдите количество вопросов, которые набрали больше 300 очков или как минимум 100 раз были добавлены в «Закладки».
*/

SELECT
    COUNT(p.id) as posts_count 
FROM
    stackoverflow.posts as p 
    INNER JOIN
        stackoverflow.post_types as pt 
        ON p.post_type_id = pt.id 
WHERE
    (
        p.score > 300 
        OR p.favorites_count >= 100
    )
    AND pt.type = 'Question'

    
/*
2. Сколько в среднем в день задавали вопросов с 1 по 18 ноября 2008 включительно? Результат округлите до целого числа.
*/

WITH posts_count_cte as 
(
    SELECT
        date_trunc('day', creation_date)::date as "day",
        COUNT(p.id) as posts_count 
    FROM
        stackoverflow.posts as p 
        INNER JOIN stackoverflow.post_types as pt ON p.post_type_id = pt.id 
    WHERE
        pt.type = 'Question' 
        AND EXTRACT(YEAR FROM creation_date) = 2008 
        AND EXTRACT(MONTH FROM creation_date) = 11 
        AND EXTRACT(DAY FROM creation_date) BETWEEN 1 AND 18 
    GROUP BY
        "day" 
)

SELECT
    ROUND(AVG(posts_count)) as posts_count_avg
FROM
    posts_count_cte

  
/*    
3. Сколько пользователей получили значки сразу в день регистрации? Выведите количество уникальных пользователей.
*/

SELECT
    COUNT(DISTINCT u.id) AS u_id_count 
FROM
    stackoverflow.badges AS b 
    INNER JOIN stackoverflow.users AS u ON b.user_id = u.id 
WHERE
    date_trunc('day', b.creation_date)::date = date_trunc('day', u.creation_date)::date


/*
4. Сколько уникальных постов пользователя с именем Joel Coehoorn получили хотя бы один голос?
*/

SELECT
    COUNT(DISTINCT p.id) as posts_count 
FROM
    stackoverflow.users as u 
    INNER JOIN stackoverflow.posts as p ON u.id = p.user_id 
    INNER JOIN stackoverflow.votes as v ON p.id = v.post_id 
WHERE
    u.display_name = 'Joel Coehoorn'
  
    
/*
5. Выгрузите все поля таблицы vote_types. Добавьте к таблице поле rank, в которое войдут номера записей в обратном порядке. Таблица должна быть отсортирована по полю id.
*/

SELECT
    *,
    ROW_NUMBER() OVER (ORDER BY vt.id DESC) as "rn"
FROM
    stackoverflow.vote_types as vt
ORDER BY
    vt.id asC

/*
6. Отберите 10 пользователей, которые поставили больше всего голосов типа Close. 
Отобразите таблицу из двух полей: идентификатором пользователя и количеством голосов. 
Отсортируйте данные сначала по убыванию количества голосов, потом по убыванию значения идентификатора пользователя.
*/

SELECT
    v.user_id,
    COUNT(v.id) as votes_id_count 
FROM
    stackoverflow.vote_types as vt 
    INNER JOIN stackoverflow.votes as v ON vt.id = v.vote_type_id 
WHERE
    vt.name = 'Close' 
GROUP BY
    v.user_id 
ORDER BY
    votes_id_count DESC 
LIMIT
    10;
    

/*
7. Отберите 10 пользователей по количеству значков, полученных в период с 15 ноября по 15 декабря 2008 года включительно. 
Отобразите несколько полей:
- идентификатор пользователя;
- число значков;
- место в рейтинге — чем больше значков, тем выше рейтинг.
Пользователям, которые набрали одинаковое количество значков, присвойте одно и то же место в рейтинге.
Отсортируйте записи по количеству значков по убыванию, а затем по возрастанию значения идентификатора пользователя.
*/

SELECT
    u.id as user_id,
    COUNT(b.id) as badges_count,
    DENSE_RANK() OVER (ORDER BY COUNT(b.id) DESC) 
FROM
    stackoverflow.badges as b 
    INNER JOIN stackoverflow.users as u ON b.user_id = u.id 
WHERE 
    EXTRACT(YEAR FROM b.creation_date) = 2008 
AND (
       (EXTRACT(MONTH FROM b.creation_date) = 11 AND EXTRACT(DAY FROM b.creation_date) BETWEEN 15 AND 30) 
    OR (EXTRACT(MONTH FROM b.creation_date) = 12 AND EXTRACT(DAY FROM b.creation_date) BETWEEN 1 AND 15)
    )
GROUP BY
    u.id 
ORDER BY
    badges_count DESC,
    user_id ASC 
LIMIT
    10;
    

/*
8. Сколько в среднем очков получает пост каждого пользователя? Сформируйте таблицу из следующих полей:
- заголовок поста;
- идентификатор пользователя;
- число очков поста;
- среднее число очков пользователя за пост, округлённое до целого числа.
Не учитывайте посты без заголовка, а также те, что набрали ноль очков.
*/

SELECT
    p.title as post_title,
    u.id as user_id,
    p.score as post_score,
    ROUND(AVG(p.score) OVER (PARTITION BY u.id)) as post_score_avg
FROM
    stackoverflow.posts as p
    INNER JOIN stackoverflow.users as u ON p.user_id = u.id
WHERE
    p.title IS NOT NULL
    AND p.score != 0


/*
9. Отобразите заголовки постов, которые были написаны пользователями, получившими более 1000 значков. Посты без заголовков не должны попасть в список.
*/

WITH users_badges_cte as
(
    SELECT
        b.user_id as user_id,
        COUNT(b.id) as badges_count
    FROM
        stackoverflow.badges as b
    GROUP BY
        b.user_id
    ORDER BY
        badges_count DESC
)

SELECT
    p.title as post_title
FROM
    stackoverflow.posts as p
WHERE
    p.user_id IN
    (
        SELECT
            user_id
        FROM
            users_badges_cte
        WHERE
            badges_count > 1000
    )
    AND p.title IS NOT NULL


/*    
10. Напишите запрос, который выгрузит данные о пользователях из США (англ. United States). 
Разделите пользователей на три группы в зависимости от количества просмотров их профилей:
- пользователям с числом просмотров больше либо равным 350 присвойте группу 1;
- пользователям с числом просмотров меньше 350, но больше либо равно 100 — группу 2;
- пользователям с числом просмотров меньше 100 — группу 3.
Отобразите в итоговой таблице идентификатор пользователя, количество просмотров профиля и группу. 
Пользователи с нулевым количеством просмотров не должны войти в итоговую таблицу.
*/

WITH usa_users_cte as
(
    SELECT
        *
    FROM
        stackoverflow.users as u
    WHERE
        u.location LIKE '%United States%'
)

SELECT
    id as user_id,
    views,
    CASE
        WHEN (views >= 350) THEN 1
        WHEN (100 <= views) AND (views < 350) THEN 2
        WHEN (views < 100) THEN 3
    END views_group
FROM
    usa_users_cte
WHERE
    views != 0

    
/*
11. Дополните предыдущий запрос. 
Отобразите лидеров каждой группы — пользователей, которые набрали максимальное число просмотров в своей группе. 
Выведите поля с идентификатором пользователя, группой и количеством просмотров. 
Отсортируйте таблицу по убыванию просмотров, а затем по возрастанию значения идентификатора.
*/

WITH usa_users_cte as
(
    SELECT
        *
    FROM
        stackoverflow.users as u
    WHERE
        u.location LIKE '%United States%'
),

views_group_cte as
(
    SELECT
        id as user_id,
        views,
        CASE
            WHEN (views >= 350) THEN 1
            WHEN (100 <= views) AND (views < 350) THEN 2
            WHEN (views < 100) THEN 3
        END views_group
    FROM
        usa_users_cte
    WHERE
        views != 0
)

SELECT
    user_id,
    views_group,
    views
FROM
(
    SELECT
        *,
        MAX(views) OVER (PARTITION BY views_group) as max_views
    FROM
        views_group_cte
) as st
WHERE
    views = max_views
ORDER BY
    views DESC,
    user_id ASC

  
/*
12. Посчитайте ежедневный прирост новых пользователей в ноябре 2008 года. Сформируйте таблицу с полями:
- номер дня;
- число пользователей, зарегистрированных в этот день;
- сумму пользователей с накоплением.
*/

SELECT
    EXTRACT(DAY FROM creation_date) as day_number,
    COUNT(u.id) users_count,
    SUM(COUNT(u.id)) OVER (ORDER BY EXTRACT(DAY FROM creation_date) ASC) as users_count_cum_sum
FROM
    stackoverflow.users as u
WHERE
    DATE_TRUNC('month', creation_date)::date = '2008-11-01'::date
GROUP BY
    day_number
    

/*
13. Для каждого пользователя, который написал хотя бы один пост, найдите интервал между регистрацией и временем создания первого поста. 
Отобразите:
- идентификатор пользователя;
- разницу во времени между регистрацией и первым постом.
*/

WITH reg_posts_cte as
(
    SELECT
        u.id as user_id,
        u.creation_date as reg_date,
        p.creation_date as post_date,
        FIRST_VALUE(p.creation_date) OVER (PARTITION BY u.id ORDER BY p.creation_date ASC) as first_post_date
    FROM
        stackoverflow.users as u
        INNER JOIN stackoverflow.posts as p ON u.id = p.user_id
)

SELECT
    user_id,
    post_date - reg_date as reg_post_interval
FROM
    reg_posts_cte
WHERE
    post_date = first_post_date