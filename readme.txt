This is a Perl program that grabs Jeff Atwood's codinghorror.com search engine
keyword referral statistics from statcounter.com. Since Jeff made his
website stats publicly available, this is completely white hat stuff.

The program was written by Peteris Krumins (peter@catonmat.net).
His blog is at http://www.catonmat.net  --  good coders code, great reuse.

The code is licensed under the GNU GPL license.

The code was written as a part of the article "Analyzing Keyword Activity on
Coding Horror" on my website. The whole article can be read at:

  http://www.catonmat.net/blog/analyzing-keyword-activity-on-coding-horror/

------------------------------------------------------------------------------

Table of contents:

    [1] The codinghorror_kwstats.pl program.
    [2] Creating the SQLite database.
    [3] Sample database.
    [4] Some useful queries.
    [5] Program dependencies.


[1]-The-codinghorror_kwstats.pl-program---------------------------------------

One thing that caught my attention on Coding Horror blog was the publicly
available keyword stats:

http://statcounter.com/project/standard/stats.php?project_id=2600027&guest=1

The free version of statcounter.com that Jeff uses keeps only the last 500
entries of any traffic activity, therefore I wrote codinghorror_kwstats.pl
program to gather the data in an SQLite database.

In general the program can be invoked as following:

    $ perl codinghorror_kwstats.pl [-nodb] [number of pages to extract]

If -nodb parameter is specified, the keywords are not inserted in the database,
they are just printed to stdout. Otherwise they are stored in 'codinghorror.db'
(can be changed in the source code of the program by modifying $db_path
variable).

If [number of pages to extract] is specified, the program grabs that many pages
from statcounter.com. Otherwise grabs one page.

Here is sample output from the program:

    $ ./codinghorror_kwstats.pl -nodb
    27 Nov 2009 12:50:27: xps m1330 ahci download
    27 Nov 2009 12:50:27: remote desktop windows key
    27 Nov 2009 12:50:17: gfx lowest power consumption
    27 Nov 2009 12:50:15: modding internet lessons
    27 Nov 2009 12:50:12: run xp on vista computer 4gb
    27 Nov 2009 12:50:10: iis on xp allow more users
    27 Nov 2009 12:49:56: system idle process
    27 Nov 2009 12:49:55: evony advertisements
    27 Nov 2009 12:49:45: what is system idle process
    27 Nov 2009 12:49:31: multimonitor productivity
    27 Nov 2009 12:49:31: evony advertisements
    27 Nov 2009 12:49:22: nvidia wont let me choose my primary display
    27 Nov 2009 12:49:11: dell xps 1330m
    27 Nov 2009 12:48:37: system idle process hogs cpu
    27 Nov 2009 12:48:34: rdp login does not work anymore
    27 Nov 2009 12:48:27: modding internet lessons
    27 Nov 2009 12:48:24: application.doevents()
    27 Nov 2009 12:48:23: low physical memory vista
    27 Nov 2009 12:48:23: how to know when energizer rechargeable batteries are done


[2]-Creating-the-SQLite-database----------------------------------------------

The schema of the database is in "schema.txt" file in the source tree. To
create the database use the following sqlite command:

    $ sqlite codinghorror.db < schema.txt

This will create 'codinghorror.db' database with the right schema.

In case schame.txt gets missing, here it is (it's really simple):

    CREATE TABLE queries (
        id        INTEGER PRIMARY KEY,
        query     TEXT,
        unix_date INTEGER,
        human_date TEXT
    );
    CREATE UNIQUE INDEX unique_query_date ON queries (query, unix_date);


[3]-Sample-database-----------------------------------------------------------

When I wrote this program, I gathered a sample database to play with. The data
in this database is from March 31, 2008 till April 8, 2008. It contains 73,336
records and is 7MB in size.

It can be downloaded at my website:

    http://www.catonmat.net/download/codinghorror-keyword-database.zip

See the next section [4] for some sample queries on this database.


[4]-Some-useful-queries-------------------------------------------------------

* Find 20 most popular keywords:

    SELECT COUNT(query) c, query
    FROM queries
    GROUP BY query
    ORDER BY c DESC
    LIMIT 20;
    
  This query is also located in query-20-most-popular-keywords.txt file. You can
  run it directly from command line:

    $ sqlite ./codinghorror.db < query-20-most-popular-keywords.txt


* Find 20 most popular keywords with percent of all total:

    SELECT
      COUNT(query) c,
      (ROUND(COUNT(query)/(1.0*(SELECT COUNT(*) FROM queries)),3)*100) || '%',
      query
    FROM queries
    GROUP BY query
    ORDER BY c DESC
    LIMIT 20;

  Run it directly from command line with this command:

  $ sqlite ./codinghorror.db < query-20-most-popular-keywords-with-percent.txt


* Find 20 most popular keywords with percent of all total and percent of the
  most popular one:

  This query is too large to include here, run it from query-super.txt:

    $ sqlite ./codinghorror.db < query-super.txt


[5]-Program-dependencies------------------------------------------------------

The program depends on the following CPAN modules:

    * WWW::Mechanize
    * HTML::TreeBuilder
    * Date::Parse
    * DBI and DBD::SQLite


------------------------------------------------------------------------------

That's it. Happy keyword research! ;)


Sincerely,
Peteris Krumins
http://www.catonmat.net


