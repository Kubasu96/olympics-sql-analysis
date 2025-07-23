 
select *  from athlete_events;
select * from regions;
--olympics games that have been held
select count (distinct(Games)) as total_games
from athlete_events;

--2.	List down all Olympics games held so far.
select distinct(Games)
from athlete_events;

--3.	Mention the total no of nations who participated in each olympics game?
select games, count(distinct NOC) AS Total_Countries
from athlete_events
group by Games
order by Games;

--4.	Which year saw the highest and lowest no of countries participating in olympics?
with TC as 
(select 
games, count(distinct NOC) AS Total_Countries 
from athlete_events
group by Games
)
select 
max(concat (games,' - ',Total_Countries)) as HighestCountries,
min(concat (games,' - ',Total_Countries)) as LowestCountries
from TC
;

--5.	Which nation has participated in all of the olympic games?

with TG as
( select count(distinct Games) as totalgames
from athlete_events),
NG as (
select nr.region as Nation, a.Games
FROM athlete_events a
join regions nr
on a.NOC = nr.NOC
),
NT as (select Nation, count(distinct Games) as TotalGamesParticipated
from NG
group by Nation)
select Nation,TotalGamesParticipated
from NT
WHERE
TotalGamesParticipated = 51;

--6.	Identify the sport which was played in all summer olympics.
select distinct sport
from athlete_events
where Games like '%summer';

--7. Which Sports were just played only once in the olympics.
with GS AS (
select  distinct Games, sport
from athlete_events
),
T1 as
(
SELECT sport, count(1) as totalgames
from GS
group by sport)
select * from T1
where totalgames = 1
;


--8.	Fetch the total no of sports played in each olympic games.
 with TA as
 (select distinct games, sport
from athlete_events)
select games, count(1) as totalSports
from TA
group by games
order by totalSports desc;

--9.	Fetch details of the oldest athletes to win a gold medal.
with T1 as 
(
select ID, Name, Sex,  
coalesce(Age, 0) as Age, Height, Weight, Team, NOC, Games, Year, Season, City, Sport, Event, Medal
from athlete_events
),
T2 as 
(select T1.ID, T1.Name, T1.Sex, T1.Age, T1.Height, T1.Weight, T1.Team, re.region, T1.Games, T1.Year, T1.Season, T1.City, T1.Sport, T1.Event, T1.Medal
from T1
JOIN regions re on T1.NOC = re.NOC
),
ranks as
(
select * ,rank() over (order by Age desc) as rnk
from T2
where Medal = 'Gold'
)
select*
from ranks
where rnk = 1;

--10. Find the Ratio of male and female athletes participated in all olympic games.
with T1 as (
select sex, count(1) as TotalParticipants
from athlete_events
group by sex
),
T2 as(
Select sex, TotalParticipants, row_number () over (order by TotalParticipants desc) as rn
from T1),
T3 as(
select TotalParticipants as males from T2 where rn = 1),
T4 as (
select TotalParticipants as females from T2 where rn = 2)
select concat('1 : ',T3.males/T4.females) as Ratio
from T3,T4;

--11.	Fetch the top 5 athletes who have won the most gold medals.
with T1 as (
select Name, Medal
from athlete_events),
T2 as (
select Name, count(Medal) as GoldMedals
from T1
WHERE Medal = 'Gold'
group by Name) ,
T3 as(
select  Name, GoldMedals, rank() over (order by GoldMedals desc) as rnk
from T2)
select top 5 Name, GoldMedals
from T3
where rnk <5
order by GoldMedals desc;

--12.	Fetch the top 5 athletes who have won the most medals (gold/silver/bronze).
with T1 as (
select Name, Medal
from athlete_events),
T2 as (
select Name, count(Medal) as Medals
from T1
group by Name) ,
T3 as(
select  Name, Medals, dense_rank() over (order by Medals desc) as rnk
from T2)
select top 5 Name, Medals
from T3
where rnk <=5
order by Medals desc;

--13.	Fetch the top 5 most successful countries in olympics. Success is defined by no of medals won.
with T1 as (select rn.region as Country, a.Medal as Medals
from athlete_events a
join regions rn
on rn.NOC= a.NOC
where medal <> 'NA'),
T2 as (
select Country, count(1) as Totalmedals
from T1
group by Country),
T3 as (
 select Country, TotalMedals, dense_rank() over (order by TotalMedals desc) as rnk
 from T2)
 select Country,TotalMedals, rnk
 from T3
 where rnk <= 5; 

 --14.	List down total gold, silver and broze medals won by each country.
 with T1 as (select rn.region as Country, a.Medal as Medals
from athlete_events a
join regions rn
on rn.NOC= a.NOC
)
select country, 
sum(CASE WHEN Medals = 'Gold' THEN 1 ELSE 0 END) as Gold,
sum(CASE WHEN Medals = 'Bronze' THEN 1 ELSE 0 END) as Bronze,
sum(CASE WHEN Medals = 'Silver' THEN 1 ELSE 0 END) as Silver
from T1
where medalS <> 'NA'
group by Country
order by Gold Desc;


--15.	List down total gold, silver and broze medals won by each country corresponding to each olympic games.
 with T1 as (select rn.region as Country, a.Games, a.Medal as Medals
from athlete_events a
join regions rn
on rn.NOC= a.NOC
)
select country, Games,
sum(CASE WHEN Medals = 'Gold' THEN 1 ELSE 0 END) as Gold,
sum(CASE WHEN Medals = 'Bronze' THEN 1 ELSE 0 END) as Bronze,
sum(CASE WHEN Medals = 'Silver' THEN 1 ELSE 0 END) as Silver
from T1
where medalS <> 'NA'
group by Country,Games
order by Games asc;

--16.	Identify which country won the most gold, most silver and most bronze medals in each olympic games.
with CT as (select rn.region as Country, a.Games, a.Medal as Medals
from athlete_events a
join regions rn 
on rn.NOC= a.NOC
),
MC as (
select Country, Games,
sum(CASE WHEN Medals = 'Gold' THEN 1 ELSE 0 END) as Gold,
sum(CASE WHEN Medals = 'Bronze' THEN 1 ELSE 0 END) as Bronze,
sum(CASE WHEN Medals = 'Silver' THEN 1 ELSE 0 END) as Silver
from CT
where medals <> 'NA'
group by Country,Games
),
G1 as (select Country, Games, Gold, row_number() over (partition by Games order by Gold desc) as rn1
from MC),
B1 as (select Country, Games, Bronze, row_number() over (partition by Games order by Bronze desc) as rn2
from MC),
S1 as (select Country, Games, Silver, row_number() over (partition by Games order by Silver desc) as rn3
from MC),
MG as (
select Games, concat(Country,'-',Gold) as Max_Gold
from G1
where rn1 =1
),
MB as (
select Games, concat(Country,'-',Bronze) as Max_Bronze
from B1
where rn2 =1
),
MS as (
select Games, concat(Country,'-',Silver) as Max_Silver
from S1
where rn3 =1
)
select MG.Games, MG.Max_Gold, MB.Max_Bronze, MS.Max_Silver
from MG
join MB on MG.Games = MB.Games
JOIN MS on MG.Games = MS.Games
order by Games asc;

--17. Identify which country won the most gold, most silver, most bronze medals and the most medals in each olympic game
with CT as (select rn.region as Country, a.Games, a.Medal as Medals
from athlete_events a
join regions rn 
on rn.NOC= a.NOC
),
MC as (
select Country, Games,
sum(CASE WHEN Medals = 'Gold' THEN 1 ELSE 0 END) as Gold,
sum(CASE WHEN Medals = 'Bronze' THEN 1 ELSE 0 END) as Bronze,
sum(CASE WHEN Medals = 'Silver' THEN 1 ELSE 0 END) as Silver,
count(Medals) as Total_Medals
from CT
where medalS <> 'NA'
group by Country,Games
),
G1 as (select Country, Games, Gold, row_number() over (partition by Games order by Gold desc) as rn1
from MC),
B1 as (select Country, Games, Bronze, row_number() over (partition by Games order by Bronze desc) as rn2
from MC),
S1 as (select Country, Games, Silver, row_number() over (partition by Games order by Silver desc) as rn3
from MC),
TM1 as (select Country, Games, Total_Medals, row_number() over (partition by Games order by Total_Medals desc) as rn4
from MC),
MG as (
select Games, concat(Country,'-',Gold) as Max_Gold
from G1
where rn1 =1
),
MB as (
select Games, concat(Country,'-',Bronze) as Max_Bronze
from B1
where rn2 =1
),
MS as (
select Games, concat(Country,'-',Silver) as Max_Silver
from S1
where rn3 =1),
MTM as (
select Games, concat(Country,'-',Total_Medals) as Max_Total_Medals
from TM1
where rn4 =1
)
select MG.Games, MG.Max_Gold, MB.Max_Bronze, MS.Max_Silver, MTM.Max_Total_Medals
from MG
join MB on MG.Games = MB.Games
JOIN MS on MG.Games = MS.Games
join MTM on MG.Games = mtm.Games
order by Games asc;

--18. Which countries have never won gold medal but have won silver/bronze medals?
with CTE as (select rn.region as Country, a.Games, a.Medal as Medals
from athlete_events a
join regions rn 
on rn.NOC= a.NOC
where Medal <>'NA'
),
TM as (
select Country, Games, 
 sum(case when Medals = 'Gold' then 1 else 0 end) as Gold_Medals,
 sum(case when Medals = 'Bronze' then 1 else 0 end) as Bronze_Medals,
 sum(case when Medals = 'Silver' then 1 else 0 end) as Silver_Medals
 from CTE
 group by Country, Games)
 select * from TM
 where Gold_Medals = 0 
 order by  Games asc;

 --19. In which Sport/event, India has won highest medals.
 with CTE as (select rn.region as Country, a.Games, a.Sport, a.Medal as Medals
from athlete_events a
join regions rn 
on rn.NOC= a.NOC
where Medal <>'NA'),
TM as (
select Sport, count(Medals) as Total_Medals
from CTE
Where country = 'India'
group by Sport
),
Rnk as (
select Sport, Total_Medals, row_number() over (order by Total_Medals desc) as rn
from TM)
select Sport, Total_Medals
from Rnk
where rn = 1;

--20. Break down all olympic games where India won medal for Hockey and how many medals in each olympic games
with CTE as (select rn.region as Country, a.Team, a.Games, a.Sport, a.Medal as Medals
from athlete_events a
join regions rn 
on rn.NOC= a.NOC
where Medal <>'NA' and Sport = 'Hockey'
)
select Games, Team, Sport, count(Medals) as Total_Medals
from CTE
where Country = 'India'
group by Games, Team, Sport
order by Total_Medals desc;