import { Controller } from "stimulus";

export default class extends Controller {
  static targets = ["startTime", "endTime"];

  connect() {
    let time = this.startTimeTarget.value;
    let target = this.endTimeTarget;

    this.updateEndTime(target, time);
  }

  updateTime(event) {
    let time = event.target.value;
    let target = this.endTimeTarget;

    this.updateEndTime(target, time);
  }

  updateEndTime(target, time) {
    if (!time) {
      target.textContent = "Select a start time…";
      return false;
    }

    let hours = Number(time.split(":")[0]) + 2;
    let minutes = time.split(":")[1];
    let formattedTime = this.formatTimeShow(hours, minutes);

    target.textContent = formattedTime;
  }

  formatTimeShow(h_24, minutes) {
    let h = h_24 % 12;
    if (h === 0) h = 12;
    return `${h}:${minutes} ${h_24 < 12 ? "AM" : "PM"}`;
  }
}
