# Exercise 1: Transaction

## Step 1: Create a lock

- Start SQL Server Management Studio
- Connect to the Server North 

* Open three query windows
* In window 1

```sql
USE AdventureWorks
BEGIN TRAN
	UPDATE Person.Person
	SET LastName='Andersson'
	WHERE BusinessEntityID=1
```
* In window 2

```sql
USE AdventureWorks
  SELECT * FROM Person.Person WHERE BusinessEntityID=1
```

## Step 2: Examine the lock
* In window 3

```sql
EXEC sp_who2
```

Identify the suspended (blocked) query and the blocking query
