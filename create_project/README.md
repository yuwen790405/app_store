= Build Project Brick

Brick that builds a project (model, reports, data) for you based on a spec. Of course you can use other tools like LDM modeler to do the same work but doing it programmatically has several advantages.

* programmable
* repeatable
* git (SCM) friendly
* easily shareable

##Examples

###Create based on the ruby spec
Ruby spec is the most flexible way how to specify a project. It is programmable on top of all the benefits JSON spec would offer. The most important thing in params is to correctly specify the type of the source.

    {
      "gooddata_project_creation_token" : "some_token",
      "gooddata_project_spec_uri"       : "https://gist.github.com/fluke777/8830288/raw/4147ab4550fab5ce910d920d8d5bb149314e15fc/model.rb",
      "gooddata_projec_spec_type"       : "rb"
    }

Have a look at the sdk site for tutorial how to create a model using ruby DSL.

###Create based on the json spec
Basically the same thing as with Ruby but JSON is just a data structure and you cannot program it which might be useful at times. The biggest difference is in providing different type

    {
      "gooddata_project_creation_token" : "some_token",
      "gooddata_project_spec_uri"       : "https://gist.github.com/fluke777/8830288/raw/4147ab4550fab5ce910d920d8d5bb149314e15fc/model.json",
      "gooddata_projec_spec_type"       : "json"
    }
    
