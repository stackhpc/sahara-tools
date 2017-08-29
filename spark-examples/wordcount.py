import pyspark


def main():
     sc = pyspark.SparkContext("local", "Word Count")
     input = sc.textFile("id_rsa")
     count = (input.flatMap(lambda line:  line.split(" "))
         .map(lambda word: (word, 1))
         .reduceByKey(lambda x, y: x + y))
     count.saveAsTextFile("outfile")
     print "OK"


if __name__ == "__main__":
     main()
