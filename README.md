# app_store

App store is a place where you can take a code that solves specific problem. It provides a central repository and is maintained. Also the app in appstore represent years of condensed experience of what worked in the field.

## Status

[![Build Status](https://travis-ci.org/gooddata/app_store.svg)](https://travis-ci.org/gooddata/app_store)

### Brick
Brick is the something that is in app_store. We might rename it since this is a working title but what we try to convey with the name is that it is something that should be part of bigger whole. In your ETL there are many problems and brick should solve one problem particularly well. It should be tested parametrizable and to some extent flexible but mainly it should play well within the larger system. Typical ETL might look like this

### Ruby vs ?
While all our bricks are currently written in ruby this is not mandatory. Brick can be in any language as long as it is supported within GoodData platform. Since majority of the bricks are currently dealing with APIs imperative language is the most flexible way to go.

### Input data sources
As stated before we are trying to minimize the amount of glue code that is necessary to make things work. Since generally you do not know where your data would come from we want to give you power to consume wider number of sources so you do not have to change any code just configuration. What is considered a source you can recognize by the name of the parameter in the documentation of specific brick. The name of the parameter will be "*_input_source" or just "input_source". If it is named according to this convention then you can treat is as a datasource.

#### Staging
Staging is an ephemeral storage that is part of gooddata platform. It supports couple of protocols most useful of which is WebDAV so sometimes it is internally referred to as WebDAV. You can specify a data source to consume a file from staging like this.

The file is consumed as is. Majority of the bricks are expecting CSV that is parsed using a [!csv](http://ruby-doc.org/stdlib-1.9.2/libdoc/csv/rdoc/CSV.html) library.

#### Agile data service (ADS)
ADS is a database service. You can specify a query to ADS as a data source.

##### query with global connection
You have to specify how to connect to ads. This is configured using ads_client structure. 

    "ads_client": { "username": "username@example.com", "password": "secret", "dwh_id": "123898qajldna97ad8" },
    "input_source": {
  	  "type": "ads",
  	  "query": "SELECT * FROM my_table"
  	}

You can also omit username and password. In such case the defaults "GDC_USERNAME" and "GDC_PASSWORD" would be used. This is useful if you want different user than the one that is executing the rest of the task for example upload to webdav.

    "GDC_USERNAME": "username@example.com",
    "GDC_PASSWORD": "secret",
    "ads_client": { "dwh_id": "123898qajldna97ad8" },
    "input_source": {
  	  "type": "ads",
  	  "query": "SELECT * FROM my_table"
  	}

The query is consumed using our JDBC driver. And it is accessible in the code as an Array of Hashes. The keys of each hash is equivalent to the name of the column from the query.

##### File from web
You can consume a file on the web directly.

    "input_source": {
      "type": "web",
      "url": "https://gist.githubusercontent.com/fluke777/4005f6d99e9a8c6a9c90/raw/d7c5eb5794dfe543de16a44ecd4b2495591df057/domain_users.csv"
    }

The file is consumed as is. Majority of the bricks are expecting CSV that is parsed using a [!csv](http://ruby-doc.org/stdlib-1.9.2/libdoc/csv/rdoc/CSV.html) library.

### Output data sources

It would make sense to do something similar for the outputs and that is planned. Currently this is not implemented.

