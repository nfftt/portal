// import Pikaday from "pikaday"
import rome from "@bevacqua/rome"
import { Controller } from "stimulus"

export default class extends Controller {
  static targets = ["input"]

  initialize() {
    if (this.element.dataset.validateDay) {
      this.dateValidator = (d) => d.getDay() == this.element.dataset.validateDay
    }
  }

  connect() {
    this.inputTarget.setAttribute("autocomplete", "off")
    debugger;
    rome(this.inputTarget, {
      inputFormat: "YYYY-MM-DD",
      time: false,
      dateValidator: this.dateValidator
    })
  }
}
