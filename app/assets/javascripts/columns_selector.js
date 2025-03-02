(function() {
  "use strict";
  App.ColumnsSelector = {
    initColumns: function() {
      var columns;
      App.ColumnsSelector.hideAll();
      columns =
        App.Cookies.getCookie($("#js-columns-selector").data("cookie")) ||
        $("#js-columns-selector").data("default");
      columns.split(",").forEach(function(column) {
        $("[data-field=" + column + "]").removeClass("hidden");
        $("#column_selector_" + column).prop("checked", true);
      });
    },
    initChecks: function() {
      $(".column-selectable th[data-field]").each(function() {
        var field, input, item, label, text;
        field = $(this).data("field");
        text = $(this).text().trim();
        item = $("#column_selector_item_template").clone();
        item.prop("id", "column_selector_item_" + field);
        input = item.find("input");
        input.prop("name", "column-selector[" + field + "]");
        input.prop("id", "column_selector_" + field);
        input.data("column", field);
        label = item.find("label");
        label.prop("for", "column_selector_" + field);
        label.text(text);
        item.removeClass("hidden");
        $("#js-columns-selector-wrapper").append(item);
      });
    },
    toggleOptions: function(button) {
      button.attr("aria-expanded", !JSON.parse(button.attr("aria-expanded")));
    },
    hideAll: function() {
      $("[data-field]").addClass("hidden");
      $(".column-selector-item input").prop("checked", false);
    },
    toggleColumn: function(event) {
      App.ColumnsSelector.displayColumn($(event.target).data("column"));
    },
    displayColumn: function(column) {
      if ($("#column_selector_" + column).prop("checked")) {
        $("[data-field=" + column + "]").removeClass("hidden");
      } else {
        $("[data-field=" + column + "]").addClass("hidden");
      }
      App.ColumnsSelector.saveCookie();
    },
    saveCookie: function() {
      var shownColumns, value;
      shownColumns = [];
      $(".column-selector-item input").each(function() {
        if ($(this).prop("checked")) {
          shownColumns.push($(this).data("column"));
        }
      });
      value = shownColumns.join(",");
      App.Cookies.saveCookie($("#js-columns-selector").data("cookie"), value, 30);
    },
    initialize: function() {
      App.ColumnsSelector.initChecks();
      App.ColumnsSelector.initColumns();
      $("#js-columns-selector").on({
        click: function() {
          App.ColumnsSelector.toggleOptions($(this));
        }
      });
      $(".column-selector-item input").on({
        click: function(event) {
          App.ColumnsSelector.toggleColumn(event);
        }
      });
    },
    destroy: function() {
      $("#js-columns-selector-wrapper").children(":not(#column_selector_item_template)").remove();
    }
  };
}).call(this);
