--creating netflix_db database 
CREATE DATABASE netflix_db;
--using netflix database
USE netflix_db;

--creating netflix table
CREATE TABLE netflix
(
    show_id VARCHAR(5),
    type VARCHAR(10),
    title VARCHAR(150),
    director VARCHAR(208),
    cast VARCHAR(1000),
    country	VARCHAR(150),
    date_added VARCHAR(50),
    release_year int,
    rating	VARCHAR(10),
    duration VARCHAR(15),
    listed_in VARCHAR(100),
    description VARCHAR(250)
);
--Inserting Rows in to netflix table
BULK INSERT netflix
FROM '/tmp/netflix_titles.csv'
WITH(
 FORMAT='CSV',
 FIRSTROW=2
);

-- Veiw table data 
SELECT  * from netflix;

-- Total rows 
SELECT COUNT(*) as Total_content from netflix

--15 Business Problem

--1. Count number of movies vs TV shows 
SELECT type , count(*) as count
from  netflix
GROUP BY [type]

--2. Find the most comman ratings for movie and TV shows 

SELECT  [type],rating
from
(SELECT [type],rating,COUNT(*) total_count,DENSE_RANK() OVER (PARTITION BY type ORDER BY count(*) DESC) AS rank
from netflix
GROUP by [type],rating)temp
WHERE rank=1

--3. List all movies released in specific year (e.g 2020)

SELECT * FROM
netflix
where  release_year = 2020 and [type] = 'movie'

--4. Find the top 5 contries with the most content on Netflix

SELECT TRIM(value) AS country_name,COUNT(show_id)as total_content
FROM netflix
CROSS APPLY STRING_SPLIT(country, ',')
where TRIM([value])<>''
GROUP BY TRIM([value])
ORDER by total_content DESC
offset 0 rows fetch next 5 rows only;

--5. Identify the longest Movie

SELECT * 
FROM netflix
WHERE [type] = 'Movie' and duration = (select MAX(duration)from netflix)

--6. Find the content added in the last 5 years
SELECT *
FROM netflix
WHERE TRY_CONVERT(date, date_added, 107) >= DATEADD(YEAR, -5, GETDATE());

--7. Find all the movies/TV shows directed by 'Rajiv Chilaka'.
select * 
from netflix
WHERE director like '%Rajiv Chilaka%';

--8. List all TV shows with more than 5 seasons.
select * 
from netflix
WHERE [type] = 'TV Show' and TRY_CAST(LEFT(duration,CHARINDEX(' ',duration)-1) as INT) >5;

--9. Count the number of content items in each genre.
select TRIM([value]) as genre , COUNT(*) as number
from netflix
CROSS APPLY string_split(listed_in,',')
GROUP by TRIM([value]);


--10. Find each year and the average numbers of content release by India on Netflix. Return top 5 year with highest avg content release!
SELECT YEAR(TRY_CONVERT(date,date_added,107)) as year ,COUNT(*) as count , round(COUNT(*)*1.0/(select COUNT(*) from netflix where country='India')*100,2) as average_no_of_content
from  netflix
WHERE country = 'India'
GROUP BY YEAR(TRY_CONVERT(date,date_added,107));

--11 select all the movies that are documentaries
SELECT * from netflix
where listed_in like '%documentaries%';

--12. Find all the content without a director

SELECT * from netflix
WHERE director is NULL;

--13.How many movies actor 'Salman Khan' appeared in last 10 years 
SELECT * from netflix
where [cast] like '%Salman Khan%' and release_year > YEAR(GETDATE())-10;

--14.Find the top 10 actors who have appreared in the highest number of movies produced in india.
select TRIM([value]) as actors,COUNT(*) as  total_movies
from netflix 
CROSS APPLY string_split([cast],',')
WHERE [type]='Movie'
GROUP BY TRIM([value])
ORDER BY total_movies DESC
OFFSET 0 rows FETCH NEXT 10 rows ONLY;

--15.Categorize the content based on the presence of the keywords 'kill' and 'violence' in the description field.
 --   Label content containing these keywords as 'Bad' and all others as 'Good'. Count how many items fall into each category
 with cte 
 as (
 SELECT* , case when [description] like '%kill%' or [description] like 'violence' then 'Bad'
            else 'Good' end as category
 from netflix
 )
 SELECT category,count(*) as total_content
 from cte 
 GROUP by category