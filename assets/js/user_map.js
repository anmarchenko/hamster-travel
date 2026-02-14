import mapboxgl from 'mapbox-gl';

const VISITED_COUNTRIES_LAYER_ID = 'visited-countries';
const CITIES_SOURCE_ID = 'visited-cities';
const CITIES_SYMBOL_LAYER_ID = 'visited-cities-symbol';
const CITIES_CIRCLE_LAYER_ID = 'visited-cities-circle';

function parseJsonArray(value) {
  if (!value) {
    return [];
  }

  try {
    const parsed = JSON.parse(value);
    return Array.isArray(parsed) ? parsed : [];
  } catch (_error) {
    return [];
  }
}

function validIso3(code) {
  return typeof code === 'string' && code.trim().length === 3;
}

function validCity(city) {
  return (
    city &&
    typeof city.name === 'string' &&
    typeof city.country_iso === 'string' &&
    typeof city.lat === 'number' &&
    typeof city.lon === 'number'
  );
}

function escapeHtml(text) {
  return text
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&#39;');
}

function iso2ToEmoji(isoCode) {
  if (typeof isoCode !== 'string' || isoCode.length !== 2) {
    return '';
  }

  const upperCode = isoCode.toUpperCase();
  const REGIONAL_OFFSET = 127_397;

  return String.fromCodePoint(
    upperCode.charCodeAt(0) + REGIONAL_OFFSET,
    upperCode.charCodeAt(1) + REGIONAL_OFFSET,
  );
}

function cityPopupHtml(cityName, countryIso) {
  const flagEmoji = iso2ToEmoji(countryIso);
  return `<span class="map-city-popup-flag">${flagEmoji}</span>${escapeHtml(cityName)}`;
}

function addCitiesLayer(map) {
  if (map.hasImage('marker-15')) {
    map.addLayer({
      id: CITIES_SYMBOL_LAYER_ID,
      type: 'symbol',
      source: CITIES_SOURCE_ID,
      layout: {
        'icon-image': 'marker-15',
        'icon-allow-overlap': true,
      },
    });

    return CITIES_SYMBOL_LAYER_ID;
  }

  map.addLayer({
    id: CITIES_CIRCLE_LAYER_ID,
    type: 'circle',
    source: CITIES_SOURCE_ID,
    paint: {
      'circle-radius': 5,
      'circle-color': '#f97316',
      'circle-stroke-width': 1,
      'circle-stroke-color': '#ffffff',
    },
  });

  return CITIES_CIRCLE_LAYER_ID;
}

const UserMap = {
  mounted() {
    this.map = null;
    this.popup = null;

    const token = this.el.dataset.mapboxAccessToken;
    const styleUrl = this.el.dataset.mapboxStyleUrl;

    if (!token || !styleUrl) {
      return;
    }

    const countryIso3Codes = parseJsonArray(this.el.dataset.visitedCountryIso3Codes)
      .filter(validIso3)
      .map((code) => code.toUpperCase());

    const visitedCities = parseJsonArray(this.el.dataset.visitedCities).filter(validCity);

    try {
      // Mapbox expects an empty container before map initialization.
      this.el.replaceChildren();
      mapboxgl.accessToken = token;

      this.map = new mapboxgl.Map({
        container: this.el,
        style: styleUrl,
        center: [13.4515, 51.1657],
        minZoom: 2,
        zoom: 2.0000001,
        dragRotate: false,
      });

      this.map.addControl(new mapboxgl.NavigationControl());

      this.map.on('load', () => {
        if (this.map.getLayer(VISITED_COUNTRIES_LAYER_ID)) {
          const filter =
            countryIso3Codes.length > 0
              ? ['in', 'ADM0_A3_IS', ...countryIso3Codes]
              : ['==', 'ADM0_A3_IS', '__none__'];

          this.map.setFilter(VISITED_COUNTRIES_LAYER_ID, filter);
        }

        this.map.addSource(CITIES_SOURCE_ID, {
          type: 'geojson',
          data: {
            type: 'FeatureCollection',
            features: visitedCities.map((city) => ({
              type: 'Feature',
              geometry: {
                type: 'Point',
                coordinates: [city.lon, city.lat],
              },
              properties: {
                name: city.name,
                country_iso: city.country_iso,
              },
            })),
          },
        });

        const citiesLayerId = addCitiesLayer(this.map);

        this.popup = new mapboxgl.Popup({
          closeButton: false,
          closeOnClick: false,
          className: 'profile-city-popup',
        });

        this.map.on('mousemove', citiesLayerId, (event) => {
          const [feature] = event.features || [];

          if (!feature || !this.popup) {
            return;
          }

          this.map.getCanvas().style.cursor = 'pointer';

          this.popup
            .setLngLat(feature.geometry.coordinates)
            .setHTML(cityPopupHtml(feature.properties.name, feature.properties.country_iso))
            .addTo(this.map);
        });

        this.map.on('mouseleave', citiesLayerId, () => {
          this.map.getCanvas().style.cursor = '';
          this.popup?.remove();
        });
      });
    } catch (error) {
      // Keep profile usable if map assets fail to load.
      console.error(error);
    }
  },

  destroyed() {
    this.popup?.remove();
    this.map?.remove();
    this.popup = null;
    this.map = null;
  },
};

export default {
  UserMap,
};
