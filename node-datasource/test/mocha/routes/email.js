/*jshint node:true, indent:2, curly:false, eqeqeq:true, immed:true, latedef:true, newcap:true, noarg:true,
regexp:true, undef:true, strict:true, trailing:true, white:true */
/*global XT:true, describe:true, it:true, before:true */

var assert = require("chai").assert,
  zombieAuth = require('../lib/zombie_auth'),
  browser;

(function () {
  "use strict";

  /**
    Test the Report route
  */
  describe('Email report route', function () {
    this.timeout(10 * 1000);

    before(function (done) {
      zombieAuth.loadApp(done);
    });

    describe.skip('Sending out an email', function () {
      it('Should annoy the hell out of whoever is going to get this everytime Jenkins rebuilds', function (done) {
        var emailPayload = {
          from: "no-reply@xtuple.com",
          to: "gene@xtuple.com",
          subject: "test email",
          body: "This email is being generated by node-datasource/test/mocha/routes/email.js"
        },
        options = {
          success: function () {
            // TODO: assert that this succeeded
            done();
          },
          error: function (err) {
            // XXX the assert here stops done() from getting called, which is too bad.
            assert.equal(err.message(), "There should be no error at all");
            done();
          }
        };

        XT.dataSource.sendEmail(emailPayload, options);
      });
    });

  });
}());
