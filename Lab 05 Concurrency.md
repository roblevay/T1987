# Exercise 1: Transactions and locks

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

## Step 2: Examine the lock using sp_who2
* In window 3

```sql
EXEC sp_who2
```

Identify the suspended (blocked) query and the blocking query

## Step 3: Examine the lock using sp_whoisactive

* Download and install sp_whoisactive from https://github.com/roblevay/T1987/Files
* Open a new query window and run 

```sql
EXEC sp_whoisactive
```

Identify the suspended (blocked) query and the blocking query

## Step 4: Examine the lock using sp_blitzwho

* Download and install sp_blitzwho from https://github.com/roblevay/T1987/Files
* Open a new query window and run 

```sql
EXEC sp_blitzwho
```

Identify the suspended (blocked) query and the blocking query

## Step 5: Dirty read

* Open a new query window and run 

```sql
SELECT *
FROM Person.Person WITH (NOLOCK)
WHERE BusinessEntityID = 1;
```
* You can now read in an open transaction (dirty read)

## Step 6: Rollback the transaction

* Return to Query window 1 which reads


```sql
USE AdventureWorks
BEGIN TRAN
	UPDATE Person.Person
	SET LastName='Andersson'
	WHERE BusinessEntityID=1
```

* Execute the following:

```sql
ROLLBACK TRAN
```

* Now, the blocking lock is released and the value in Person.Person is returned to the original value
* Close all open query windows


