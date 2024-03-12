import { Controller } from "stimulus"

export default class extends Controller {
  static targets = ["name", "empty", "selected"]

  show(event) {
    let input = event.target;

    if (input.value) {
      let name = input.files[0].name;

      this.nameTarget.innerHTML = `Selected: ${name}`;

      this.emptyTarget.classList.add('dn');
      this.selectedTarget.classList.remove('dn');
    }
  }
}
