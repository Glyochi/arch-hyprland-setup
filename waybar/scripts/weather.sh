#!/usr/bin/env bash

set -euo pipefail

ZIP_CODE="${1:-50266}"

if [[ ! "$ZIP_CODE" =~ ^[0-9]{5}$ ]]; then
  python3 - <<'PY'
import json
print(json.dumps({
    "text": "Weather N/A",
    "tooltip": "ZIP must be 5 digits (e.g. 50266)."
}))
PY
  exit 0
fi

ZIP_LOOKUP_URL="https://api.zippopotam.us/us/${ZIP_CODE}"

if ! ZIP_JSON="$(curl -fsS --max-time 15 "$ZIP_LOOKUP_URL")"; then
  python3 - "$ZIP_CODE" <<'PY'
import json
import sys
zip_code = sys.argv[1]
print(json.dumps({
    "text": "Weather N/A",
    "tooltip": f"Could not look up location for ZIP {zip_code}."
}))
PY
  exit 0
fi

python3 - "$ZIP_JSON" "$ZIP_CODE" <<'PY'
import json
import sys
from urllib import parse, request


def fail(msg: str) -> None:
    print(json.dumps({"text": "Weather N/A", "tooltip": msg}))
    raise SystemExit(0)


def weather_label(code: int) -> str:
    labels = {
        0: "Clear",
        1: "Mainly clear",
        2: "Partly cloudy",
        3: "Overcast",
        45: "Fog",
        48: "Rime fog",
        51: "Light drizzle",
        53: "Drizzle",
        55: "Dense drizzle",
        56: "Freezing drizzle",
        57: "Dense freezing drizzle",
        61: "Light rain",
        63: "Rain",
        65: "Heavy rain",
        66: "Freezing rain",
        67: "Heavy freezing rain",
        71: "Light snow",
        73: "Snow",
        75: "Heavy snow",
        77: "Snow grains",
        80: "Rain showers",
        81: "Rain showers",
        82: "Heavy showers",
        85: "Snow showers",
        86: "Heavy snow showers",
        95: "Thunderstorm",
        96: "Storm with hail",
        99: "Heavy storm with hail",
    }
    return labels.get(code, "Unknown")


def wind_compass(deg: float) -> str:
    dirs = ["N", "NNE", "NE", "ENE", "E", "ESE", "SE", "SSE", "S", "SSW", "SW", "WSW", "W", "WNW", "NW", "NNW"]
    idx = int((deg % 360) / 22.5 + 0.5) % 16
    return dirs[idx]

try:
    zip_data = json.loads(sys.argv[1])
    zip_code = sys.argv[2]

    places = zip_data.get("places") or []
    if not places:
        fail(f"No location found for ZIP {zip_code}.")

    place = places[0]
    lat = place.get("latitude")
    lon = place.get("longitude")
    if lat is None or lon is None:
        fail(f"Location lookup did not return coordinates for ZIP {zip_code}.")

    location = place.get("place name") or "Unknown"
    region = place.get("state abbreviation") or place.get("state") or ""
    country = zip_data.get("country") or "United States"

    params = parse.urlencode(
        {
            "latitude": lat,
            "longitude": lon,
            "current": "temperature_2m,apparent_temperature,relative_humidity_2m,wind_speed_10m,wind_direction_10m,weather_code",
            "wind_speed_unit": "kmh",
            "temperature_unit": "celsius",
            "timezone": "auto",
        }
    )
    weather_url = f"https://api.open-meteo.com/v1/forecast?{params}"

    with request.urlopen(weather_url, timeout=15) as resp:
        weather_data = json.loads(resp.read().decode("utf-8"))

    current = weather_data.get("current") or {}
    temp_c = current.get("temperature_2m")
    feels_c = current.get("apparent_temperature")
    humidity = current.get("relative_humidity_2m")
    wind_kmph = current.get("wind_speed_10m")
    wind_deg = current.get("wind_direction_10m")
    code = int(current.get("weather_code", -1))

    if temp_c is None:
        fail("Open-Meteo did not return current weather data.")

    desc = weather_label(code)
    wind_dir = wind_compass(float(wind_deg)) if wind_deg is not None else "?"
    place_label = f"{location}, {region}" if region else location

    text = f"{round(float(temp_c))}C {desc}"
    tooltip = "\n".join([
        place_label,
        f"ZIP: {zip_code}",
        country,
        f"Condition: {desc}",
        f"Temperature: {temp_c}C",
        f"Feels like: {feels_c}C",
        f"Humidity: {humidity}%",
        f"Wind: {wind_kmph} km/h {wind_dir}",
    ])

    print(json.dumps({"text": text, "tooltip": tooltip}))
except Exception:
    fail(f"Could not fetch weather from Open-Meteo for ZIP {zip_code}.")
PY
