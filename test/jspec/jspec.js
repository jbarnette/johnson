console = {
  indentation: 0,
  indent: function() {
    for(i=0;i<this.indentation - 1;i++) Ruby.print("  ");
    if(this.indentation > 0) Ruby.print("- ");
  },
  group: function(msg) {
    this.info(msg);
    this.indentation += 1;
  },
  info: function(msg) {
    this.indent();
    Ruby.puts(msg);
  },
  error: function(msg) {
    this.info("F " + msg);
  },
  warn: function(msg) {
    this.info("W " + msg);
  },
  groupEnd: function() {
    this.indentation -= 1;
  }
};

jspec = {
  fn_contents: function(fn) {
    return fn.toString().match(/^[^\{]*{((.*\n*)*)}/m)[1];
  },
  TOP_LEVEL: 0, DESCRIBE: 1, IT_SHOULD_PASS: 2, IT_SHOULD_FAIL: 3, 
  FAILURE: 4, DONE_EXAMPLE: 5, DONE_GROUP: 6, PENDING: 7,
  logger: function(state, message) {
    switch(state) {
      case jspec.TOP_LEVEL:
        console.group(message);
        break;
      case jspec.DESCRIBE:
        console.group(message);
        break;
      case jspec.IT_SHOULD_PASS:
        console.info(message);
        break;
      case jspec.IT_SHOULD_FAIL:
        console.group(message);
        break;
      case jspec.FAILURE:
        console.error(message);
        console.groupEnd();
        break;
      case jspec.DONE_EXAMPLE:
        console.groupEnd();
        break;
      case jspec.DONE_GROUP:
        console.groupEnd();
        break;
      case jspec.PENDING:
        console.warn("Pending: " + message);
        break;
    }
    
  },
  describe: function(str, desc) {
    jspec.logger(jspec.TOP_LEVEL, str);
    var it = function(str, fn) {
      if(fn) {
        jspec.logger(jspec.DESCRIBE, str);
        fn();
        jspec.logger(jspec.DONE_EXAMPLE);
      } else {
        jspec.logger(jspec.PENDING, str);
      };
    };
    var Expectation = function(p) { this.expectation = p; };
    Expectation.prototype.to = function(fn_str, to_compare, not) {
      try {
        var pass = jspec.matchers[fn_str].matches(this.expectation, to_compare);
        if(not) var pass = !pass;
      } catch(e) {
        var pass = null;
      }
      var should_string = (jspec.matchers[fn_str].describe && 
        jspec.matchers[fn_str].describe(this.expectation, to_compare, not)) || 
        this.toString() + " should " + (not ? "not " : "") + fn_str + " " + to_compare;
      if(pass) {
        jspec.logger(jspec.IT_SHOULD_PASS, should_string + " (PASS)");
      } else {
        jspec.logger(jspec.IT_SHOULD_FAIL, should_string + (pass == false ? " (FAIL)" : " (ERROR)"));
        jspec.logger(jspec.FAILURE, jspec.matchers[fn_str].failure_message(this.expectation, to_compare, not))
      }
    }
    Expectation.prototype.not_to = function(fn_str, to_compare) { this.to(fn_str, to_compare, true) }
    var expect = function(p) { return new Expectation(p) };
    x = desc.toString()
    var fn_body = this.fn_contents(desc);
    var fn = new Function("it", "expect", fn_body);
    fn.call(this, it, expect);
    jspec.logger(jspec.DONE_GROUP);
  }
}

// Helper for 

jspec.print_object = function(obj) {
  if(obj instanceof Function) {
    return obj.toString().match(/^([^\{]*) {/)[1];
  } else if(obj instanceof Array) {
    return "[" + obj.toString() + "]";
  } else if(typeof HTMLElement != "undefined" && obj instanceof HTMLElement) {
     return "<" + obj.tagName + (obj.className != "" ? " class='" + obj.className + "'" : "") + 
       (obj.id != "" ? " id='" + obj.id + "'" : "") + ">";
  } else if(typeof DOMDocument != "undefined" && obj instanceof DOMDocument) {
    return "The document element";
  } else {
    return obj.toString().replace(/\n\s*/g, "");
  }
}

// Matchers begin here

jspec.matchers = {};

jspec.matchers["=="] = {
  describe: function(self, target, not) {
    return jspec.print_object(self) + " should " + (not ? "not " : "") + "equal " + jspec.print_object(target)
  },
  matches: function(self, target) {
    return self == target;
  },
  failure_message: function(self, target, not) {
    if (not)
      return "Expected " + jspec.print_object(self) + " not to equal " + jspec.print_object(target);
    else
      return "Expected " + jspec.print_object(self) + ". Got " + jspec.print_object(target);
  }
}

jspec.matchers["include"] = {
  matches: function(self, target) {
    if(Array.prototype.indexOf) return Array.prototype.indexOf.call(self, target) != -1;
    else {
      for(i=0,j=self.length;i<j;i++) {
        if(target == self[i]) return true;
      }
      return false;
    }
  },
  failure_message: function(self, target, not) {
    return "Expected [" + jspec.print_object(self) + "] " + (not ? "not " : "") + "to include " + target;
  }  
}

jspec.matchers["exist"] = {
  describe: function(self, target, not) {
    return jspec.print_object(self) + " should " + (not ? "not " : "")  + "exist."
  },
  matches: function(self, target) {
    return !!this;
  },
  failure_message: function(self, target, not) {
    return "Expected " + (not ? "not " : "") + "to exist, but was " + jspec.print_object(self);
  }
}

jspec.matchers["be_instanceof"] = {
  describe: function(self, target, not) {
    return jspec.print_object(self) + " should " + (not ? "not " : "") + 
      "be an instance of " + jspec.print_object(target);
  },
  matches: function(self, target) {
    return self instanceof target;
  },
  failure_message: function(self, target, not) {
    return "Expected " + jspec.print_object(self) + (not ? "not " : "") + 
      "to be an instance of " + jspec.print_object(target) + ", but was " + 
      jspec.print_object(target.constructor);
  }
}

jspec.matchers["have_constructor"] = {
  describe: function(self, target, not) {
    return jspec.print_object(self) + " should " + (not ? "not " : "") + 
      "have " + jspec.print_object(target) + " as its constructor";
  },
  matches: function(self, target) {
    return self instanceof target;
  },
  failure_message: function(self, target, not) {
    return "Expected " + jspec.print_object(self) + (not ? "not " : "") + 
      "to have " + jspec.print_object(target) + ", as its constructor but was " + 
      jspec.print_object(target.constructor);
  }
}