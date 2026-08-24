# Marmaradar

**Marmaradar** is a driving companion for **fixed speed cameras (EDS)** and **average-speed corridors** in **Turkey**. Coverage started around Bursa / Marmara and is expanding.

Open the map, start a drive, and get warnings before you reach a camera or enter a corridor. Alerts can keep working in the background.

Website: [www.marmaradar.com](https://www.marmaradar.com)

## What it does

- **Live map** — your position, nearby cameras, and corridor stretches
- **Speed camera alerts** — distance and speed limit as you approach a fixed camera
- **Average-speed corridors** — track your average vs the limit inside a corridor
- **Background warnings** — alerts with the screen off (always-on location required)
- **Destination search** — optional route with distance and ETA
- **Automatic tracking** — optionally start when driving is detected
- **Optional account** — Google / Apple / email; drive history, stats, and crowd reports when signed in

It is **not** a full navigation replacement and is **not** affiliated with EGM, KGM, or any public authority.

## Who it’s for

Drivers in Turkey who want a simple on-the-road camera/corridor alert app.

## Platforms

- **Android** — public **beta APK** from the website (`/downloads/marmaradar-beta.apk`). Not on Google Play yet.
- **iOS** — App Store listing is not published yet.

Sideloading the APK is at your own risk. See [Kullanım Şartları](https://www.marmaradar.com/kullanim-sartlari).

## How to use it

1. Install the app and allow **location** (and **notifications**). For alerts while the phone is locked, choose **always** location and disable battery restrictions for Marmaradar if the OS asks.
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

Contact: [marmaradar@gmail.com](mailto:marmaradar@gmail.com)

## Feedback

Questions or ideas? Open an issue on this repository or email the address above.

---

## For developers

See **[DEVELOPMENT.md](DEVELOPMENT.md)** for stack, local setup, API notes, and deploy guidance. See **[SECURITY.md](SECURITY.md)** for what must not be committed.
