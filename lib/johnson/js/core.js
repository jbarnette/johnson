
// Ruby ProxyHelper => JS original
Johnson.addConversion(function(v) {
  return v.javascript_proxy;
}, (function(Helper_send) {
  return function(v) {
    return Helper_send('===', v);
  };
})(Ruby.Johnson.RubyLandProxy.ProxyHelper.method('send')));


// Ruby Time => JS Date
Johnson.addWrapper(function(v) {
  var d = new Date(v.to_f() * 1000);
  d.wrappedRuby = v;
  return d;
}, (function(Helper_send, RubyTime_send) {
  return function(v) {
    return !Helper_send('===', v) && RubyTime_send('===', v);
  };
})(Ruby.Johnson.RubyLandProxy.ProxyHelper.method('send'), Ruby.Time.method('send')));


// Ruby Date/DateTime => JS Date
Johnson.addWrapper(function(v) {
  var d = new Date(parseFloat(v.strftime('%Q')));
  d.wrappedRuby = v;
  return d;
}, (function(Helper_send, RubyDate_send) {
  return function(v) {
    return !Helper_send('===', v) && RubyDate_send('===', v);
  };
})(Ruby.Johnson.RubyLandProxy.ProxyHelper.method('send'), Ruby.Date.method('send')));

