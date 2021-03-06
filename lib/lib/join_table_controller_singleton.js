// Generated by CoffeeScript 1.9.2

/*
  backbone-rest.js 0.5.3
  Copyright (c) 2013 Vidigami - https://github.com/vidigami/backbone-rest
  License: MIT (http://www.opensource.org/licenses/mit-license.php)
 */

(function() {
  var JoinTableController, JoinTableControllerSingleton, _, path;

  path = require('path');

  _ = require('backbone-orm')._;

  JoinTableController = null;

  JoinTableControllerSingleton = (function() {
    function JoinTableControllerSingleton() {
      this.join_tables = {};
    }

    JoinTableControllerSingleton.prototype.reset = function() {
      return this.join_tables = {};
    };

    JoinTableControllerSingleton.prototype.generateByOptions = function(app, options) {
      var _key, err, i, join_table_auth, join_table_endpoint, join_table_options, join_table_parts, join_table_url, key, len, ref, ref1, ref2, ref3, relation, results, route_parts, route_root, schema;
      if (!JoinTableController) {
        JoinTableController = require('./join_table_controller');
      }
      route_parts = options.route.split('/');
      route_parts.pop();
      route_root = route_parts.join('/');
      schema = options.model_type.schema();
      ref = schema.relations;
      results = [];
      for (key in ref) {
        relation = ref[key];
        if (!(relation && relation.join_table)) {
          continue;
        }
        try {
          join_table_url = _.result(new relation.join_table, 'url');
          join_table_parts = join_table_url.split('/');
          join_table_endpoint = join_table_parts.pop();
        } catch (_error) {
          err = _error;
          console.log("JoinTableControllerSingleton.generateControllers: failed to parse url. Error: " + err);
          continue;
        }
        join_table_options = _.clone(options);
        join_table_options.route = path.join(route_root, join_table_endpoint);
        if (join_table_options.route[0] !== '/') {
          join_table_options.route = "/" + join_table_options.route;
        }
        if (this.join_tables[join_table_options.route]) {
          continue;
        }
        ref1 = ['whitelist', 'templates', 'default_template'];
        for (i = 0, len = ref1.length; i < len; i++) {
          _key = ref1[i];
          delete join_table_options[_key];
        }
        join_table_options.model_type = relation.join_table;
        if (join_table_auth = (ref2 = options.auth) != null ? (ref3 = ref2.relations) != null ? ref3[key] : void 0 : void 0) {
          join_table_options.auth = join_table_auth;
        }
        results.push(this.join_tables[join_table_options.route] = new JoinTableController(app, join_table_options));
      }
      return results;
    };

    return JoinTableControllerSingleton;

  })();

  module.exports = new JoinTableControllerSingleton();

}).call(this);
