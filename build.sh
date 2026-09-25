#!/data/data/com.termux/files/usr/bin/bash
set -e

cd "$(dirname "$0")"

ANDROID_JAR="$HOME/../usr/tmp/opencode/android/android-10/android.jar"
if [ ! -f "$ANDROID_JAR" ]; then
  ANDROID_JAR=/data/data/com.termux/files/usr/tmp/opencode/android/android-10/android.jar
fi
[ -f "$ANDROID_JAR" ] || { echo "android.jar tidak ketemu"; exit 1; }

OUT=out
rm -rf "$OUT"
mkdir -p "$OUT/classes"

echo "[1/6] compile java..."
javac -source 8 -target 8 -bootclasspath "$ANDROID_JAR" -classpath "$ANDROID_JAR" \
  -d "$OUT/classes" src/com/duit/charger/MainActivity.java

echo "[2/6] build dex (d8)..."
d8 --release --lib "$ANDROID_JAR" --output "$OUT" \
   $(find "$OUT/classes" -name '*.class')

echo "[3/6] package resource + asset (aapt)..."
aapt package -f -M AndroidManifest.xml -I "$ANDROID_JAR" -A assets -F "$OUT/base.apk"

echo "[4/6] inject classes.dex..."
(cd "$OUT" && aapt add base.apk classes.dex)

echo "[5/6] generate keystore..."
if [ ! -f charger.keystore ]; then
  keytool -genkeypair -keystore charger.keystore -alias charger \
    -keyalg RSA -keysize 2048 -validity 10000 \
    -storepass charger123 -keypass charger123 \
    -dname "CN=SuperCharger, OU=duit, O=duit, C=ID" \
    -noprompt
fi

echo "[6/6] sign apk..."
apksigner sign --ks charger.keystore --ks-pass pass:charger123 \
  --key-pass pass:charger123 --out SuperCharger.apk "$OUT/base.apk"

ls -lh SuperCharger.apk
echo "SELESAI  ->  $PWD/SuperCharger.apk"
echo "Install:  pkg install -y termux-open; termux-open SuperCharger.apk"
echo "         (atau lihat di file manager, atau:  cp SuperCharger.apk ~/storage/downloads/ )"