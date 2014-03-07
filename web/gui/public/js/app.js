/*
######################################################################
Copyright (C) 2007-2014, GoodData(R) Corporation. All rights reserved.
Author: patrick.mcconlogue@gooddata.com (thnkr)
######################################################################
*/

var App = Ember.Application.create({
    log: function(message) {
        if (window.console) console.log(message);
    }
});

App.Store = DS.Store.extend({
    adapter: DS.RESTAdapter
});

App.Router.map(function() {
    this.route("index", {path: "/"});
    this.resource("app", {path: "/app"}, function() {
        this.route("", {path: '/app/:app_uri'});
    });
});


App.ApplicationController = Em.Controller.extend({

    isLoaded: false, 

    apps: [],
    
    init: function () {

        var controller = this; 

        obj = {
            url: '/api/apps',
            type: 'json',
            method: 'get'
        }
        
        $.ajax(obj).then(function(apps){
            console.log(apps);
            controller.set('apps', apps);
            controller.set('isLoaded', true);
        });

    }

});