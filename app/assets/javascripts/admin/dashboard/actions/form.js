(function() {
  "use strict";
  App.AdminDashboardActionsForm = {
    initialize: function() {
      $("input[name='dashboard_action[action_type]']").on({
        change: function() {
          switch ($(this).val()) {
          case "proposed_action":
            $("#request_to_administrators").hide();
            $("#short_description").hide();
            break;
          case "resource":
            $("#request_to_administrators").show();
            $("#short_description").show();
          }
        }
      }).filter("[checked]").trigger("change");
    }
  };
}).call(this);

