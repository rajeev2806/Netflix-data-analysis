-- handling foreign characters


--remove duplicates

select show_id,count(*) 
from netflix_data
group by show_id
having count(*)>1

select *
from netflix_data
where (upper(title),type) in (
select upper(title),type
from netflix_data
group by upper(title),type
having count(*)>1
)
order by title

with cte as(
select *,row_number() over(partition by upper(title),type  order by show_id) rn
from netflix_data
)

select *
from cte
where rn=1


--new table for listed_in,director,country,cast

select show_id,trim(d.value) as genre
into netflix_genre
from netflix_data
join
lateral unnest(string_to_array(listed_in,',')) as d(value)
on true;

select *
from netflix_genre

conversion of date_added datatype

 with cte as(
select *,row_number() over(partition by upper(title),type  order by show_id) rn
from netflix_data
)

select show_id,type,title,cast(date_added as date) as date,release_year,rating,duration,description
from cte
where rn=1

-- populate missing values in country,directors columns

insert into netflix_countries
select show_id,nr.director
from netflix_data nr
inner join (
select dir as director,country
from netflix_countries as nc
inner join netflix_directors as nd on nc.show_id=nd.show_id
group by dir,country
) as  a 
on nr.director=a.director
where nr.country is null
order by show_id

select dir,country
from netflix_countries as nc
inner join netflix_directors as nd on nc.show_id=nd.show_id
group by dir,country

select *
from netflix_data
where duration is null

 with cte as(
select *,row_number() over(partition by upper(title),type  order by show_id) rn
from netflix_data
)

select show_id,type,title,cast(date_added as date) as date,release_year,rating,
       case when duration is null then rating else duration end as duration,description
into netflix
from cte
where rn=1 

select *
from netflix

-- netflix data analysis


--1  for each director count the no of movies and tv shows created by them in separate columns 
for directors who have created tv shows and movies both */

select nd.dir as director,count(case when n.type ='Movie' then n.show_id end) as no_of_movies,
 		count(case when n.type='TV Show' then n.show_id end) as no_of_show
from netflix as n
inner join netflix_directors as nd on n.show_id=nd.show_id
group by nd.dir
having count(distinct n.type)>1

--2 which country has highest number of comedy movies 

with cte as (
select nc.country,count(distinct n.show_id) as cnt
from netflix_genre as ng
inner join netflix_countries as nc on ng.show_id=nc.show_id
inner join netflix n on nc.show_id=n.show_id
where ng.genre='Comedies' and n.type='Movie'
group by nc.country
)
select *
from cte
order by cnt desc
limit 1

--3 for each year (as per date added to netflix), which director has maximum number of movies released

with cte as(
select nd.dir as director,extract(year from n.date) yr,count(n.show_id) as cnt
from netflix as n 
inner join netflix_directors as nd on n.show_id=nd.show_id
where n.type='Movie'
group by nd.dir,yr
 ),
cte2 as(
select *,row_number()over(partition by yr order by cnt desc,director) as c
from cte

)

select *
from cte2
where c=1

--4 what is average duration of movies in each genre


select round(avg(cast(replace(n.duration,'min','')as INTEGER)),2) as avg_duration,ng.genre
from netflix n
inner join netflix_genre ng on n.show_id=ng.show_id
where n.type='Movie'
group by ng.genre

--5  find the list of directors who have created horror and comedy movies both.
-- display director names along with number of comedy and horror movies directed by them 

with cte as(
select n.show_id show_id,nd.dir director,ng.genre as genre
from netflix n
inner join netflix_directors nd on n.show_id=nd.show_id
inner join netflix_genre ng on nd.show_id=ng.show_id
where n.type='Movie' and(ng.genre='Comedies' or ng.genre='Horror Movies')
),
cte2 as(
select director,count( distinct case when genre='Horror Movies' then show_id end ) as horror,
		count( distinct case when genre='Comedies' then show_id end ) as comedy
from cte
group by director
having count(distinct genre)=2
)

select *
from cte2
