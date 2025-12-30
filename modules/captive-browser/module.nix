{
  config,
  lib,
  ...
}:

let
  this = config.custom.captive-browser;
  firefox = lib.getExe config.programs.firefox.package;
in

{
  options.custom.captive-browser = {
    enable = lib.mkEnableOption "captive browser using firefox";
  };
  config = lib.mkIf this.enable {
    programs.captive-browser = {
      enable = true;
      # Stolen from https://github.com/FiloSottile/captive-browser/issues/20#issuecomment-1496700943
      # Slightly adapted for NixOS
      # No license was provided, so this is proprietary/all rights reserved :/
      # FIXME this could be done nicer using NixOS options to configure most of the stuff
      # TODO upstream this
      browser = ''
        ${firefox} --CreateProfile "captive-browser" \
        && printf "user_pref%s;\\n" \
          "(\\"network.proxy.type\\", 1)" \
          "(\\"network.proxy.socks_remote_dns\\", true)" \
          "(\\"network.proxy.socks_version\\", 5)" \
          "(\\"network.proxy.socks\\", \\"''${PROXY%:*}\\")" \
          "(\\"network.proxy.socks_port\\", ''${PROXY##*:})" \
          "(\\"network.proxy.no_proxies_on\\", \\"localhost, 127.0.0.1, [::1]\\")" \
          "(\\"dom.security.https_only_mode\\", false)" \
          "(\\"network.trr.mode\\", 5)" \
          "(\\"toolkit.legacyUserProfileCustomizations.stylesheets\\", true)" \
          "(\\"browser.cache.disk.enable\\", false)" \
          "(\\"browser.cache.disk_cache_ssl\\", false)" \
          "(\\"browser.cache.offline.enable\\", false)" \
          "(\\"pdfjs.disabled\\", true)" \
          "(\\"extensions.pocket.enabled\\", false)" \
          "(\\"extensions.pocket.onSaveRecs\\", false)" \
          "(\\"browser.topsites.contile.enabled\\", false)" \
          "(\\"browser.newtabpage.enabled\\", false)" \
          "(\\"browser.newtabpage.activity-stream.section.highlights.includePocket\\", false)" \
          "(\\"browser.newtabpage.activity-stream.discoverystream.enabled\\", false)" \
          "(\\"browser.newtabpage.activity-stream.feeds.snippets\\", false)" \
          "(\\"browser.newtabpage.activity-stream.feeds.system.topstories\\", false)" \
          "(\\"browser.newtabpage.activity-stream.feeds.system.topsites\\", false)" \
          "(\\"browser.newtabpage.activity-stream.feeds.systemtick\\", false)" \
          "(\\"browser.newtabpage.activity-stream.showSponsored\\", false)" \
          "(\\"browser.newtabpage.activity-stream.showSponsoredTopSites\\", false)" \
          "(\\"browser.aboutHomeSnippets.updateUrl\\", \\"\\")" \
          "(\\"browser.messaging-system.whatsNewPanel.enabled\\", false)" \
          "(\\"browser.startup.homepage_override.mstone\\", \\"ignore\\")" \
          "(\\"browser.ping-centre.telemetry\\", false)" \
          "(\\"browser.region.update.enabled\\", false)" \
          "(\\"browser.search.update\\", false)" \
          "(\\"browser.search.geoip.url\\", \\"\\")" \
          "(\\"geo.enabled\\", false)" \
          "(\\"geo.provider.network.url\\", \\"\\")" \
          "(\\"browser.region.network.url\\", \\"\\")" \
          "(\\"geo.provider.use_geoclue\\", false)" \
          "(\\"browser.uitour.enabled\\", false)" \
          "(\\"browser.vpn_promo.enabled\\", false)" \
          "(\\"datareporting.healthreport.uploadEnabled\\", false)" \
          "(\\"datareporting.policy.dataSubmissionEnabled\\", false)" \
          "(\\"media.gmp-gmpopenh264.enabled\\", false)" \
          "(\\"media.gmp-manager.url\\", \\"\\")" \
          "(\\"extensions.getAddons.cache.enabled\\", false)" \
          "(\\"extensions.blocklist.enabled\\", false)" \
          "(\\"extensions.systemAddon.update.enabled\\", false)" \
          "(\\"extensions.systemAddon.update.url\\", \\"\\")" \
          "(\\"app.update.auto\\", false)" \
          "(\\"privacy.trackingprotection.enabled\\", false)" \
          "(\\"privacy.trackingprotection.pbmode.enabled\\", false)" \
          "(\\"privacy.trackingprotection.cryptomining.enabled\\", false)" \
          "(\\"privacy.trackingprotection.emailtracking.enabled\\", false)" \
          "(\\"privacy.trackingprotection.fingerprinting.enabled\\", false)" \
          "(\\"privacy.trackingprotection.origin_telemetry.enabled\\", false)" \
          "(\\"privacy.trackingprotection.socialtracking.enabled\\", false)" \
          "(\\"services.settings.server\\", \\"\\")" \
          "(\\"app.normandy.enabled\\", false)" \
          "(\\"app.shield.optoutstudies.enabled\\", false)" \
          "(\\"messaging-system.rsexperimentloader.enabled\\", false)" \
          "(\\"toolkit.coverage.opt-out\\", true)" \
          "(\\"toolkit.telemetry.coverage.opt-out\\", true)" \
          "(\\"beacon.enabled\\", false)" \
          "(\\"security.OCSP.enabled\\", 0)" \
          "(\\"extensions.systemAddon.update.enabled\\", false)" \
          "(\\"extensions.blocklist.enabled\\", false)" \
          "(\\"browser.discovery.enabled\\", false)" \
          "(\\"network.captive-portal-service.enabled\\", false)" \
          "(\\"network.connectivity-service.enabled\\", false)" \
          "(\\"browser.safebrowsing.provider.mozilla.gethashURL\\", \\"\\")" \
          "(\\"browser.safebrowsing.provider.mozilla.updateURL\\", \\"\\")" \
          "(\\"browser.safebrowsing.malware.enabled\\", false)" \
          "(\\"browser.safebrowsing.phishing.enabled\\", false)" \
          "(\\"browser.safebrowsing.downloads.enabled\\", false)" \
          "(\\"browser.safebrowsing.downloads.remote.enabled\\", false)" \
          "(\\"browser.safebrowsing.downloads.remote.block_potentially_unwanted\\", false)" \
          "(\\"browser.safebrowsing.downloads.remote.block_uncommon\\", false)" \
          "(\\"browser.safebrowsing.blockedURIs.enabled\\", false)" \
          "(\\"browser.safebrowsing.passwords.enabled\\", false)" \
          "(\\"network.prefetch-next\\", false)" \
          "(\\"network.dns.disablePrefetch\\", true)" \
          "(\\"network.http.speculative-parallel-limit\\", 0)" \
          "(\\"network.predictor.enabled\\", false)" \
          "(\\"dom.push.enabled\\", false)" \
        >> "$(printf "%s\\n" "$HOME"/.mozilla/firefox/*.captive-browser/)"prefs.js \
        && export MOZ_REMOTE_SETTINGS_DEVTOOLS=1 \
        && mkdir -p "$(printf "%s\\n" "$HOME"/.mozilla/firefox/*.captive-browser/)"chrome \
        && printf "%s\\n" "#TabsToolbar { display: none; }" \
        > "$(printf "%s\\n" "$HOME"/.mozilla/firefox/*.captive-browser/)"chrome/userChrome.css \
        && exec ${firefox} -P "captive-browser" --no-remote --private-window "http://detectportal.firefox.com/canonical.html" \
      '';
    };
  };
}
