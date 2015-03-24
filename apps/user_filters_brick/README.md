Data Filters Brick
==================
This brick provides improved way to handle data permissions set up both through mandatory filters and variables.

## Important terms

### Data filter
Data filters are basically whatever comes after WHERE in MAQL. Imagine

    WHERE city IN ('San Francisco', 'Prague', 'Amsterdam')

The difference is that in both cases you can define it per user.

### Variable
Variable is a per user filter. You can apply a variable on per report basis so you can basically pick which report will be filtered and which not. This is different with mandatory filters.

### Mandatory filter
Mandatory filter is again a filter that is defined per user. The difference that a intersection of all filters is applied to every computation a user performs automatically so it is well suited to implement security rules.

## Colum-based vs row-based sources of data
In many cases you cannot pick what kind of data you get. We are trying to help minimize glue code as much as possible. You can easily configure this brick to accept couple types of input with respect to its shape and name of the columns. Let's try to illustrate different shapes given the example with cities at the beginning.

Imagine there are two users in your system and you would like to set him with these values.

 login              | filter
--------------------|----------
 john@example.com   | WHERE city ('San Francisco', 'Prague', 'Amsterdam')
 jane@example.com   | WHERE city ('San Francisco', 'Dublin')

### Column based

This is how the values would be expressed in a column based file.

 login              | city          | other_unused_value
--------------------|---------------|-------------
 john@example.com   | San Francisco | x
 john@example.com   | Prague        | x
 john@example.com   | Amsterdam     | y
 jane@example.com   | Dublin        | y
 jane@example.com   | San Francisco | y

Take note that multiple values are expressed by repeating the user. Brick also deduplicates the values before setting them as Data Filters. This might easily happen if you got the file for filters as an output of a join.

Notice that in our case the file has headers but this is not a requirement and brick can cope with both situations.

### Row based
While column based file is the most commonly used source but imagine that a different kind of file would arrive. The example above could be also expressed like this
         
  \\ \\                 | \\ \\ \\
 -------------------|---------------------------------------
 john@example.com   | "San Francisco", "Prague", "Amsterdam"
 jane@example.com   | "Dublin", "San Francisco"
 
Notice that this file cannot have headers since we do not know how many columns we will have.

## Use cases
