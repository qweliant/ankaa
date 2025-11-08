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
import { LiveSocket, Hook } from "phoenix_live_view";
import topbar from "../vendor/topbar";

const AlertsHook: Partial<Hook> = {
  mounted() {
    const DISMISSED_ALERTS_KEY = "dismissed_info_alerts";

    // 1. On page load, read session storage and push to the server.
    const dismissedIds: string[] = JSON.parse(
      sessionStorage.getItem(DISMISSED_ALERTS_KEY) || "[]"
    );
    if (dismissedIds.length > 0) {
      this.pushEvent("load_dismissed_alerts", { ids: dismissedIds });
    }

    // 2. Listen for an event from the server to save a new dismissal.
    this.handleEvent("dismiss_info_alert", ({ id }: { id: string }) => {
      console.log(`Persisting dismissal of INFO alert ${id} to session storage.`);
      const currentDismissed: string[] = JSON.parse(
        sessionStorage.getItem(DISMISSED_ALERTS_KEY) || "[]"
      );
      if (!currentDismissed.includes(id)) {
        const newDismissed = [...currentDismissed, id];
        sessionStorage.setItem(DISMISSED_ALERTS_KEY, JSON.stringify(newDismissed));
      }
    });
  },
};

const SessionTimer: Partial<Hook> = {
  mounted() {
    const startTime = new Date(this.el.dataset.startTime!).getTime();

    const updateTimer = () => {
      const now = Date.now();
      const elapsed = Math.max(0, now - startTime);

      const hours = String(Math.floor(elapsed / 3600000)).padStart(2, "0");
      const minutes = String(Math.floor((elapsed % 3600000) / 60000)).padStart(2, "0");
      const seconds = String(Math.floor((elapsed % 60000) / 1000)).padStart(2, "0");

      this.el.innerText = `${hours}:${minutes}:${seconds}`;
    };
    
    // Use `as any` to attach our custom property. This tells TypeScript
    // to trust us that we're adding this property at runtime.
    (this as any).timerInterval = window.setInterval(updateTimer, 1000);
    updateTimer();
  },

  destroyed() {
    // Use `as any` again to access the property and clear the interval.
    clearInterval((this as any).timerInterval);
  },
};

const DisclaimerBannerHook: Partial<Hook> = {
  mounted() {
    const banner = this.el as HTMLElement;
    const dismissButton = document.getElementById("dismiss-disclaimer-btn");
    const storageKey = "hide_disclaimer_banner";

    if (sessionStorage.getItem(storageKey) === "true") {
      banner.style.display = "none";
    }

    dismissButton?.addEventListener("click", () => {
      banner.style.display = "none";
      sessionStorage.setItem(storageKey, "true");
    });
  },
};

const csrfToken = (
  document.querySelector("meta[name='csrf-token']") as HTMLElement
).getAttribute("content");

// Register our hooks
const hooks: { [key: string]: Partial<Hook> } = {
  AlertsHook: AlertsHook,
  SessionTimer: SessionTimer,
  DisclaimerBanner: DisclaimerBannerHook,
};

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
