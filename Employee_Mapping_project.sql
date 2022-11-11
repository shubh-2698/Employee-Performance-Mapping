-- Checking all Existing Databases;
show databases;

-- Creating Database Employee and ensuring no such database exists previously
-- which will be used to create tables, import data and analyze the information from it.
create database if not exists employee;

-- Using the newly created database
use employee;
-- Database needs to include three tables Data Science Team, Project Table and Employee Record Table
-- I Firstly created data science table with following attributes
drop table if exists ds_team;
create table if not exists ds_team
(emp_id varchar(10) not null, 
f_name varchar(25) not null,
l_name varchar(25) not null, 
gender varchar(1) not null,
role varchar(100) not null,
dept varchar(50) not null, 
experience int not null,
country varchar(25) not null,
continent varchar(25) not null,
primary key (emp_id));

-- Creating second table for the Projects and their status
drop table if exists projects;
create table if not exists projects (proj_id varchar(4) not null,
									proj_name varchar(100) not null,
                                    domain varchar(25) not null,
                                    start_date date not null,
                                    closure_date date not null,
                                    dev_qtr varchar(5) not null,
                                    status varchar(25) not null,
                                    constraint qtr_check check (dev_qtr in ('Q1', 'Q2', 'Q3', 'Q4')),
                                    constraint closure_date_check check (closure_date <= '2022-03-31'),
                                    constraint start_date_check check (start_date >= '2021-04-01'),
                                    constraint proj_id_check check (substr(proj_id,1,1) in ('P')),
									primary key (proj_id));

-- Creating 3rd table for employee records and their details
drop table if exists emp_record;
create table if not exists emp_record(emp_id varchar(4) not null,
									f_name varchar(25) not null,
                                    l_name varchar(25) not null,
                                    gender varchar(1) not null,
                                    role varchar(100) not null,
                                    dept varchar(25) not null,
                                    exp int not null,
                                    country varchar(25) not null,
									continent varchar(25) not null,
                                    salary int not null,
                                    rating int not null,
                                    manager_id varchar(25),
                                    proj_id varchar(4),
                                    constraint emp_key foreign key(emp_id) references ds_team(emp_id) on delete cascade on update cascade,
                                    constraint proj_key foreign key(proj_id) references projects(proj_id) on delete cascade on update cascade);

-- Checking tables description
describe ds_team;
describe projects;
describe emp_record;

-- Importing couple entries using insert command and rest using import wizard

insert into ds_team values('E005',	'Eric',	'Hoffman',	'M',	'LEAD DATA SCIENTIST',	'FINANCE',	11,	'USA',	'NORTH AMERICA'),
							('E010',	'William',	'Butler',	'M',	'LEAD DATA SCIENTIST',	'AUTOMOTIVE',	12,	'FRANCE',	'EUROPE');

-- Checking all values inserted into the tables
select * from ds_team;
select * from emp_record;
select * from projects;

-- Task 1: Check ER diagram of the model and cross check relationships.
-- I used the Ctrl + R combination on Windows key and on screen instructions to create ER diagram
use employee;
-- Task 2 : Fetching the employee details from employee records
select emp_id, f_name, l_name, gender, dept
from emp_record;

-- Task 3: Fetching employee details with rating less than 2, greater than 4, between 2&4
select emp_id, f_name, l_name, gender, dept
from emp_record
where rating <2;

select emp_id, f_name, l_name, gender, dept
from emp_record
where rating >4;

select emp_id, f_name, l_name, gender, dept
from emp_record
where rating between 2 and 4;

-- Task 3: Combining first and last name of employee from finance department and aliasing the column as name
select Concat(f_name , ' ' , l_name) as Name
from emp_record
where dept in ('Finance');

-- Selecting count of employees reporting to their seniors and their senior details including president.

select e.emp_id, e.f_name, e.l_name, e.role, count(e.emp_id) as Reporters from emp_record e
inner join emp_record f 
on e.emp_id = f.manager_id
where e.role in ('President','CEO', 'Manager')
group by e.emp_id
order by Reporters desc;

-- Fetching details of employees from finance and healthcare department and union them
select emp_id, f_name, l_name, role, dept from emp_record
where dept = 'Finance'
Union
select emp_id, f_name, l_name, role, dept from emp_record
where dept = 'Healthcare';

-- fetching details of employee wrt to their department and comparing their rating to the maximum in respective department.
select emp_id, f_name, l_name, role, dept, rating , max(rating) over (partition by dept order by rating desc) as Maximum_Rating
from emp_record;

-- Fetching details of minimum and maximum salary in each role and comparing the salary of each employee
select emp_id, f_name, l_name, role, salary, min(salary) over (partition by role) as Minimum_Salary,
max(salary) over (partition by role) as Maximum_Salary
from emp_record
order by salary;

-- Ranking the employees based on their experience. Lowest rank represents the oldest employee in organization
select emp_id, f_name, l_name, exp, dense_rank() over (order by exp desc) as Dense_Ranking,
rank() over (order by exp desc) as Ranking
from emp_record;

-- Creating view to fetch only those employees having salary greater than 6000 from all countries
drop view if exists emp_salary;
create view  emp_salary as 
select emp_id, f_name, l_name, role, country, salary from emp_record
where salary > 6000;

select * from emp_salary
order by salary;

-- Creating nested query to fetch employee details having experience greater than 10 years. 
select emp_id, f_name, l_name, role from (select * from emp_record where exp > 10) as Exp10;

-- Create a procedure to fetch details of only employees where experience is greater than certain years based on the input provided by user
-- Exluding Top most senior positions from the list as we only need list of employees

drop procedure if exists emp_salary;
delimiter &&
create procedure emp_salary( in x int)
begin
select emp_id, f_name, l_name, role, exp, salary from emp_record
where exp > x and role not in ('CEO', 'President', 'Manager')
order by exp;
end &&
delimiter ;
call emp_salary(10);

-- Creating index to improve the cost of query and find the details of employee based on their name.
select * from emp_record
where f_name = 'Eric';

-- Before index query cost is found to be at 2.15 sec
create index First_name on emp_record(f_name);

-- Checking indexes
show indexes from emp_record;

-- Fetching details using index
select * from emp_record where f_name = 'Eric';

-- After creating index query cost is only 0.35 sec
-- Now Calculating bonuses for employees based on their rating and salary . Bonus = 5%of salary * rating
select emp_id, f_name, l_name, salary, rating, round((0.05 * salary * rating),0) as Bonus
from emp_record
order by bonus desc;

-- Fetching average salary of employees based on continent and country
select emp_id, f_name, l_name, country, continent, 
round(avg(salary) over (partition by continent order by country),0) as Average_Salary
from emp_record;