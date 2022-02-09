// We import the CSS which is extracted to its own file by esbuild.
// Remove this line if you add a your own CSS build pipeline (e.g postcss).
import "../css/app.css"

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
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import topbar from "../vendor/topbar"
import gui_channel from "./user_socket"

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, {params: {_csrf_token: csrfToken}})

// Show progress bar on live navigation and form submits
topbar.config({barColors: {0: "#29d"}, shadowColor: "rgba(0, 0, 0, .3)"})
window.addEventListener("phx:page-loading-start", info => topbar.show())
window.addEventListener("phx:page-loading-stop", info => topbar.hide())

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket

function toFixed(value, precision) {
    var power = Math.pow(10, precision || 0);
    return String(Math.round(value * power) / power);
}

class Knob {
  constructor(elem, min_val, max_val) {
    this.min_val = min_val;
    this.max_val = max_val;
    this.elem = elem;
    this.knob_elem = elem.getElementsByClassName('knob-slider')[0];
    this.text_elem = elem.getElementsByClassName('inner')[0];
    var self = this;

    this.elem.addEventListener('mousedown', function(e) {
      self.moving = self.on_click(e);
    });
    this.elem.addEventListener('mousemove', function(e) {
      if (self.moving) {
        self.on_click(e);
      }
    });
    this.elem.addEventListener('mouseup', function(e) {
      self.moving = false;
    });
  }

  on_click(event) {
    var rect = event.target.getBoundingClientRect();
    var x = event.offsetX - rect.x - rect.width/2;
    var y = event.offsetY - rect.y - rect.height/2;
    this.percent = (Math.PI + Math.atan2(x, -y) - 0.9) / 4.62;
    if (this.percent < 0 || this.percent > 1) {
      return false;
    }

    this.value = this.min_val + this.percent * (this.max_val - this.min_val);
    this.draw();
    gui_channel.push("update_module", {
        id: this.elem.dataset.id,
        key: this.elem.dataset.key,
        value: this.value
    });

    return true;
  }

  draw() {
    this.knob_elem.style.background =
        "conic-gradient(red " + (75 * this.percent) + "%, grey 0 75%, white 0)";
    this.text_elem.innerHTML = toFixed(this.value, 1);
  }
}

function api_get(url, params, callback) {
  var xhr = new XMLHttpRequest();
  if (!callback) {
    xhr.onreadystatechange = function () {
      if (this.readyState != 4) {
        return;
      } else if (this.status == 200) {
        var data = JSON.parse(this.responseText);
        callback(this.status, data);
      } else {
        callback(this.status);
      }
    };
  }
  xhr.open("POST", window.location + "api" + url, true);
  xhr.setRequestHeader('Content-Type', 'application/json');
  xhr.send(JSON.stringify(params));
};

window.addEventListener('load', function() {
  var elems = document.getElementsByClassName("knob");
  var knob = new Knob(elems[0], 20, 2000);
});
