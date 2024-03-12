import { Controller } from "stimulus"

export default class extends Controller {
  static targets = [
    "deliveryText",
    "deliveryRadioYes",
    "siteText",
    "siteRadioYes",
    "equipmentText",
    "equipmentRadioYes",
    "otherText"
  ]

  connect() {
    let showSite = this.siteRadioYesTarget.checked;
    let showDelivery = !this.deliveryRadioYesTarget.checked;
    let showEquipment = this.equipmentRadioYesTarget.checked;

    this.updateSite(showSite);
    this.updateDelivery(showDelivery);
    this.updateEquipment(showEquipment);
  }

  handleDelivery(event) {
    let show = event.target.value == "false";
    this.updateDelivery(show)
  }

  updateDelivery(show) {
    if (show) {
      this.deliveryTextTarget.classList.remove("dn")
    } else {
      this.deliveryTextTarget.classList.add("dn")
    }
  }

  handleSite(event) {
    let show = event.target.value == "true";
    this.updateSite(show)
  }

  updateSite(show) {
    if (show) {
      this.siteTextTarget.classList.remove("dn")
    } else {
      this.siteTextTarget.classList.add("dn")
    }
  }

  handleEquipment(event) {
    let show = event.target.value == "true";
    this.updateEquipment(show)
  }

  updateEquipment(show) {
    if (show) {
      this.equipmentTextTarget.classList.remove("dn")
    } else {
      this.equipmentTextTarget.classList.add("dn")
    }
  }
}
