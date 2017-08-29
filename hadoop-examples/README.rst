===============
Hadoop Examples
===============

Running Hadoop MapReduce examples
---------------------------------

http://www.informit.com/articles/article.aspx?p=2190194&seqNum=3

List Examples
=============

Via YARN:

.. code-block::

   sudo su - hadoop yarn jar /opt/hadoop-2.7.1/share/hadoop/mapreduce/hadoop-mapreduce-examples-2.7.1.jar 
   Last login: Wed Jun 14 16:16:16 UTC 2017 on pts/0
   An example program must be given as the first argument.
   Valid program names are:
     aggregatewordcount: An Aggregate based map/reduce program that counts the words in the input files.
     aggregatewordhist: An Aggregate based map/reduce program that computes the histogram of the words in the input files.
     bbp: A map/reduce program that uses Bailey-Borwein-Plouffe to compute exact digits of Pi.
     dbcount: An example job that count the pageview counts from a database.
     distbbp: A map/reduce program that uses a BBP-type formula to compute exact bits of Pi.
     grep: A map/reduce program that counts the matches of a regex in the input.
     join: A job that effects a join over sorted, equally partitioned datasets
     multifilewc: A job that counts words from several files.
     pentomino: A map/reduce tile laying program to find solutions to pentomino problems.
     pi: A map/reduce program that estimates Pi using a quasi-Monte Carlo method.
     randomtextwriter: A map/reduce program that writes 10GB of random textual data per node.
     randomwriter: A map/reduce program that writes 10GB of random data per node.
     secondarysort: An example defining a secondary sort to the reduce.
     sort: A map/reduce program that sorts the data written by the random writer.
     sudoku: A sudoku solver.
     teragen: Generate data for the terasort
     terasort: Run the terasort
     teravalidate: Checking results of terasort
     wordcount: A map/reduce program that counts the words in the input files.
     wordmean: A map/reduce program that counts the average length of the words in the input files.
     wordmedian: A map/reduce program that counts the median length of the words in the input files.
     wordstandarddeviation: A map/reduce program that counts the standard deviation of the length of the words in the input files.

Run Pi Example
==============

Via Hadoop:

.. code-block::

   sudo su - hadoop hadoop jar /opt/hadoop-2.7.1/share/hadoop/mapreduce/hadoop-mapreduce-examples-2.7.1.jar pi 10 100

Via YARN:

.. code-block::

   sudo su - hadoop yarn jar /opt/hadoop-2.7.1/share/hadoop/mapreduce/hadoop-mapreduce-examples-2.7.1.jar pi 10 100
