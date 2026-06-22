/*
 * Auth0.swift documentation version selector.
 *
 * Injected before </head> in every DocC page. DocC renders its navigation bar
 * at runtime (a Vue SPA), so this script waits for the nav to appear and then
 * inserts a version <select> beside the language toggle. Selecting a version
 * navigates to the same documentation path under that version's folder, falling
 * back to the version's landing page when the exact symbol does not exist there.
 *
 * The script, together with versions.json, lives at the site root and is shared
 * by all versions, so previously published versions pick up newly released ones
 * automatically.
 */
(function () {
  "use strict";

  var VERSION_SEGMENT = /\/v\d+\.\d+\.\d+(?:-[0-9A-Za-z.-]+)?\//;
  var SELECTOR_ID = "docs-version-selector";

  // Split the current path into { root, version, rest } around the /vX.Y.Z/
  // segment. Returns null when the page is not under a version folder (e.g. the
  // root redirect page).
  function parseLocation() {
    var path = window.location.pathname;
    var match = VERSION_SEGMENT.exec(path);
    if (!match) {
      return null;
    }
    var segment = match[0]; // "/vX.Y.Z/"
    var start = match.index;
    return {
      root: path.slice(0, start), // "" when served at the domain root
      version: segment.slice(1, -1), // "vX.Y.Z"
      rest: path.slice(start + segment.length) // "documentation/auth0/..."
    };
  }

  function fetchVersions(root, callback) {
    var url = root + "/versions.json";
    fetch(url, { cache: "no-cache" })
      .then(function (response) {
        return response.ok ? response.json() : null;
      })
      .then(function (data) {
        callback(data && Array.isArray(data.versions) ? data.versions : null);
      })
      .catch(function () {
        callback(null);
      });
  }

  function buildSelect(versions, currentVersion) {
    var container = document.createElement("div");
    container.className = "nav-menu-setting version-container";

    var select = document.createElement("select");
    select.id = SELECTOR_ID;
    select.className = "version-dropdown";
    select.setAttribute("aria-label", "Documentation version");

    var known = false;
    versions.forEach(function (entry) {
      var option = document.createElement("option");
      option.value = entry.path; // "vX.Y.Z"
      option.textContent = entry.name || entry.path;
      if (entry.path === currentVersion) {
        option.selected = true;
        known = true;
      }
      select.appendChild(option);
    });

    // The current version may have been pruned from the list; show it anyway so
    // the control reflects reality.
    if (!known) {
      var option = document.createElement("option");
      option.value = currentVersion;
      option.textContent = currentVersion + " (unlisted)";
      option.selected = true;
      select.insertBefore(option, select.firstChild);
    }

    select.addEventListener("change", function () {
      navigateToVersion(select.value, select);
    });

    container.appendChild(select);
    return container;
  }

  // Navigate to the same doc path under the chosen version, HEAD-probing first
  // and falling back to that version's landing page when the path is absent.
  // The location context is recomputed here (not captured at build time) so
  // that switching after client-side navigation resolves the current path.
  function navigateToVersion(targetVersion, select) {
    var context = parseLocation();
    if (!context || targetVersion === context.version) {
      return;
    }
    var base = context.root + "/" + targetVersion + "/";
    var target = base + context.rest;
    var landing = base + "documentation/auth0/";

    select.disabled = true;
    fetch(target, { method: "HEAD" })
      .then(function (response) {
        window.location.href = response.ok
          ? target + window.location.hash
          : landing;
      })
      .catch(function () {
        window.location.href = landing;
      });
  }

  function injectStyles() {
    if (document.getElementById(SELECTOR_ID + "-style")) {
      return;
    }
    var style = document.createElement("style");
    style.id = SELECTOR_ID + "-style";
    style.textContent =
      ".version-container{display:flex;align-items:center;margin-right:10px}" +
      ".version-dropdown{font:inherit;color:var(--color-nav-link-color,inherit);" +
      "background:transparent;border:1px solid var(--color-grid,rgba(0,0,0,0.2));" +
      "border-radius:4px;padding:2px 6px;cursor:pointer;max-width:160px}" +
      ".version-dropdown:disabled{opacity:0.5;cursor:progress}";
    document.head.appendChild(style);
  }

  // Insert the control into the nav settings area, beside the language toggle.
  function insert(versions, context) {
    var settings = document.querySelector(".nav-menu-settings");
    if (!settings || document.getElementById(SELECTOR_ID)) {
      return Boolean(document.getElementById(SELECTOR_ID));
    }
    var control = buildSelect(versions, context.version);
    var languageToggle = settings.querySelector(".language-container");
    if (languageToggle) {
      settings.insertBefore(control, languageToggle);
    } else {
      settings.insertBefore(control, settings.firstChild);
    }
    return true;
  }

  function start() {
    var context = parseLocation();
    if (!context) {
      return; // Not a versioned page; nothing to do.
    }

    fetchVersions(context.root, function (versions) {
      if (!versions || versions.length === 0) {
        return;
      }
      injectStyles();

      // The nav is rendered asynchronously and re-rendered on client-side
      // navigation, so keep trying to (re)insert the control whenever the DOM
      // changes. The id guard prevents duplicates.
      if (insert(versions, context)) {
        // Inserted immediately; still observe in case the SPA re-renders the nav.
      }
      var observer = new MutationObserver(function () {
        insert(versions, context);
      });
      observer.observe(document.body, { childList: true, subtree: true });
    });
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", start);
  } else {
    start();
  }
})();
