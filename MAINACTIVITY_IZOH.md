# MainActivity.java — Kod izohi

Bu fayl Android ilovasining yagona ekrani (Activity). U ichida bitta `WebView` bor — ya'ni butun ilova aslida brauzer ichidagi HTML sahifadan iborat.

---

## Umumiy arxitektura

```
Android APK
 └── MainActivity.java       ← shu fayl
      └── WebView             ← brauzer oynasi
           └── assets/www/index.html  ← bizning UI
                └── fetch(CBU API)    ← internet so'rovi
```

Foydalanuvchi APK ni o'rnatadi → MainActivity ochiladi → WebView ichida `index.html` ishlaydi → HTML o'zi CBU serveriga so'rov yuboradi.

---

## Import qilingan kutubxonalar

```java
import android.annotation.SuppressLint;       // lint ogohlantirmasini o'chirish
import android.app.Activity;                  // Activity bazaviy klass
import android.os.Bundle;                     // savedInstanceState uchun
import android.webkit.CookieManager;          // cookie boshqaruvi
import android.webkit.WebResourceRequest;     // URL so'rovlarini ushlab qolish
import android.webkit.WebSettings;            // WebView sozlamalari
import android.webkit.WebView;                // asosiy brauzer komponenti
import android.webkit.WebViewClient;          // navigatsiyani boshqarish
import android.webkit.WebChromeClient;        // JavaScript dialog, progress
import android.net.ConnectivityManager;       // internet bor/yo'qligini tekshirish
import android.net.NetworkInfo;               // tarmoq holati
import android.content.Context;              // sistema servislariga kirish
import android.view.Window;                  // status bar rangi uchun
import android.view.WindowManager;           // oyna flaglari
import android.os.Build;                     // Android versiyasini tekshirish
import android.graphics.Color;              // rang qiymatlari
import android.view.View;                   // (import qilingan, ishlatilmayapti)
```

---

## `onCreate()` — ilova ishga tushganda

Bu metod Activity birinchi marta yaratilganda chaqiriladi.

### 1. Status bar rangini o'zgartirish

```java
if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
    Window window = getWindow();
    window.clearFlags(WindowManager.LayoutParams.FLAG_TRANSLUCENT_STATUS);
    window.addFlags(WindowManager.LayoutParams.FLAG_DRAWS_SYSTEM_BAR_BACKGROUNDS);
    window.setStatusBarColor(Color.parseColor("#0d47a1"));
}
```

- Faqat **Android 5.0 (Lollipop) va undan yuqori** qurilmalarda ishlaydi
- `FLAG_TRANSLUCENT_STATUS` olib tashlanadi → shaffof status bar yo'q bo'ladi
- `FLAG_DRAWS_SYSTEM_BAR_BACKGROUNDS` qo'shiladi → status bar rangini o'zimiz belgilashimiz mumkin
- `#0d47a1` — to'q ko'k rang (header bilan mos)

### 2. Layout o'rnatish

```java
setContentView(R.layout.activity_main);
webView = findViewById(R.id.webview);
```

- `activity_main.xml` faylidagi `RelativeLayout` ko'rsatiladi
- Undagi `@+id/webview` elementi olinadi

### 3. WebView sozlamalari

```java
WebSettings settings = webView.getSettings();
settings.setJavaScriptEnabled(true);        // JS ishlashi uchun (fetch, DOM...)
settings.setDomStorageEnabled(true);        // localStorage ishlashi uchun
settings.setLoadWithOverviewMode(true);     // sahifa ekranga sig'diradi
settings.setUseWideViewPort(true);          // viewport meta tegini hurmat qiladi
settings.setBuiltInZoomControls(false);     // zoom tugmalarini yashiradi
settings.setDisplayZoomControls(false);     // zoom ikonkasini yashiradi
settings.setCacheMode(WebSettings.LOAD_DEFAULT); // oddiy kesh: internetda yangi, oflaynda keshdan
settings.setMixedContentMode(WebSettings.MIXED_CONTENT_ALWAYS_ALLOW); // HTTP+HTTPS aralash ruxsat
```

> **Muhim:** `setJavaScriptEnabled(true)` bo'lmasa `fetch()` ishlamaydi va CBU API ga so'rov yuborib bo'lmaydi. `@SuppressLint("SetJavaScriptEnabled")` annotatsiyasi bu haqda lint ogohlantirmasini bostirib qo'yadi.

### 4. Cookie yoqish

```java
CookieManager.getInstance().setAcceptCookie(true);
if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
    CookieManager.getInstance().setAcceptThirdPartyCookies(webView, true);
}
```

CBU API cookie ishlatmaydi, lekin kelajakda boshqa servislar uchun foydali.

### 5. WebChromeClient

```java
webView.setWebChromeClient(new WebChromeClient());
```

JavaScript `alert()`, `confirm()`, `console.log()` va sahifa yuklanish progressi ishlashi uchun kerak. Bo'lmasa JS dialog funksiyalari jim ishlaydi.

### 6. WebViewClient — navigatsiyani boshqarish

```java
webView.setWebViewClient(new WebViewClient() {
    @Override
    public boolean shouldOverrideUrlLoading(WebView view, WebResourceRequest request) {
        return false; // false = WebView ichida och, tashqi brauzerga chiqma
    }

    @Override
    public void onPageFinished(WebView view, String url) {
        super.onPageFinished(view, url); // sahifa yuklandi (kengaytirish mumkin)
    }
});
```

`shouldOverrideUrlLoading` → `false` qaytarish degani: barcha havolalar WebView ichida ochiladi, tizim brauzeriga o'tilmaydi.

### 7. Sahifani yuklash

```java
webView.loadUrl("file:///android_asset/www/index.html");
```

- `file:///android_asset/` — APK ichidagi `assets/` papkasiga yo'l
- `www/index.html` — bizning HTML fayl
- Bu fayl o'zi `fetch("https://cbu.uz/...")` chaqiradi → internet orqali kurs oladi

---

## `isNetworkAvailable()` — internet tekshiruvi

```java
private boolean isNetworkAvailable() {
    ConnectivityManager cm = (ConnectivityManager) getSystemService(Context.CONNECTIVITY_SERVICE);
    if (cm == null) return false;
    NetworkInfo info = cm.getActiveNetworkInfo();
    return info != null && info.isConnected();
}
```

Internet bor yoki yo'qligini tekshiradi. Hozir bevosita ishlatilmayapti, lekin kelajakda "oflayn rejim" yoki xabar ko'rsatish uchun ishlatish mumkin.

> `AndroidManifest.xml` da `ACCESS_NETWORK_STATE` ruxsati bo'lishi shart, aks holda `getActiveNetworkInfo()` null qaytaradi.

---

## Lifecycle metodlari

### `onBackPressed()`
```java
if (webView.canGoBack()) {
    webView.goBack();   // WebView tarixida orqaga
} else {
    super.onBackPressed(); // ilovadan chiq
}
```
Foydalanuvchi "Orqaga" tugmasini bosganida WebView navigation tarixida orqaga qaytadi. Tarix tugasa ilova yopiladi.

### `onResume()`
```java
webView.onResume();
```
Ilova foreground ga qaytganda (boshqa ilovadan qaytganda) WebView ni faollashtiradi — video, animatsiya, timer ishlaydi.

### `onPause()`
```java
webView.onPause();
```
Ilova background ga o'tganda WebView ni to'xtatadi — batareyani tejaydi, CPU yukini kamaytiradi.

### `onDestroy()`
```java
if (webView != null) {
    webView.destroy();
}
```
Activity to'liq yopilganda WebView xotirani bo'shatadi. `null` tekshiruvi — agar `onCreate` da xato bo'lib webView yaratilmagan bo'lsa, crash oldini oladi.

---

## Ma'lumot oqimi (Data Flow)

```
Foydalanuvchi APK ochadi
        ↓
onCreate() chaqiriladi
        ↓
WebView sozlanadi (JS, DOM Storage, Cookie...)
        ↓
file:///android_asset/www/index.html yuklanadi
        ↓
HTML ichidagi JavaScript ishga tushadi
        ↓
fetch("https://cbu.uz/uz/arkhiv-kursov-valyut/json/")
        ↓
CBU serveri JSON qaytaradi
        ↓
JavaScript DOM ni yangilaydi (kurslar ko'rinadi)
        ↓
Har 5 daqiqada takrorlaydi (setInterval)
```

---

## Kengaytirish imkoniyatlari

| Xususiyat | Qanday qo'shish |
|---|---|
| Xabarnoma (notification) | `NotificationManager` + `AlarmManager` |
| Oflayn rejim | `onPageFinished` da keshga yozish |
| JS ↔ Java aloqa | `addJavascriptInterface()` |
| Pull-to-refresh | `SwipeRefreshLayout` ni WebView ustiga qo'yish |
| Splash screen | `SplashActivity` + `Intent` |
| Widget | `AppWidgetProvider` + RemoteViews |
