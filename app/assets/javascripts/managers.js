(function() {
  "use strict";
  App.Managers = {
    generatePassword: function() {
      var pass, possible_chars, possible_digits, possible_symbols, password_complexity;
      password_complexity = $(".generate-random-value").data("password-complexity");
      possible_chars = "abcdefghijklmnopqrstuvwxyz";
      possible_digits = "123456789";
      possible_symbols = "-_.,;!?";

      pass = Array.apply(null, {
        length: 8
      }).map(function() {
        var i;
        i = Math.floor(Math.random() * possible_chars.length);
        return possible_chars.charAt(i);
      }).join("");

      for (var i = 0; i < password_complexity.upper; i++) {
        pass += possible_chars.charAt(Math.floor(Math.random() * possible_chars.length)).toUpperCase();
      }

      for (var j = 0; j < password_complexity.digit; j++) {
        pass += possible_digits.charAt(Math.floor(Math.random() * possible_digits.length));
      }

      for (var k = 0; k < password_complexity.symbol; k++) {
        pass += possible_symbols.charAt(Math.floor(Math.random() * possible_symbols.length));
      }

      return pass;
    },
    togglePassword: function(type) {
      $("#user_password").prop("type", type);
    },
    initialize: function() {
      $(".generate-random-value").on("click", function(e) {
        e.preventDefault();
        e.stopPropagation();
        $("#user_password").val(App.Managers.generatePassword());
      });
      $(".show-password").on("click", function() {
        if ($("#user_password").is("input[type='password']")) {
          App.Managers.togglePassword("text");
        } else {
          App.Managers.togglePassword("password");
        }
        $(this).attr("aria-pressed", !JSON.parse($(this).attr("aria-pressed")));
      });
    }
  };
}).call(this);
