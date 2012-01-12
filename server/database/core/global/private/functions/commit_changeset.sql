create or replace function private.commit_changeset(payload text) returns text as $$
  /* Copyright (c) 1999-2011 by OpenMFG LLC, d/b/a xTuple. 
     See www.xm.ple.com/CPAL for the full text of the software license. */

  var changeset = JSON.parse(payload), 
      schemaName = 'xm',
      recordTypes = changeset['sc_types'],
      viewdefSql = "select attname, typname, typcategory "
                 + "from pg_class c, pg_namespace n, pg_attribute a, pg_type t "
                 + "where c.relname = $1 "
                 + " and n.nspname = $2"
                 + " and n.oid = c.relnamespace"
                 + " and a.attnum > 0"
                 + " and a.attrelid = c.oid"
                 + " and a.atttypid = t.oid";

  // ..........................................................
  // METHODS
  //

  /* Process a changeset 

     @param { String } model name
     @param { Object } data
  */
  commitChangeset = function(key, value) {
    var changeType;

    if(value) {
      changeType = value['created'];
      for (var r in changeType) {
        createRecord(key, changeType[r]);
      }

      changeType = value['updated'];
      for (var r in changeType) {
        updateRecord(key, changeType[r]);
      }

      changeType = value['deleted'];
      for (var r in changeType) {
        deleteRecord(key, changeType[r]);
      }
    }
  }

  /* Commit insert to the database 

     @param {string} model name
     @param {object} the record to be committed
  */
  createRecord = function(key, value) {
    var modelName = decamelize(key).replace(schemaName + '.',''), 
        record = decamelize(value),
        sql, columns, expressions, args, 
        props = [], params = [], 
        viewdef = executeSql(viewdefSql, [ modelName, schemaName ]);

    /* build up the content for insert of this record */
    for(prop in record) {
      var coldef = findProperty(viewdef, 'attname', prop);

      if (coldef.typcategory !== 'A') { /* Don't process arrays here */
        props.push(prop);
        if(record[prop]) { 
          if(coldef.typcategory === 'S' ||
             coldef.typcategory === 'D') { /* Strings and dates need to be quoted */
            params.push("'" + record[prop] + "'");
          }
          else {
            params.push(record[prop]);
          }
        }
        else {
          params.push('null');
        }
      }
    }

    columns = props.join(', ');
    expressions = params.join(', ');
    sql = 'insert into ' + schemaName + '.' + modelName + ' (' + columns + ') values (' + expressions + ')';
    
    print(NOTICE, 'sql =', sql);
    
    /* commit the record */
    executeSql(sql); 

    /* okay, now lets handle arrays */
    for(prop in record) {
      var coldef = findProperty(viewdef, 'attname', prop);

      if (coldef['typcategory'] === 'A') {
          var key = coldef['typname'].substring(1); /* strip underscore from (array) type name */
              value = record[prop]; 
                     
          commitChangeset(key, value);
      }
    }
  }

   /* Commit update to the database */
  updateRecord = function(key, value) {
    
  } 

  /* Commit deletion to the database */
  deleteRecord = function(key, value) {
    
  }

  /* Returns an the first item in an array with a property matching the passed value.  

     @param { object } an array to search
     @param { string } property name to search on
     @param { any } a value to match
  */
  findProperty = function(ary, key, value) {
    for(var i = 0; i < ary.length; i++) {
      for(var prop in ary[i]) {
        if(prop === key &&
           ary[i][prop] === value) {
             return ary[i];
        }
      }
    }
    return false;
  }

  /* Pass an argument to change camel case names to snake case.
     A string passed in simply returns a decamelized string.
     If an object is passed, an object is returned with all it's
     proprety names camelized.

     @param { string | object }
  */
  decamelize = function(arg) {
    var ret = arg; 

    decamelizeStr = function(str) {
      return str.replace((/([a-z])([A-Z])/g), '$1_$2').toLowerCase();
    }

    if(typeof arg == "string") {
      ret = decamelizeStr(arg);
    }
    else if(typeof arg == "object") {
      ret = new Object;
      for(var prop in arg) {
        ret[decamelizeStr(prop)] = arg[prop];
      }
    }
    
    return ret;
  }

  // ..........................................................
  // PROCESS
  //

  for(var i in recordTypes) {
    var key = recordTypes[i],
        value = changeset[recordTypes[i]];

    commitChangeset(key, value);
  }

  return '{ "status":"ok" }';
  
$$ language plv8;

select private.commit_changeset('
  {"sc_version":1,
   "XM.Contact":{
     "created":[{
       "guid":12171,
       "number":"14832",
       "honorific":"Mrs.",
       "firstName":"Jane",
       "middleName":"L",
       "lastName":"Knight",
       "suffix":"",
       "isActive":true,
       "jobTitle":"Heiress to a fortune",
       "initials":"JLK","isActive":true,
       "phone":"555-555-5551",
       "alternate":"555-444-4441",
       "fax":"555-333-3331",
       "webAddress":
       "www.xtuple.com",
       "notes":"A distinguished person",
       "owner":null,
       "primaryEmail":
       "jane@gmail.com",
       "address":null,
       "comments":{
         "created":[{
           "guid":739893,
           "contact":12171,
           "date":"2011-12-21 12:47:12.756437-05",
           "username":"admin", 
           "comment_type":"1",
           "text":"booya!",
           "isPublic":false
           },{
           "guid":739894,
           "contact":12171,
           "date":"2011-12-21 12:47:12.756437-05",
           "username":"admin", 
           "comment_type":"1",
           "text":"Now is the time for all good men...",
           "isPublic":false
         }],
         "updated":[],
         "deleted":[]
       },
       "characteristics":[],
       "email":[]
      }],
     "updated":[],
     "deleted":[]
   },
   "sc_types":["XM.Contact"]}
 ');