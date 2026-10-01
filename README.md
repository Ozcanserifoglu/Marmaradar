# Marmaradar

**Marmaradar** is a driving companion for **fixed speed cameras (EDS)** and **average-speed corridors** in **Turkey**. Coverage started around Bursa / Marmara and is expanding.

Open the map, start a drive, and get warnings before you reach a camera or enter a corridor while the app is in use.

Website: [www.marmaradar.com](https://www.marmaradar.com)

## What it does

- **Live map** — your position, nearby cameras, and corridor stretches
- **Speed camera alerts** — distance and speed limit as you approach a fixed camera
- **Average-speed corridors** — track your average vs the limit inside a corridor
- **Voice & on-screen alerts** — camera and corridor warnings while the app is open
- **Destination search** — optional route with distance and ETA
- **Automatic tracking** — optionally start when driving is detected
- **Optional account** — Google / Apple / email; drive history, stats, and crowd reports when signed in

It is **not** a full navigation replacement and is **not** affiliated with EGM, KGM, or any public authority.

## Who it’s for

Drivers in Turkey who want a simple on-the-road camera/corridor alert app.

## Platforms

- **Android** — [Google Play](https://www.marmaradar.com/#get-app) (set the listing URL in `web/src/config/storeLinks.js`).
- **iOS** — App Store listing is not published yet.

See [Kullanım Şartları](https://www.marmaradar.com/kullanim-sartlari).

## How to use it

1. Install the app and allow **location** (while in use) and **notifications**.
2. Open the map and wait for GPS lock.
3. Tap **Sürüşe Başla** to start tracking, or turn on **Otomatik**.
4. Optionally search a destination (**Nereye?**) and follow the route.
5. Watch for camera and corridor alerts; tap a camera marker for more detail.
6. Tap **Sürüşü Bitir** when you’re done.

## Privacy and terms

Location is required for map and alerts. Nearby camera queries can send coordinates even without an account. Signed-in users may upload full trip tracks and post reports.

Public pages (Turkish):

- [Gizlilik / KVKK](https://www.marmaradar.com/gizlilik)
- [Kullanım Şartları](https://www.marmaradar.com/kullanim-sartlari)

### OpenStreetMap

Camera and corridor features are partly derived from [OpenStreetMap](https://www.openstreetmap.org/copyright) data, © OpenStreetMap contributors, licensed under the [Open Database License (ODbL)](https://opendatacommons.org/licenses/odbl/). The app basemap is Google Maps; OSM attribution applies to the radar/corridor dataset. See [OSM copyright](https://www.openstreetmap.org/copyright) and the [OSMF attribution guidelines](https://wiki.osmfoundation.org/wiki/Licence/Attribution_Guidelines).

Contact: [marmaradar@gmail.com](mailto:marmaradar@gmail.com)

## Feedback

Questions or ideas? Open an issue on this repository or email the address above.

---

## For developers

See **[DEVELOPMENT.md](DEVELOPMENT.md)** for stack, local setup, API notes, and deploy guidance. See **[SECURITY.md](SECURITY.md)** for what must not be committed.
