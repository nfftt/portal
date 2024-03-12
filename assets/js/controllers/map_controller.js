import mapboxgl from 'mapbox-gl'
import { Controller } from "stimulus"

mapboxgl.accessToken = 'pk.eyJ1IjoiamVmZmpld2lzcyIsImEiOiI2Y2dSOFF3In0.pLIRGIMJdT1fvL2-A9dVng'

export default class extends Controller {
  static targets = ["container", "agency", "property", "equipmentset"]

  connect() {
    let mapContainer = this.containerTarget.id
    let pinList = [];
    let agencyData = this.agencyTarget.dataset;
    let propertyData = this.propertyTarget.dataset;
    let equipmentSetData = this.equipmentsetTarget.dataset;

    if (!Number.isNaN(Number(propertyData.longitude)) && !Number.isNaN(Number(propertyData.latitude))) {
      pinList.push({
        latitude: Number(this.propertyTarget.dataset.latitude),
        longitude: Number(this.propertyTarget.dataset.longitude)
      });
    }

    if (!Number.isNaN(Number(agencyData.longitude)) && !Number.isNaN(Number(agencyData.latitude))) {
      pinList.push({
        latitude: Number(this.agencyTarget.dataset.latitude),
        longitude: Number(this.agencyTarget.dataset.longitude)
      });
    }

    if (!Number.isNaN(Number(equipmentSetData.longitude)) && !Number.isNaN(Number(equipmentSetData.latitude))) {
      pinList.push({
        latitude: Number(this.equipmentsetTarget.dataset.latitude),
        longitude: Number(this.equipmentsetTarget.dataset.longitude)
      });
    }

    let map = new mapboxgl.Map({
      container: mapContainer,
      style: 'mapbox://styles/mapbox/streets-v11',
      center: [propertyData.longitude, propertyData.latitude],
      zoom: 14
    });

    // disable zooming from scrolling
    map.scrollZoom.disable();

    // Add button zoom controls
    let nav = new mapboxgl.NavigationControl({ position: 'topright' });
    map.addControl(nav, 'top-right');

    let geojson = this.createGeoJson(pinList);
    this.setupMap(map, geojson)
  }

  setupMap(map, geojson) {
    geojson.features.forEach((marker, ind) => {
      let el = document.createElement('div');
      el.className = 'pin-marker';
      el.innerHTML = ind + 1;

      // make a marker for each feature and add to the map
      new mapboxgl.Marker(el)
        .setLngLat(marker.geometry.coordinates)
        .addTo(map);
    });
  }

  createGeoJson (pinList) {
    return {
      type: 'FeatureCollection',
      features: pinList.map((pin) => ({
        type: 'Feature',
        geometry: {
          type: 'Point',
          coordinates: [pin.longitude, pin.latitude]
        }
      }))
    }
  }

}
