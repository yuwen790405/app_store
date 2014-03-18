/*
######################################################################
Copyright (C) 2007-2014, GoodData(R) Corporation. All rights reserved.
Author: patrick.mcconlogue@gooddata.com (thnkr)
######################################################################

Todo:
-- Thread processes based on app directory to avoid fatal loading error when apps do not contain 'info.json'.

*/
var fs = require('fs');
var express = require('express');
var events = require('events');
var e = new events.EventEmitter();

process.on('uncauchtException', function(err){
    console.log(err);
});

_status={
    apps_loaded: 0,
    apps_failed: {
        app: [],
        count: 0,
    }
}

_apps = [];

_app_dirs = [];

_store = {

    loadApps: function() {

        dirs = fs.readdirSync('../../apps');

        _app_dirs = dirs;

            for(i=0;i<dirs.length;i++){

                app_path = '../apps/'+dirs[i];

                fs.readFile(app_path+'/info.json', function(err, data){

                    data = JSON.parse(data);
                    _status.apps_loaded++;
                    _apps.push(data);


                    if(_apps.length == dirs.length){

                        console.log('Apps loaded: '+_status.apps_loaded);
                        e.emit('apps');

                    }

                });
            }
    },

    server: function()  {

        var app = express();

        app.set('views', __dirname + '/views');
        app.use(express.static(__dirname + '/public'));
        app.use(express.cookieParser());
        app.use(express.methodOverride());
        app.use(express.bodyParser());

        app.engine('html', require('ejs').renderFile);
        app.get('/', function(req, res){
            res.render('index.html', { 
                user:'hello', 
            });

        });

        // REST API

        app.get('/api/apps', function(req, res){
            
            res.send(_apps);

        });

        app.listen(3000);

    }, 

    submitApp: function(key, file) { 

        console.log('Session:'+key);
    }
        
}

e.on('apps', _store.server);

_store.loadApps();


