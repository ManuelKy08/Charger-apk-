# ⚡ SuperCharger — Charger (apk)

Dashboard baterai keren buat Termux. Ada **2 versi**:

| File | Jenis | Isi |
|------|-------|-----|
| `charger.sh` | Bash (Termux) | Dashboard terminal baca baterai asli (`termux-battery-status` / sysfs), ada fallback mode simulasi |
| `SuperCharger.apk` | Android APK | Aplikasi WebView, baca baterai real via `navigator.getBattery()`, layar gak mati (KEEP_SCREEN_ON) |

## ✨ Fitur

- Persen baterai asli + bar gradient (merah → kuning → hijau)
- Status nge-charge / kabel dicolok / estimasi waktu penuh
- Auto refresh tiap 1.5 detik
- Desain terminal: `╔ S U P E R   C H A R G E ╗`
- APK versi touchscreen + auto keep-screen-on (temen nge-charge)
- ⚡ powered by Risky Manuel T

## 🛠 Build APK dari source

Butuh Termux + package:

```bash
pkg install -y aapt apksigner d8 openjdk-17
```

Download `android.jar` (SDK resmi, API 29):
```bash
cd /data/data/com.termux/files/usr/tmp/opencode
curl -sSL -o platform29.zip https://dl.google.com/android/repository/platform-29_r03.zip
unzip -o platform29.zip "android-10/android.jar" -d android
```

Build:
```bash
bash build.sh
```

Hasil di `SuperCharger.apk`. File `charger.keystore` (private key) TIDAK ikut di-repo — backup sendiri kalau mau update app dengan tanda tangan yang sama.

## 📲 Install APK

```bash
cd ~/storage/downloads
termux-open SuperCharger.apk
```

Izinin "Install aplikasi tak dikenal" untuk Termux. Karena bukan dari Play Store, Android bakal konfirmasi manual.

## 🔬 Data baterai

- **Script bash**: `termux-battery-status` (termux-api) dulu, jatoh ke `/sys/class/power_supply`, terakhir mode simulasi (nggak asli, nggak bohong — ada label `MODE SIMULASI`).
- **APK**: `navigator.getBattery()` bawaan WebView. Gak ngasih arus mA/suhu (keterbatasan API).