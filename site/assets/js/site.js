// Catalog filtering: kind chips + module select + free-text search.
(function () {
  "use strict";

  var chips = Array.prototype.slice.call(document.querySelectorAll("[data-kind-filter]"));
  var moduleSelect = document.querySelector("[data-module-filter]");
  var search = document.querySelector("[data-card-search]");
  var cards = Array.prototype.slice.call(document.querySelectorAll("[data-card]"));
  var empty = document.querySelector("[data-empty-state]");

  var state = { kind: "all", module: "all", query: "" };

  function apply() {
    var visible = 0;
    var q = state.query.trim().toLowerCase();
    cards.forEach(function (card) {
      var ok =
        (state.kind === "all" || card.dataset.kind === state.kind) &&
        (state.module === "all" || card.dataset.module === state.module) &&
        (!q || card.dataset.search.toLowerCase().indexOf(q) !== -1);
      card.hidden = !ok;
      if (ok) visible += 1;
    });
    if (empty) {
      if (visible === 0) empty.setAttribute("data-visible", "");
      else empty.removeAttribute("data-visible");
    }
  }

  chips.forEach(function (chip) {
    chip.addEventListener("click", function () {
      chips.forEach(function (c) { c.setAttribute("aria-pressed", String(c === chip)); });
      state.kind = chip.getAttribute("data-kind-filter");
      apply();
    });
  });

  if (moduleSelect) {
    moduleSelect.addEventListener("change", function () {
      state.module = moduleSelect.value;
      apply();
    });
  }

  if (search) {
    search.addEventListener("input", function () {
      state.query = search.value;
      apply();
    });
  }
})();
