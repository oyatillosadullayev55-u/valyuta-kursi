# 🇺🇿 Valyuta kursi

O‘zbekiston Markaziy bankining rasmiy valyuta kurslari asosida ishlaydigan Flutter ilovasi.

## Imkoniyatlar

- Valyuta kurslarini ko‘rish, qidirish, saralash va filtrlash
- Valyutalarni o‘zaro konvertatsiya qilish
- Kurslar tarixini grafikda ko‘rish
- Sevimli valyutalar va narx signallari
- Hamyon qiymatini so‘mda hisoblash
- Kriptovalyuta narxlarini ko‘rish
- Yorug‘/qorong‘i mavzu va rang aksentini tanlash
- Kurslarni keshda saqlash va internet bo‘lmaganda oxirgi saqlangan ma’lumotni ko‘rsatish

## Talablar

- Flutter SDK (Dart `>=3.0.0 <4.0.0`)
- Android Studio yoki VS Code
- Internet ulanishi — CBU kurslari va kripto narxlari uchun

## Ishga tushirish

```bash
flutter pub get
flutter run
```

Android APK yaratish:

```bash
flutter build apk --release
```

APK fayli `build/app/outputs/flutter-apk/app-release.apk` manzilida hosil bo‘ladi.

## Ma’lumot manbalari

- Valyuta kurslari: [O‘zbekiston Markaziy banki](https://cbu.uz/uz/arkhiv-kursov-valyut/json/)
- Kurs tarixi CBU API’ning valyuta kodi va sana qabul qiladigan manzili orqali olinadi.
- Kurslar va sozlamalar qurilmada `shared_preferences` orqali saqlanadi.

## Asosiy tuzilma

```text
lib/
├── controllers/   Ilova holati, sozlamalar va foydalanuvchi amallari
├── models/        Valyuta va kriptovalyuta modellari
├── pages/         Kurslar, konvertor, hamyon, kripto va sozlamalar sahifalari
├── services/      CBU/kripto API va lokal saqlash
├── utils/         Formatlash va bayroqlar
└── widgets/       Umumiy UI komponentlari
```
