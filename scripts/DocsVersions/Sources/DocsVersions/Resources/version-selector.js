/*
 * Auth0.swift documentation version selector.
 *
 * Injected before </head> in every DocC page. DocC renders its navigation bar
 * at runtime (a Vue SPA), so this script waits for the nav to appear and then
 * inserts a version <select> beside the language toggle. Selecting a version
 * navigates to the same documentation path under that version's folder, falling
 * back to the version's landing page when the exact symbol does not exist there.
 *
 * The default stable version is served at the site root (a version-less URL),
 * while every version (including the stable one) is also addressable under its
 * /v<version>/ folder. Root pages have no /v<version>/ segment, so the script
 * treats them as the stable version and routes the stable choice back to root.
 *
 * The script, together with versions.json, lives at the site root and is shared
 * by all versions, so previously published versions pick up newly released ones
 * automatically.
 */
(function () {
  "use strict";

  var VERSION_SEGMENT = /\/v\d+\.\d+\.\d+(?:-[0-9A-Za-z.-]+)?\//;
  var SELECTOR_ID = "docs-version-selector";

  // Derive the site root prefix from the injected script's own src. In
  // production the script is "/Auth0.swift/version-selector.js" → root
  // "/Auth0.swift"; served locally at the domain root it is
  // "/version-selector.js" → root "". Returns null when the script element is
  // not found (callers then fall back to the /v<version>/ segment).
  function siteRootFromScript() {
    var scripts = document.querySelectorAll("script[src]");
    for (var i = 0; i < scripts.length; i++) {
      var src = scripts[i].getAttribute("src") || "";
      var clean = src.split("?")[0].split("#")[0];
      if (/(^|\/)version-selector\.js$/.test(clean)) {
        var path = new URL(clean, window.location.href).pathname;
        return path.replace(/\/version-selector\.js$/, "");
      }
    }
    return null;
  }

  // Resolve the current location into { root, version, rest, atRoot }. On a
  // versioned page the version comes from the /v<version>/ segment; on a
  // root-served page there is no segment, so version is null (resolved to the
  // stable version once versions.json loads) and rest is the path after the root
  // prefix. Returns null when the location cannot be resolved.
  function parseLocation() {
    var scriptRoot = siteRootFromScript();
    var path = window.location.pathname;
    var match = VERSION_SEGMENT.exec(path);
    if (match) {
      var segment = match[0]; // "/vX.Y.Z/"
      var start = match.index;
      return {
        root: scriptRoot != null ? scriptRoot : path.slice(0, start),
        version: segment.slice(1, -1), // "vX.Y.Z"
        rest: path.slice(start + segment.length), // "documentation/auth0/..."
        atRoot: false
      };
    }
    // No version segment: a root-served page. We need the script-derived root to
    // know where the doc path begins.
    if (scriptRoot == null) {
      return null;
    }
    var rest = path.slice(scriptRoot.length);
    if (rest.charAt(0) === "/") {
      rest = rest.slice(1);
    }
    return { root: scriptRoot, version: null, rest: rest, atRoot: true };
  }

  function fetchVersions(root, callback) {
    var url = root + "/versions.json";
    fetch(url, { cache: "no-cache" })
      .then(function (response) {
        return response.ok ? response.json() : null;
      })
      .then(function (data) {
        callback(data && Array.isArray(data.versions) ? data : null);
      })
      .catch(function () {
        callback(null);
      });
  }

  function buildSelect(versions, currentVersion, stablePath) {
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
    if (!known && currentVersion) {
      var option = document.createElement("option");
      option.value = currentVersion;
      option.textContent = currentVersion + " (unlisted)";
      option.selected = true;
      select.insertBefore(option, select.firstChild);
    }

    select.addEventListener("change", function () {
      navigateToVersion(select.value, stablePath, select);
    });

    container.appendChild(select);
    return container;
  }

  // Navigate to the same doc path under the chosen version, HEAD-probing first
  // and falling back to that version's landing page when the path is absent. The
  // location context is recomputed here (not captured at build time) so that
  // switching after client-side navigation resolves the current path. The stable
  // version is served at the root, so selecting it targets the version-less URL.
  function navigateToVersion(targetVersion, stablePath, select) {
    var context = parseLocation();
    if (!context) {
      return;
    }
    var currentVersion = context.atRoot ? stablePath : context.version;
    if (targetVersion === currentVersion) {
      return;
    }
    var base =
      targetVersion === stablePath
        ? context.root + "/"
        : context.root + "/" + targetVersion + "/";
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
  function insert(versions, currentVersion, stablePath) {
    var settings = document.querySelector(".nav-menu-settings");
    if (!settings || document.getElementById(SELECTOR_ID)) {
      return Boolean(document.getElementById(SELECTOR_ID));
    }
    var control = buildSelect(versions, currentVersion, stablePath);
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
      return; // Location could not be resolved; nothing to do.
    }

    fetchVersions(context.root, function (data) {
      if (!data || data.versions.length === 0) {
        return;
      }
      var versions = data.versions;
      // On a root-served page the displayed version is the stable one.
      var stablePath = data.stable || versions[0].path;
      var currentVersion = context.atRoot ? stablePath : context.version;
      injectStyles();

      // The nav is rendered asynchronously and re-rendered on client-side
      // navigation, so keep trying to (re)insert the control whenever the DOM
      // changes. The id guard prevents duplicates.
      insert(versions, currentVersion, stablePath);
      var observer = new MutationObserver(function () {
        insert(versions, currentVersion, stablePath);
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
