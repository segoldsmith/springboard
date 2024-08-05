/* Welcome to the SQL mini project. You will carry out this project partly in
the PHPMyAdmin interface, and partly in Jupyter via a Python connection.

This is Tier 2 of the case study, which means that there'll be less guidance for you about how to setup
your local SQLite connection in PART 2 of the case study. This will make the case study more challenging for you: 
you might need to do some digging, aand revise the Working with Relational Databases in Python chapter in the previous resource.

Otherwise, the questions in the case study are exactly the same as with Tier 1. 

PART 1: PHPMyAdmin
You will complete questions 1-9 below in the PHPMyAdmin interface. 
Log in by pasting the following URL into your browser, and
using the following Username and Password:

URL: https://sql.springboard.com/
Username: student
Password: learn_sql@springboard

The data you need is in the "country_club" database. This database
contains 3 tables:
    i) the "Bookings" table,
    ii) the "Facilities" table, and
    iii) the "Members" table.

In this case study, you'll be asked a series of questions. You can
solve them using the platform, but for the final deliverable,
paste the code for each solution into this script, and upload it
to your GitHub.

Before starting with the questions, feel free to take your time,
exploring the data, and getting acquainted with the 3 tables. */


/* QUESTIONS 
/* Q1: Some of the facilities charge a fee to members, but some do not.
Write a SQL query to produce a list of the names of the facilities that do. */

SELECT name 
FROM Facilities 
WHERE membercost = 0

/* Q2: How many facilities do not charge a fee to members? */

4

/* Q3: Write an SQL query to show a list of facilities that charge a fee to members,
where the fee is less than 20% of the facility's monthly maintenance cost.
Return the facid, facility name, member cost, and monthly maintenance of the
facilities in question. */

SELECT facid, name, membercost, monthlymaintenance 
FROM Facilities 
WHERE membercost > 0 AND membercost < (.2 * monthlymaintenance);

/* Q4: Write an SQL query to retrieve the details of facilities with ID 1 and 5.
Try writing the query without using the OR operator. */

SELECT * 
FROM Facilities 
WHERE facid IN (1, 5);

/* Q5: Produce a list of facilities, with each labelled as
'cheap' or 'expensive', depending on if their monthly maintenance cost is
more than $100. Return the name and monthly maintenance of the facilities
in question. */

SELECT name, monthlymaintenance, 
CASE WHEN monthlymaintenance <= 100 THEN 'cheap'
	ELSE 'expensive' END AS result
FROM Facilities;


/* Q6: You'd like to get the first and last name of the last member(s)
who signed up. Try not to use the LIMIT clause for your solution. */

SELECT firstname, surname
FROM Members
WHERE joindate IN
	(SELECT MAX(joindate)
	FROM Members);


/* Q7: Produce a list of all members who have used a tennis court.
Include in your output the name of the court, and the name of the member
formatted as a single column. Ensure no duplicate data, and order by
the member name. */

/*Based on the phrasing of the question, I was not sure if duplicates meant that the output should only return 1 name regardless of whether they played on multiple courts, or if it should include 1 name/court pairing per name. As such, I have made a query for both. 
Output is distinct to member name and court name pairings. As a result, output has duplicate member names, but unique member name and court name pairing (i.e., if a member played multiple times on courts 1 and 2, the output returns the first instance of them playing on each court, for a total of 2 entries).*/

SELECT DISTINCT CONCAT_WS(' ',m.firstname, m.surname) AS fullname, f.name
FROM Bookings AS b
INNER JOIN Facilities as f
ON b.facid = f.facid
INNER JOIN Members as m
ON b.memid = m.memid
WHERE f.name LIKE 'Tennis%' AND m.surname <> 'GUEST'
ORDER BY m.surname;

/*Output is distinct to member name, regardless of whether they played on 1 or both tennis courts (i.e., if a member played multiple times on courts 1 and 2, the output only returns the first instance of them playing tennis, for a total of 1 entry).*/

SELECT DISTINCT CONCAT_WS(' ',m.firstname, m.surname) AS fullname, f.name
FROM Bookings AS b
INNER JOIN Facilities as f
ON b.facid = f.facid
INNER JOIN Members as m
ON b.memid = m.memid
WHERE f.name LIKE 'Tennis%' AND m.surname <> 'GUEST'
GROUP BY fullname
ORDER BY m.surname;


/* Q8: Produce a list of bookings on the day of 2012-09-14 which
will cost the member (or guest) more than $30. Remember that guests have
different costs to members (the listed costs are per half-hour 'slot'), and
the guest user's ID is always 0. Include in your output the name of the
facility, the name of the member formatted as a single column, and the cost.
Order by descending cost, and do not use any subqueries. */

SELECT f.name, CONCAT_WS(' ',m.firstname, m.surname) AS fullname, 
CASE WHEN b.memid > 0 THEN (f.membercost * b.slots)
	ELSE f.guestcost * b.slots END AS cost
FROM Bookings as b
INNER JOIN Facilities as f
ON b.facid = f.facid
INNER JOIN Members as m
on b.memid = m.memid
WHERE b.starttime BETWEEN '2012-09-14 00:00:00' AND '2012-09-14 23:59:59' 
HAVING cost > 30
ORDER BY cost DESC;


/* Q9: This time, produce the same result as in Q8, but using a subquery. */

SELECT f.name, CONCAT_WS(' ', m.firstname, m.surname) AS fullname, booking_details.cost
FROM (SELECT b.facid, b.memid,
         CASE WHEN b.memid > 0 THEN (f.membercost * b.slots)
             ELSE (f.guestcost * b.slots) END AS cost
     FROM Bookings AS b
     INNER JOIN Facilities AS f ON b.facid = f.facid
     WHERE b.starttime BETWEEN '2012-09-14 00:00:00' AND '2012-09-14 23:59:59') AS booking_details
INNER JOIN Facilities AS f ON booking_details.facid = f.facid
INNER JOIN Members AS m ON booking_details.memid = m.memid
WHERE booking_details.cost > 30
ORDER BY booking_details.cost DESC;


/* PART 2: SQLite

Export the country club data from PHPMyAdmin, and connect to a local SQLite instance from Jupyter notebook 
for the following questions.  

QUESTIONS:
/* Q10: Produce a list of facilities with a total revenue less than 1000.
The output of facility name and total revenue, sorted by revenue. Remember
that there's a different cost for guests and members! */
conn = sqlite3.connect('sqlite_db_pythonsqlite.db')
q1 = ('SELECT f.name, SUM(CASE WHEN b.memid > 0 THEN (f.membercost * b.slots) \
    ELSE (f.guestcost * b.slots) END) AS revenue\
    FROM Bookings as b\
    INNER JOIN Facilities as f\
    ON b.facid = f.facid\
    INNER JOIN Members as m\
    on b.memid = m.memid\
    GROUP BY f.name\
    HAVING revenue < 1000\
    ORDER BY revenue DESC')
df1 = pd.read_sql_query(q1, conn)
conn.close()
df1


/* Q11: Produce a report of members and who recommended them in alphabetic surname,firstname order */
conn = sqlite3.connect('sqlite_db_pythonsqlite.db')

q1 = ("""SELECT m1.surname || ', ' || m1.firstname AS membername, 
        m2.surname || ', ' || m2.firstname AS recommendedbyName
    FROM Members AS m1
    INNER JOIN Members AS m2 ON m1.recommendedby = m2.memid
    WHERE m1.recommendedby > 0
    ORDER BY membername """)
df1 = pd.read_sql_query(q1, conn)
conn.close()
df1

/* Q12: Find the facilities with their usage by member, but not guests */

conn = sqlite3.connect('sqlite_db_pythonsqlite.db')
q1 = ('SELECT f.name, COUNT(b.memid) \
        FROM Bookings as b\
    INNER JOIN Facilities as f\
    ON b.facid = f.facid\
    WHERE b.memid > 0\
    GROUP BY f.name\
    ORDER BY f.name')
df1 = pd.read_sql_query(q1, conn)
conn.close()
df1


/* Q13: Find the facilities usage by month, but not guests */
conn = sqlite3.connect('sqlite_db_pythonsqlite.db')
q1 = """SELECT f.name AS facility_name, strftime('%m', b.starttime) AS month, COUNT(b.starttime) AS total_usage
    FROM Bookings AS b
    INNER JOIN Facilities AS f
    ON b.facid = f.facid
    WHERE b.memid > 0 
    GROUP BY b.facid, strftime('%m', b.starttime)"""
df1 = pd.read_sql_query(q1, conn)
conn.close()
df1
