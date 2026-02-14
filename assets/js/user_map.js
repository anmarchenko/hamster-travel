const MAPBOX_JS_URL = 'https://api.mapbox.com/mapbox-gl-js/v2.15.0/mapbox-gl.js';
const MAPBOX_CSS_URL = 'https://api.mapbox.com/mapbox-gl-js/v2.15.0/mapbox-gl.css';
const MAPBOX_SCRIPT_ID = 'hamster-mapbox-script';
const MAPBOX_STYLE_ID = 'hamster-mapbox-style';
const LEGACY_VISITED_COUNTRIES_LAYER = 'visited-countries';
const CITIES_SOURCE_ID = 'visited-cities';
const CITIES_LAYER_ID = 'visited-cities';

let mapboxAssetsPromise;

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

function ensureMapboxAssets() {
  if (window.mapboxgl) {
    return Promise.resolve(window.mapboxgl);
  }

  if (mapboxAssetsPromise) {
    return mapboxAssetsPromise;
  }

  mapboxAssetsPromise = new Promise((resolve, reject) => {
    if (!document.getElementById(MAPBOX_STYLE_ID)) {
      const styleLink = document.createElement('link');
      styleLink.id = MAPBOX_STYLE_ID;
      styleLink.rel = 'stylesheet';
      styleLink.href = MAPBOX_CSS_URL;
      document.head.appendChild(styleLink);
    }

    let script = document.getElementById(MAPBOX_SCRIPT_ID);

    if (!script) {
      script = document.createElement('script');
      script.id = MAPBOX_SCRIPT_ID;
      script.async = true;
      script.src = MAPBOX_JS_URL;
      document.head.appendChild(script);
    }

    script.addEventListener(
      'load',
      () => {
        if (window.mapboxgl) {
          resolve(window.mapboxgl);
        } else {
          reject(new Error('Mapbox GL script loaded but window.mapboxgl is unavailable.'));
        }
      },
      { once: true },
    );

    script.addEventListener(
      'error',
      () => {
        reject(new Error('Failed to load Mapbox GL script.'));
      },
      { once: true },
    );
  });

  return mapboxAssetsPromise;
}

const UserMap = {
  async mounted() {
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
      const mapboxgl = await ensureMapboxAssets();
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
        if (this.map.getLayer(LEGACY_VISITED_COUNTRIES_LAYER)) {
          const filter =
            countryIso3Codes.length > 0
              ? ['in', 'ADM0_A3_IS', ...countryIso3Codes]
              : ['==', 'ADM0_A3_IS', '__none__'];

          this.map.setFilter(LEGACY_VISITED_COUNTRIES_LAYER, filter);
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

        this.map.addLayer({
          id: CITIES_LAYER_ID,
          type: 'symbol',
          source: CITIES_SOURCE_ID,
          layout: {
            'icon-image': 'marker-15',
            'icon-allow-overlap': true,
          },
        });

        this.popup = new mapboxgl.Popup({
          closeButton: false,
          closeOnClick: false,
        });

        this.map.on('mousemove', CITIES_LAYER_ID, (event) => {
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

        this.map.on('mouseleave', CITIES_LAYER_ID, () => {
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
