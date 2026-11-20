// Super App — perilaku kecil situs unduhan (tanpa pustaka).
(function () {
  "use strict";

  var REPO = "baymakeprojects/Super_App";
  var API_URL = "https://api.github.com/repos/" + REPO + "/releases/latest";

  // ---------- Menu HP ----------
  var menu = document.getElementById("menu");
  var openButton = document.querySelector("[data-menu-open]");
  var closeButton = document.querySelector("[data-menu-close]");

  function setMenu(open) {
    if (!menu) return;
    menu.hidden = !open;
    document.body.classList.toggle("menu-open", open);
    if (openButton) openButton.setAttribute("aria-expanded", String(open));
    (open ? closeButton : openButton)?.focus();
  }

  if (menu && openButton && closeButton) {
    openButton.addEventListener("click", function () {
      setMenu(true);
    });
    closeButton.addEventListener("click", function () {
      setMenu(false);
    });
    menu.addEventListener("click", function (event) {
      if (event.target.closest("a")) setMenu(false);
    });
    document.addEventListener("keydown", function (event) {
      if (event.key === "Escape" && !menu.hidden) setMenu(false);
    });
  }

  // ---------- Rilis terbaru dari GitHub ----------
  // Tanpa JavaScript atau saat API gagal, tautan tetap ke halaman Releases.
  function applyRelease(release) {
    var version = release.version;
    document.querySelectorAll("[data-version]").forEach(function (el) {
      el.textContent = version;
    });
    if (release.apkName) {
      document.querySelectorAll("[data-apk-name]").forEach(function (el) {
        el.textContent = release.apkName;
      });
    }
    if (release.apkUrl) {
      document.querySelectorAll("[data-apk]").forEach(function (el) {
        el.href = release.apkUrl;
      });
    }
  }

  function loadRelease() {
    if (!window.fetch) return Promise.resolve(null);
    return fetch(API_URL, { headers: { Accept: "application/vnd.github+json" } })
      .then(function (response) {
        if (!response.ok) throw new Error("HTTP " + response.status);
        return response.json();
      })
      .then(function (data) {
        var apk = (data.assets || []).find(function (asset) {
          return /\.apk$/i.test(asset.name);
        });
        var release = {
          version: String(data.tag_name || "").replace(/^v/i, ""),
          apkName: apk ? apk.name : null,
          apkUrl: apk ? apk.browser_download_url : null,
        };
        if (release.version) applyRelease(release);
        return release;
      })
      .catch(function () {
        return null;
      });
  }

  var releaseReady = loadRelease();

  // ---------- Salin link (Unduh Android, desktop) ----------
  document.querySelectorAll("[data-copy-link]").forEach(function (button) {
    var label = button.textContent;
    button.addEventListener("click", function () {
      var url = window.location.href.split("#")[0];
      var done = function () {
        button.textContent = "Link tersalin";
        setTimeout(function () {
          button.textContent = label;
        }, 2000);
      };
      if (navigator.clipboard && navigator.clipboard.writeText) {
        navigator.clipboard.writeText(url).then(done, function () {
          window.prompt("Salin link ini:", url);
        });
      } else {
        window.prompt("Salin link ini:", url);
      }
    });
  });

  // ---------- Unduh otomatis (Unduh Android, HP) ----------
  if (document.body.hasAttribute("data-auto-download")) {
    var isPhoneLayout = window.matchMedia("(max-width: 1023.98px)").matches;
    if (isPhoneLayout) {
      releaseReady.then(function (release) {
        if (release && release.apkUrl) {
          window.location.href = release.apkUrl;
        }
      });
    }
  }
})();
