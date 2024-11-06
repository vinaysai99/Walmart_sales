SELECT * FROM walmart_db.walmart;

/*
1. Analyze Payment methods and sales
- What are the different payment methods, and how many transactions and items were sold with each method?
*/

SELECT payment_method,
       Count(payment_method) AS Count,
       Round(Sum(total),2)           AS Purchases
FROM   walmart_db.walmart
GROUP  BY payment_method
ORDER  BY Sum(total) DESC; 

/*
2. Identify the Highest Rated Category in Each Branch
- Which category received the highest average rating in each branch?
*/

SELECT branch, category, avg_rating
FROM (
    SELECT 
        branch,
        category,
        AVG(rating) AS avg_rating,
        RANK() OVER(PARTITION BY branch ORDER BY AVG(rating) DESC) AS rank_num
    FROM walmart_db.walmart
    GROUP BY branch, category
) AS ranked
WHERE rank_num = 1;


/*
3. Determine the Busiest Day for each Branch
- What is the busiest day of the week for each branch bases on transaction volume?
*/

SELECT branch, day_name, no_transactions
FROM (
    SELECT 
        branch,
        DAYNAME(STR_TO_DATE(date, '%d/%m/%Y')) AS day_name,
        COUNT(*) AS no_transactions,
        RANK() OVER(PARTITION BY branch ORDER BY COUNT(*) DESC) AS ranking
    FROM walmart_db.walmart
    GROUP BY branch, day_name
) AS ranked
WHERE ranking = 1;

/*
4. Calculate total Quantity sold by payment method
- How many items were sold through each payment method?
*/   

SELECT payment_method,
       Sum(quantity)
FROM   walmart_db.walmart
GROUP  BY payment_method; 

/*
5. Analyze Category Ratings by City 
- What are the average, minimum, and maximum ratings for each category in each city? 
*/

SELECT city,
       category,
       Round(Avg(rating), 2),
       Max(rating),
       Min(rating)
FROM   walmart_db.walmart
GROUP  BY city,
          category
ORDER  BY city ASC,
          Avg(rating)DESC; 
   
/*
6. Calculate Total Profit by Category 
- What is the total profit for each category, ranked from highest to lowest? 
*/

SELECT category,
       Round(Sum(profit_margin * total), 2) AS profit
FROM   walmart_db.walmart
GROUP  BY category
ORDER  BY profit DESC; 

/*
7. Determine the Most Common Payment Method per Branch 
- What is the most frequently used payment method in each branch? 
*/

SELECT branch,
       payment_method,
       number
FROM   (SELECT branch,
               payment_method,
               Count(*) AS frequency,
               Rank()
                 OVER(
                   partition BY branch
                   ORDER BY Count(*) DESC ) AS ranking
        FROM   walmart_db.walmart
        GROUP  BY branch,payment_method) AS new
WHERE  ranking = 1; 

/*
8. Analyze Sales Shifts Throughout the Day 
- How many transactions occur in each shift (Morning, Afternoon, Evening) across branches? 
*/

SELECT branch,
       CASE
         WHEN Hour(Time(time)) < 12 THEN 'Morning'
         WHEN Hour(Time(time)) BETWEEN 12 AND 17 THEN 'Afternoon'
         ELSE 'Evening'
       END      AS shift,
       Count(*) AS num_invoices
FROM   walmart_db.walmart
GROUP  BY branch,
          shift
ORDER  BY branch,
          num_invoices DESC; 

/*
9. Identify Branches with Highest Revenue Decline Year-Over-Year
- Which branches expenenced the largest decrease in revenue compared to the previous year? 
*/


WITH revenue_2022 AS
(
         SELECT   branch,
                  Sum(total) AS revenue
         FROM     walmart_db.walmart
         WHERE    Year(Str_to_date(date, '%d/%m/%Y')) = 2022
         GROUP BY branch ), revenue_2023 AS
(
         SELECT   branch,
                  Sum(total) AS revenue
         FROM     walmart_db.walmart
         WHERE    Year(Str_to_date(date, '%d/%m/%Y')) = 2023
         GROUP BY branch )
SELECT   r2022.branch,
         r2022.revenue                                                     AS last_year_revenue,
         r2023.revenue                                                     AS current_year_revenue,
         Round(((r2022.revenue - r2023.revenue) / r2022.revenue) * 100, 2) AS revenue_decrease_ratio
FROM     revenue_2022                                                      AS r2022
JOIN     revenue_2023                                                      AS r2023
ON       r2022.branch = r2023.branch
WHERE    r2022.revenue > r2023.revenue
ORDER BY revenue_decrease_ratio DESC limit 5;