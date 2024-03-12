import { Controller } from "stimulus";

export default class extends Controller {
  static targets = ["errorText", "info", "button", "buttonWrapper"];

  connect() {
    this.setup();
  }

  showError(error) {
    this.errorTextTarget.classList.remove("dn");
    this.buttonTarget.remove();
    console.error(error);
  }

  pay(event) {
    event.preventDefault();
    this.checkout();
  }

  showButton() {
    this.buttonWrapperTarget.classList.remove("dn");
  }

  checkout() {
    try {
      this.stripe
        .redirectToCheckout({
          sessionId: this.info.sessionID,
        })
        .then((result) => {
          this.showError(result.error);
        });
    } catch (error) {
      this.showError(error);
    }
  }

  setup() {
    let data = this.infoTarget.dataset;

    this.info = {
      active: data.active == "Yes",
      role: data.role,
      pubKey: data.pubkey,
      sessionID: data.session,
      auto: data.auto == "Yes",
      hasValidProperty: data.validprop == "Yes",
    };

    this.stripe = Stripe(this.info.pubKey);

    if (this.shouldPay()) {
      this.showButton();

      if (this.info.auto) {
        this.checkout();
      }
    }
  }

  shouldPay() {
    if (!this.info.active) {
      switch (this.info.role) {
        case "tree_owner":
          return this.info.hasValidProperty;
        case "picker":
          return true;
        default:
          return false;
      }
    } else {
      return false;
    }
  }
}
