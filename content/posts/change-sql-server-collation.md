+++
title = "Change SQL Server Collation"
date = "2019-11-07T14:25:45-05:00"
author = "derek"
cover = ""
tags = ["sql-server", "database"]
keywords = ["", ""]
description = "For when you stand up a SQL Server and realize the database collation is wrong."
showFullContent = false
+++

I’ve been doing a lot of work lately in Microsoft Azure. When you spin up a new VM using the SQL server template the database collation is `SQL_Latin1_General_CP1_CI_AS`. The primary system I deploy into these databases requires that the database be `Latin1_General_CI_AI`. While there are other ways to accomplish this change below is what I have found to be the quickest and most consistent way to update the collation.

** *Note: This is not recommended on databases already holding data, but it should work the same.*

1. On the DB server open SQL Server Configuration Manager
2. Stop the SQL Server Services that are running
3. Open an elevated Command Prompt and navigate to `C:\Program Files\Microsoft SQL Server\MSSQL14.MSSQLSERVER\MSSQL\Binn`
4. Run `sqlservr -m -T4022 -T3659 -q "Latin1_General_CI_AI"` replacing `Latin1_General_CI_AI` with your required collation. The flag `-T4022` will bypass database startup and `-T3659` will write errors to the logs.
5. When the Command Prompt shows a success message, close the cmd window
6. Start services back up in SQL Server Configuration Manager

After completing these steps the database will be the expected/required collation.
