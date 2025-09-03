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

## Step 2: Examine the lock using sp_who2
* In window 3

```sql
EXEC sp_who2
```

Identify the suspended (blocked) query and the blocking query

## Step 3: Examine the lock using sp_whoisactive

* Download and install sp_whoisactive from [http://whoisactive.com/](http://whoisactive.com/)<img width="279" height="53" alt="image" src="https://github.com/user-attachments/assets/541fd6b5-029f-4850-a875-599c78f476de" />


```sql
EXEC sp_who2
```

Identify the suspended (blocked) query and the blocking query
