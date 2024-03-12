import { Controller } from "stimulus"

const notLargeBreakpoint = '(max-width: 60em)'
const largeBreakpoint = '(min-width: 60em)'

export default class extends Controller {
  static targets = ["nav", "toggle"]

  show(/* event */) {
    this.navTarget.classList.add('active')
    this.toggleTarget.classList.add('open');
  }

  hideLarge(/* event */) {
    if (matchMedia(largeBreakpoint).matches) {
      this.navTarget.classList.remove('active');
      this.toggleTarget.classList.remove('open');
    }
  }

  hideNotLarge(/* event */) {
    if (matchMedia(notLargeBreakpoint).matches) {
      this.navTarget.classList.remove('active');
      this.toggleTarget.classList.remove('open');
    }
  }

  toggle(/* event */) {
    this.navTarget.classList.toggle('active');
    this.toggleTarget.classList.toggle('open');
  }
}
