'use strict'

var config = {
showDebugMsgs : false,
cloudCorsProxyUrl: "https://exosphere.jetstream-cloud.org/proxy",
cloudsWithUserAppProxy:
[ ["iu.jetstream-cloud.org", "proxy-j7m-iu.exosphere.app"],
  ["tacc.jetstream-cloud.org", "proxy-j7m-tacc.exosphere.app"],
],
urlPathPrefix: "exosphere",
palette: { primary: {r: 155, g: 33, b: 35}, secondary: {r: 52, g: 122, b: 140} },
logo: "assets/img/jetstream-logo.svg",
favicon: "assets/img/jetstream-favicon.ico",
appTitle: "Jetstream Cloud",
defaultLoginView: "jetstream",
aboutAppMarkdown: "This is the Exosphere interface for [Jetstream Cloud](https://jetstream-cloud.org), currently in beta. If you require assistance, please email help@jetstream-cloud.org and specify you are using Exosphere.\\\n\\\nUse of this site is subject to the Exosphere hosted sites [Privacy Policy](https://gitlab.com/exosphere/exosphere/-/blob/master/docs/privacy-policy.md) and [Acceptable Use Policy](https://gitlab.com/exosphere/exosphere/-/blob/master/docs/acceptable-use-policy.md).",
supportInfoMarkdown: "Please read about [using instances](https://iujetstream.atlassian.net/wiki/display/JWT/Jetstream+Public+Wiki) or [troubleshooting instances](https://wiki.jetstream-cloud.org/Troubleshooting+and+FAQ) for answers to common problems before submitting a request to support staff.",
userSupportEmail: "help@jetstream-cloud.org"
}

/* Matomo tracking code */
var _paq = window._paq = window._paq || [];
/* tracker methods like "setCustomDimension" should be called before "trackPageView" */
_paq.push(['trackPageView']);
_paq.push(['enableLinkTracking']);
(function() {
  var u="//matomo.exosphere.app/";
  _paq.push(['setTrackerUrl', u+'matomo.php']);
  _paq.push(['setSiteId', '3']);
  var d=document, g=d.createElement('script'), s=d.getElementsByTagName('script')[0];
  g.type='text/javascript'; g.async=true; g.src=u+'matomo.js'; s.parentNode.insertBefore(g,s);
})();
