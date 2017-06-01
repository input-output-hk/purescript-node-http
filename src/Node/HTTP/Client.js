"use strict";

var http = require("http");
var https = require("https");

exports.requestImpl = function (opts) {
    console.log('step1')
  return function (k) {
    console.log('step2')
    return function () {
    console.log('step3')
      var lib = opts.protocol === "https:" ? https : http;
    console.log('step4')
      return lib.request(opts, function (res) {
    console.log('step5')
        k(res)();
    console.log('step6')
      });
    };
  };
};

exports.setTimeout = function (r) {
  return function (ms) {
    return function (k) {
      return function () {
        r.setTimeout(ms, k);
      };
    };
  };
};
