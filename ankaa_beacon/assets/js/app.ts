// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html";
// Establish Phoenix Socket and LiveView configuration.
import { Socket } from "phoenix";
import { LiveSocket } from "phoenix_live_view";
import topbar from "../vendor/topbar";

const csrfToken = (
  document.querySelector("meta[name='csrf-token']") as HTMLElement
).getAttribute("content");

// Register our hooks
const hooks = {};

// Custom loading animation setup
topbar.config({
  barColors: { 0: "#4f46e5" }, // Indigo color from Tailwind
  shadowColor: "rgba(0, 0, 0, .2)",
});

const liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  hooks: hooks,
  params: { _csrf_token: csrfToken },
  // dom: {
  //   // Optional: Add custom DOM handling if needed
  //   onBeforeElUpdated(from, to) {
  //     // Keep any custom data attributes when elements are updated
  //     if (from._x_dataStack) {
  //       window.Alpine.clone(from, to);
  //     }
  //     return true;
  //   },
  // },
});

window.addEventListener("phx:page-loading-start", (_info) => topbar.show(300));
window.addEventListener("phx:page-loading-stop", (_info) => topbar.hide());

// Connect if there are any LiveViews on the page
liveSocket.connect();

// Add modal close functionality for any modals in the app
document.addEventListener("click", (e) => {
  const target = e.target as HTMLElement;
  if (target.getAttribute("data-close-modal")) {
    const modalId = target.getAttribute("data-close-modal");
    const modal = document.getElementById(modalId as string);
    if (modal) {
      modal.classList.add("hidden");
    }
  }
});

// Expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket;
