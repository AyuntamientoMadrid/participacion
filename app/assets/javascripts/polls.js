(function() {
  "use strict";
  App.Polls = {
    updateMultipleChoiceStatus: function(fieldset, try_to_check, click_target) {
      var max_votes = $(fieldset).attr('data-max_votes');
      var checked_boxes_count = $(fieldset).find("input[type='checkbox']:checked").length;
      var unchecked_boxes = $(fieldset).find("input[type='checkbox']:not(:checked)");

      if(try_to_check && checked_boxes_count >= max_votes) {
        // disable currently unchecked boxes if no more votes available
        $(unchecked_boxes).prop( "disabled", true );
        if(click_target && checked_boxes_count > max_votes){
          // disable self + prevent click (edge case, shouldn't occur)
          event.preventDefault();
          $(click_target).prop( "disabled", true );
        }
      }else{
        $(fieldset).find("input[type='checkbox']").prop( "disabled", false );
      }
    },
    initialize: function() {
      $("fieldset.multiple-choice").each(function() {
        App.Polls.updateMultipleChoiceStatus(this, true, null);
      });
      $(".zoom-link").on("click", function(event) {
        var option;
        option = $(event.target).closest("div.option");

        if ($(option).hasClass("medium-6")) {
          $(option).removeClass("medium-6");
          $(option).addClass("option-divider");
          if (!$(option).hasClass("first")) {
            $(option).insertBefore($(option).prev("div.option"));
          }
        } else {
          $(option).addClass("medium-6");
          $(option).removeClass("option-divider");
          if (!$(option).hasClass("first")) {
            $(option).insertAfter($(option).next("div.option"));
          }
        }
      });
      $("fieldset.multiple-choice input[type='checkbox']").on("click", function(event) {
          var self = event.target;
          // :checked status reflects what the click would do if we wouldn't use event.preventDefault()
          var try_to_check = $(self).is(':checked');
          var fieldset = $(self).closest('fieldset');

          App.Polls.updateMultipleChoiceStatus(fieldset, try_to_check, self);
      });
    }
  };
}).call(this);