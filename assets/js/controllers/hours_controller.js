import { Controller } from "stimulus"

export default class extends Controller {
  static targets = ["start", "end"]

  toggle(/* event */) {
    this.startTarget.toggleAttribute('disabled');
    this.endTarget.toggleAttribute('disabled');
  }
}
