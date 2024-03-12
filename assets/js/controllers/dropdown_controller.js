import { Controller } from "stimulus";

export default class extends Controller {
  static targets = ["content", "toggle"];

  toggle(event) {
    event.stopPropagation();
    this.contentTarget.classList.toggle("dn");
    this.toggleTarget.classList.toggle("active");
  }

  closeAll(/* event */) {
    this.contentTarget.classList.add("dn");
  }
}
