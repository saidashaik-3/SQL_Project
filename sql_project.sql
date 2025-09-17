create database sql_project;
drop database sql_project;

use sql_project;


-- Table 1: Job Department
CREATE TABLE JobDepartment (
    Job_ID INT PRIMARY KEY,
    jobdept VARCHAR(50),
    name VARCHAR(100),
    description TEXT,
    salaryrange VARCHAR(50)
);
-- Table 2: Salary/Bonus
CREATE TABLE SalaryBonus (
    salary_ID INT PRIMARY KEY,
    Job_ID INT,
    amount DECIMAL(10,2),
    annual DECIMAL(10,2),
    bonus DECIMAL(10,2),
    CONSTRAINT fk_salary_job FOREIGN KEY (job_ID) REFERENCES JobDepartment(Job_ID)
        ON DELETE CASCADE ON UPDATE CASCADE
);
-- Table 3: Employee
CREATE TABLE Employee (
    emp_ID INT PRIMARY KEY,
    firstname VARCHAR(50),
    lastname VARCHAR(50),
    gender VARCHAR(10),
    age INT,
    contact_add VARCHAR(100),
    emp_email VARCHAR(100) UNIQUE,
    emp_pass VARCHAR(50),
    Job_ID INT,
    CONSTRAINT fk_employee_job FOREIGN KEY (Job_ID)
        REFERENCES JobDepartment(Job_ID)
        ON DELETE SET NULL
        ON UPDATE CASCADE
);

-- Table 4: Qualification
CREATE TABLE Qualification (
    QualID INT PRIMARY KEY,
    Emp_ID INT,
    Position VARCHAR(50),
    Requirements VARCHAR(255),
    Date_In DATE,
    CONSTRAINT fk_qualification_emp FOREIGN KEY (Emp_ID)
        REFERENCES Employee(emp_ID)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

-- Table 5: Leaves
CREATE TABLE Leaves (
    leave_ID INT PRIMARY KEY,
    emp_ID INT,
    date DATE,
    reason TEXT,
    CONSTRAINT fk_leave_emp FOREIGN KEY (emp_ID) REFERENCES Employee(emp_ID)
        ON DELETE CASCADE ON UPDATE CASCADE
);

-- Table 6: Payroll
CREATE TABLE Payroll (
    payroll_ID INT PRIMARY KEY,
    emp_ID INT,
    job_ID INT,
    salary_ID INT,
    leave_ID INT,
    date DATE,
    report TEXT,
    total_amount DECIMAL(10,2),
    CONSTRAINT fk_payroll_emp FOREIGN KEY (emp_ID) REFERENCES Employee(emp_ID)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_payroll_job FOREIGN KEY (job_ID) REFERENCES JobDepartment(job_ID)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_payroll_salary FOREIGN KEY (salary_ID) REFERENCES SalaryBonus(salary_ID)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_payroll_leave FOREIGN KEY (leave_ID) REFERENCES Leaves(leave_ID)
        ON DELETE SET NULL ON UPDATE CASCADE
);


select * from jobdepartment;
select * from salarybonus;
select * from employee;
select * from qualification;
select * from leaves;
select * from payroll;


-- Analysis Questions
-- 1. EMPLOYEE INSIGHTS
-- How many unique employees are currently in the system?
select count(emp_ID) as unique_employees from employee;


--  Which departments have the highest number of employees?
select jobdept,count(jobdept) as count_emp from jobdepartment j 
join employee e on j.job_id=e.job_id 
group by j.jobdept
order by count_emp desc
limit 3;

-- What is the average salary per department?
select j.jobdept,avg(s.amount) as avg_salary,avg(s.annual) as avg_annul from jobdepartment j
join salarybonus s on j.job_id=s.job_id 
group by j.jobdept;

-- Who are the top 5 highest-paid employees?
select e.emp_id,e.firstname,s.amount from salarybonus s join employee e 
on s.job_id=e.job_id
order by amount desc 
limit 5; 

--  What is the total salary expenditure across the company?
select sum(amount) as total_salary from salarybonus;

-- 2. JOB ROLE AND DEPARTMENT ANALYSIS
--  How many different job roles exist in each department? 
select jobdept,count(distinct name) as job_roles from jobdepartment group by jobdept;

-- What is the average salary range per department?
select j.jobdept,avg(s.amount) as avg_salary,
(max(s.amount)+min(s.amount))/2 as avg_salary_range,
max(s.amount) as maxsalary,
min(s.amount) as minsalary
from jobdepartment j join salarybonus s on 
j.job_id=s.job_id 
group by j.jobdept;

--  Which job roles offer the highest salary?
select j.name as job_role,max(s.amount) as high_salary from jobdepartment j join salarybonus s 
on j.job_id=s.job_id
group by job_role
order by high_salary desc
limit 5;

-- Which departments have the highest total salary allocation?
select j.jobdept,sum(s.amount) as total_salary 
from jobdepartment j join salarybonus s 
on j.job_id=s.job_id 
group by j.jobdept
order by total_salary desc;

-- 3. QUALIFICATION AND SKILLS ANALYSIS
-- How many employees have at least one qualification listed?
SELECT COUNT(DISTINCT Emp_ID) AS Employees_With_Qualification
FROM Qualification;

--  Which positions require the most qualifications?
select position,count(*) as num_qualification from qualification
group by position 
order by num_qualification desc;

-- Which employees have the highest number of qualifications?
WITH EmpQualCount AS (
  SELECT Emp_ID,
         COUNT(*) AS Qualification_Count
  FROM Qualification
  GROUP BY Emp_ID
)
SELECT EQC.Emp_ID, EQC.Qualification_Count, E.firstname, E.lastname
FROM EmpQualCount EQC
JOIN Employee E ON E.emp_ID = EQC.Emp_ID
WHERE EQC.Qualification_Count = (
  SELECT MAX(Qualification_Count) FROM EmpQualCount
);


-- 4. LEAVE AND ABSENCE PATTERNS 
-- Which year had the most employees taking leaves?
select extract(year from date),count(*) as leave_count 
from leaves 
group by extract(year from date);

-- What is the average number of leave days taken by its employees per department?
select j.jobdept,AVG(extract(day from date)) as avg_leave from leaves l join employee e on l.emp_id=e.emp_id
join jobdepartment j on e.job_id=j.job_id
group by j.jobdept;

-- Which employees have taken the most leaves?
select e.emp_id,sum(extract(day from date)) as most_leaves from leaves l join employee e on l.emp_id=e.emp_id
group by e.emp_id
order by most_leaves desc;

-- What is the total number of leave days taken company-wide?




-- How do leave days correlate with payroll amounts?
select p.emp_id,extract(day from l.date) as leave_day,p.date as pay_roll_date,total_amount 
from leaves l 
join payroll p on l.leave_id=p.leave_id;


-- 5. PAYROLL AND COMPENSATION ANALYSIS 
-- What is the total monthly payroll processed?
select extract(year from date) as year,
extract(month from date) as month, 
sum(total_amount) as total from payroll
group by extract(year from date),extract(month from date)
order by year,month;

-- What is the average bonus given per department?
select j.jobdept,avg(s.bonus) as avg_bonus 
from jobdepartment j join salarybonus s on j.job_id=s.job_id
group by j.jobdept;

-- Which department receives the highest total bonuses?
select j.jobdept,sum(s.bonus) as total_bonus 
from jobdepartment j join salarybonus s on j.job_id=s.job_id
group by j.jobdept
order by total_bonus desc
limit 1;

-- What is the average value of total_amount after considering leave deductions?
select avg(total_amount) as avg_value from payroll;


-- 6. EMPLOYEE PERFORMANCE AND GROWTH 
--  Which year had the highest number of employee promotions?
select extract(year from date_in) as high_year,
count(extract(year from date_in)) as count
from qualification
group by extract(year from date_in)
order by count desc
limit 1;







