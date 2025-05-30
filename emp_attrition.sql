create database emp_perf;
use emp_perf;

create table dim_employee (emp_id int primary key,
    first_name varchar(15),
    last_name varchar(15),
    gender varchar(10),
    age int,
    marital_status varchar(10),
    
    education_level varchar(15),
    job_tenure int,
    current_salary int,
    distance_from_home int);

create table dim_department (dept_id int primary key,
    dept_name varchar(50));

create table dim_job_role ( job_role_id int primary key,
    job_role_name varchar(50),
    base_salary int);

create table fact_emp_perf ( perf_id int primary key,
	emp_id int,
    dept_id int,
    job_role_id int,
    performance_rating int,
    
    last_promotion_year int,
    training_hours int,
    work_life_balance int,
    job_satisfaction int,
    current_salary int,
    foreign key (emp_id) references dim_employee(emp_id),
    
    foreign key (dept_id) references dim_department(dept_id),
    foreign key (job_role_id) references dim_job_role(job_role_id));

create table fact_employee_attrition (attr_id int primary key,
	emp_id int,
    dept_id int,
    job_role_id int,
    attrition boolean,
    exit_interview_score int,
    final_salary int,
    
    foreign key (emp_id) references dim_employee(emp_id),
    foreign key (dept_id) references dim_department(dept_id),
    foreign key (job_role_id) references dim_job_role(job_role_id));
    
select * from dim_department;

select * from dim_job_role;

select * from dim_employee;

select * from fact_emp_perf;

select * from fact_employee_attrition;


# Employee Satisfaction Score: Aggregate of employee feedback on work conditions, leadership, and job satisfaction.

select emp_id, round((work_life_balance + job_satisfaction) / 2,1) as Employee_Satisfaction_Score from fact_emp_perf;

# Average Tenure: The average length of time employees remain with the company.

select avg(job_tenure) as Average_Tenure from dim_employee;


# Attrition Rate: Percentage of employees leaving over a given period. 

select (sum(attrition) * 100.0 / (select count(*) from dim_employee)) as Attrition_Rate from fact_employee_attrition;

# Performance Rating Distribution: Categorization of employees based on performance scores.

select performance_rating, count(*) as no_of_employees from fact_emp_perf group by performance_rating order by performance_rating;

---------------------------------------------------------------------
# Department-wise Attrition Trends: Comparison of attrition across different departments. 

select d.dept_name, (sum(f.attrition) * 100.0 /(select count(*) from dim_employee)) as Attrition_Rate from fact_employee_attrition f 
join dim_department d on f.dept_id = d.dept_id group by d.dept_name order by Attrition_Rate desc;


# Exit Interview Sentiment Analysis: Text analysis of exit interviews to identify common reasons for attrition.

select emp_id,  exit_interview_score, if(exit_interview_score < 4, 'negative feedback', 'positive feedback') as exit_feedback
from fact_employee_attrition where attrition = 1;

select if(exit_interview_score < 4, 'negative feedback', 'positive feedback') as exit_feedback, count(*)
from fact_employee_attrition where attrition = 1 group by exit_feedback;

------------------------------------------------------
# employees with a long distance from home

select emp_id, distance_from_home, if(distance_from_home > avg(distance_from_home),'long distance from home','good distance') as reason
from dim_employee  where emp_id in (select emp_id from fact_employee_attrition where attrition = 1);

--------------------------------------------------------
# employees with low job satisfaction scores

select emp_id, job_satisfaction, if(job_satisfaction < 4, 'low job satisfaction','good job satisfaction') as reason
from fact_emp_perf  where emp_id in (select emp_id from fact_employee_attrition where attrition = 1);

select if(job_satisfaction < 4, 'low job satisfaction','good job satisfaction') as reason,count(*)
from fact_emp_perf  where emp_id in (select emp_id from fact_employee_attrition where attrition = 1) group by reason;

---------------------------------------------------------
# employees with low work life balance scores

select emp_id, work_life_balance, if(work_life_balance < 4, 'poor work life balance','good work life balance') as reason
from fact_emp_perf where emp_id in (select emp_id from fact_employee_attrition where attrition = 1);

select if(work_life_balance < 4, 'poor work life balance','good work life balance') as reason, count(*)
from fact_emp_perf where emp_id in (select emp_id from fact_employee_attrition where attrition = 1) group by reason;

----------------------------------------------------------------
# employees with low performance rating

select emp_id, performance_rating, if(performance_rating < 3,'poor performance','good performance')as reason
from fact_emp_perf  where emp_id in (select emp_id from fact_employee_attrition where attrition = 1);

select if(performance_rating < 3,'poor performance','good performance')as reason, count(*)
from fact_emp_perf  where emp_id in (select emp_id from fact_employee_attrition where attrition = 1) group by reason;
------------------------------------------------------------------
# employees with delayed promotion

select f.last_promotion_year, sum(if(a.attrition = 1, 1, 0)) as attrition_count from fact_emp_perf f
join fact_employee_attrition a on f.emp_id = a.emp_id group by f.last_promotion_year order by f.last_promotion_year;

select if(f.last_promotion_year < 2022,'delayed promotion','on time promotion')as reason, sum(if(a.attrition = 1, 1, 0)) as attrition_count
from fact_emp_perf f join fact_employee_attrition a on f.emp_id = a.emp_id group by reason;
