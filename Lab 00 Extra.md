Här är en färdig extraövning i Markdown på engelska:

# Extra Exercise: Index Tuning with AdventureWorks

## Goal

In this exercise, you will practice identifying queries that may benefit from indexes, use Database Engine Tuning Advisor to get index recommendations, and review and improve queries written by another participant.

The database used in this exercise is **AdventureWorks**, which is a copy of **AdventureWorks2016**.

## Instructions

Work in pairs.

### Part 1: Select Tables

Choose **five tables** from the AdventureWorks database.

Try to choose tables that contain enough rows to make query performance relevant.

### Part 2: Write Queries

For each selected table, write one query that could benefit from an index.

Each query should include a condition that filters rows, for example using a `WHERE` clause against a column that does not already have a useful index.

Example:

```sql
SELECT *
FROM Sales.SalesOrderHeader
WHERE CustomerID = 11000;
```

You do not have to use this exact table or column. The purpose is to create queries where SQL Server may benefit from an additional index.

### Part 3: Use Database Engine Tuning Advisor

Test your queries with **Database Engine Tuning Advisor**.

For each query:

1. Run the query or include it in a tuning workload.
2. Let Database Engine Tuning Advisor analyze it.
3. Review the index recommendations.
4. Save the recommendations.

You should save either:

* the generated script,
* screenshots of the recommendations,
* or a short written summary of the suggested indexes.

### Part 4: Exchange Queries

Send your original five queries to your partner.

Do not include your own index recommendations or optimized versions at this stage.

### Part 5: Optimize Your Partner’s Queries

Analyze your partner’s five queries.

For each query:

1. Examine the table and existing indexes.
2. Decide whether a new index could improve the query.
3. Use Database Engine Tuning Advisor if needed.
4. Write an optimized version of the query and/or propose a suitable index.

Example index proposal:

```sql
CREATE NONCLUSTERED INDEX IX_SalesOrderHeader_CustomerID
ON Sales.SalesOrderHeader(CustomerID);
```

### Part 6: Give Feedback

Give your partner feedback on their queries and your proposed optimizations.

Your feedback should include:

* whether the original query was a good candidate for indexing,
* what index you suggest, if any,
* why the index may improve performance,
* whether there are any possible disadvantages, such as extra storage or slower inserts/updates/deletes.

## Deliverables

Submit or present the following:

1. Your five original queries.
2. The Database Engine Tuning Advisor recommendations for your own queries.
3. Your partner’s five queries.
4. Your optimized versions or index suggestions for your partner’s queries.
5. Short feedback to your partner.

## Reflection Questions

Answer briefly:

1. Did Database Engine Tuning Advisor suggest the same indexes that you expected?
2. Were any recommendations surprising?
3. Can an index ever make performance worse? Explain briefly.
4. What is the difference between improving a query and adding an index?
