// import Pikaday from "pikaday"
import rome from "@bevacqua/rome"
import { Controller } from "stimulus"

export default class extends Controller {
  static targets = ["input"]

  connect() {
    this.inputTarget.setAttribute("autocomplete", "off")
    rome(this.inputTarget, {
      inputFormat: "YYYY-MM-DD",
      time: false,
    })
  }
}
