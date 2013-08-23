// Generated by CoffeeScript 1.6.3
(function() {
  $(document).ready(function() {
    var ctrlDown, ctrlKey, getSlope;
    window.models = {};
    window.views = {};
    window.collections = {};
    window.globals = {
      setPlaceholders: function(draggable, collection) {
        var after, before;
        draggable.before(before = new views.droppablePlaceholder({
          collection: collection
        }).render()).after(after = new views.droppablePlaceholder({
          collection: collection
        }).render());
        if (before.prev().css("display") === "inline-block") {
          return before.css("height", before.prev().height() + "px");
        }
      }
    };
    String.prototype.parseBool = function() {
      if (this.toLowerCase() === "false") {
        return false;
      } else if (this.toLowerCase() === "true") {
        return true;
      }
      return null;
    };
    String.prototype.dirty = function() {
      return this.toLowerCase().replace(/\s+/g, "");
    };
    getSlope = function(y1, y, x1, x) {
      return (y - y1) / (x - x1);
    };
    window.launchModal = function(content) {
      var modal;
      modal = $("<div />").addClass("modal");
      if ($.isArray(content)) {
        _.each(content, function(item) {
          return modal.append(item);
        });
      } else {
        modal.html(content);
      }
      modal.prepend("<i class='close-modal icon-multiply'></i>");
      $(document.body).addClass("active-modal").append(modal);
      return modal;
    };
    window.launchDraggableModal = function(content, tagname, appendTo, title) {
      var modal;
      title = $("<h2/>").html("<i class='icon icon-move'></i>" + title).addClass("drag-handle");
      modal = $("<" + (tagname || "div") + "/>").html($(content).addClass("hidden")).addClass("draggable-modal");
      title.prependTo(modal);
      modal.draggable({
        revert: 'invalid',
        start: function(e, ui) {
          return ui.helper.addClass("moved");
        },
        snap: '.section-builder-wrap:not(:hidden), .sidebar-controls:not(:hidden), .organize-elements:not(:hidden), .draggable-modal:not(:hidden)',
        cancel: '.close-arrow',
        containment: '.container',
        handle: '.drag-handle'
      });
      modal.delegate(".drag-handle", "click", function() {
        cc("click");
        return $(this).siblings(".close-arrow").trigger("click");
      });
      modal.prependTo(appendTo || document.body);
      modal.append($("<div/>").addClass("close-arrow icon-caret-up icon pointer"));
      return modal;
    };
    $.fn.launchModal = function(content) {
      return this.addClass("modal").prependTo($("body").addClass("active-modal"));
    };
    $.fn.showTooltip = function() {
      var el, tooltip_text;
      tooltip_text = this.data("tooltip");
      $(".tooltip").remove();
      el = $("<div/>").addClass("tooltip").text(tooltip_text);
      return this.append(el);
    };
    $.fn.hideTooltip = function() {
      return $(".tooltip").remove();
    };
    window.validNumber = function(num) {
      return !isNaN(parseInt(num));
    };
    window.cc = function(msg, color) {
      return console.log("%c" + msg, "color:" + color + ";font-weight:bold;");
    };
    $(this).delegate(".close-modal", "click", function() {
      $(this).closest(".modal").remove();
      return $("body").removeClass("active-modal");
    });
    $(this).delegate(".modal .confirm", "click", function() {
      $(document.body).removeClass("active-modal");
      return $(this).closest(".modal").remove();
    });
    $(this).delegate("[data-switch-text]", "click", function() {
      var $t, currtext, switchtext;
      $t = $(this);
      switchtext = $t.data("switch-text");
      currtext = $t.text();
      $t.text(switchtext);
      return $t.data("switch-text", currtext);
    });
    $(this).delegate("[data-switch-icon]", "click", function() {
      var $t, curricon, switchicon;
      $t = $(this);
      switchicon = $t.data("switch-icon");
      curricon = $t.attr("class").split(" ");
      _.each(curricon, function(classname) {
        if (classname.indexOf("icon") > -1) {
          curricon = classname;
          return false;
        }
      });
      $t.removeClass(curricon);
      $t.addClass(switchicon);
      return $t.data("switch-icon", curricon);
    });
    $(this).delegate(".close-arrow", "click", function() {
      return $(this).toggleClass("flipped").siblings(":not(.drag-handle)").toggle();
    });
    $(this).delegate("[data-modal] input", "click", function(e) {
      var $t, modal;
      $t = $(this);
      modal = $t.parent().data("modal");
      $(".control-section").eq(currIndex).find(".draggable-modal." + modal).toggle("slide", {
        direction: "left"
      }, 200);
      return e.stopPropagation();
    });
    $(this).delegate("[data-modal]", "click", function(e) {
      var $t, modal;
      $t = $(this);
      modal = $t.data("modal");
      $(".control-section").eq(currIndex).find(".draggable-modal." + modal).toggle("slide", {
        direction: "left"
      }, 200);
      return $t.find("input").prop("checked", !$t.find("input").prop("checked"));
    });
    ctrlDown = false;
    ctrlKey = 17;
    $(this).keydown(function(e) {
      var keyCode;
      keyCode = e.keyCode || e.which;
      if (keyCode === ctrlKey) {
        return ctrlDown = true;
      }
    });
    return $(this).keyup(function(e) {
      var current, keyCode, snaps;
      keyCode = e.keyCode || e.which;
      current = allSections.at(window.currIndex).toJSON().controller;
      if (keyCode === ctrlKey) {
        ctrlDown = false;
      }
      if (ctrlDown === true) {
        if (keyCode === 90) {
          snaps = current.histList;
          snaps.selectLast();
        } else if (keyCode === 83) {
          current.saveSection();
        }
      }
      e.preventDefault();
      e.stopPropagation();
      return false;
    });
  });

  $(window).scroll(function() {});

  window.onbeforeunload = function() {
    var saved;
    saved = true;
    _.each(allSections.models, function(section) {
      return saved = section.saved;
    });
    if (saved === false) {
      return "You have unsaved changes. Are you sure you want to reload/navigate away?";
    } else {
      return null;
    }
  };

}).call(this);
