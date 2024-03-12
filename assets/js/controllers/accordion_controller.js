import { Controller } from "stimulus"

export default class extends Controller {
  static targets = ["content", "toggle", "title", "hide"]

  toggle(event) {
    event.stopPropagation();
    this.contentTarget.classList.toggle('dn');
    this.hideTarget.classList.toggle('dn');
    this.updateToggleText()
    this.updateTitleText()
  }

  updateTitleText() {
    this.titleTarget.classList.toggle('light-gray')
    this.titleTarget.classList.toggle('dark-gray')
    this.titleTarget.classList.toggle('f4')
    this.titleTarget.classList.toggle('fw5')
    this.titleTarget.classList.toggle('nt3')
    this.titleTarget.classList.toggle('lh-copy')
  }

  updateToggleText() {
    let text = this.toggleTarget.textContent;

    if (text == "View Details") {
      this.toggleTarget.textContent = "Hide Details";
    } else {
      this.toggleTarget.textContent = "View Details";
    }
  }
}
