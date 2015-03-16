# Hierarchy brick
This brick aims to provide you out of the box couple of hierarchy implementations that are typically used by implementations at gooddata. Underlying this implementation is library [https://github.com/fluke777/user_hierarchies](https://github.com/fluke777/user_hierarchies) so if you need anything specific you can use it directly.

## Types of input
Brick accepts data in adjacency tree. This means that representing this hierarchy

![Example hierarchy](https://www.dropbox.com/s/j25qw0ef2ra6q20/hierarchy_brick_hierarchy_example.png?dl=0&raw=1)

would be represented by file containing this data. It is convenient because it an be stored in a flat file or database file of a known structure.

 id | parent | department
----|--------------------
 A  | B      | sales
 B  | A      | eng
 C  | A      | marketing
 D  | E      | support
 
##Types of output

The adjacency list input is very information rich because it is basically serialization of a sparse matrix. Unfortunately it is not so useful to work with inside typical data tools since it requires recursive processing. Here we provide several output variants that are easier to use inside gooddata. You can transform into them by parametrizing the app.

### Subordinates closure tuples
The first type expands the hierarchy to contain all the relationships not just child -> parent as in adjacency list. For our example the output would look like this.

#### Output

 parent_id | subordinate_id
-----------|---------------
  A        |  A
  A        |  B
  A        |  C
  A        |  D
  A        |  E
  B        |  B
  B        |  D
  B        |  E
  D        |  D
  E        |  E
  C        |  C
  
This is much more nicer to work with visually. Try to find if E is a subordinate of C in the first one vs this one. Also it is nicer to work with in non recursive languages. It is directly useful for uploading to GoodData for usage in Data filters with OVER etc.

#### Additional fields
You can provide names of additional fields that will be propagated from the source hierarchy.


### Fixed level hierarchy
In certain cases it is very useful to flatten the hierarchy to a rectangular shape. This is useful if you would like to use the hierarchy as part of the dimension.

#### Preconditions
There are couple of preconditions that has to be valid in this case

* There is one supervisor at the top of the hierarchy
* Each subordinate has at most one supervisor

#### Output
Our example fulfills both of the precondition and the output would look like this.

 level_1 | level_2 | level_3 | level
---------|---------|---------|-------
  A      |  A      |  A      |  1
  A      |  B      |  B      |  2
  A      |  B      |  D      |  3
  A      |  B      |  E      |  3
  A      |  C      |  C      |  2
  
#### Additional fields
You can provide names of additional fields that will be propagated from the source hierarchy.

