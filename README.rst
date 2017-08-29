Sahara Tools
============

Some simple scripts for working with OpenStack sahara.

Building images
---------------

Images can be built and/or registered with Glance using
``build-spark-image.sh``::

    ./build-spark-image.sh [<build|register>]

Various environment variables are accepted, see the environment files under
``environment`` for examples. The built images will be present under the
``sahara-image-elements`` directory.

Creating clusters
-----------------

Node group templates, cluster templates, and clusters can be created using
``sahara-cluster-create.sh``::

    ./sahara-cluster-create.sh

Similar environment variables are accepted as for the ``build-spark-image.sh``
script, so again see the environment files under ``environment`` for examples.

Examples
--------

Some simple Hadoop examples are provided in ``hadoop-examples``, and Spark
examples in ``spark-examples``.
