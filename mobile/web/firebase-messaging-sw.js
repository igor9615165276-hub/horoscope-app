// web/firebase-messaging-sw.js

// Подключаем Firebase SDK (v8 — подходит для FCM в сервис‑воркере)
importScripts('https://www.gstatic.com/firebasejs/8.10.1/firebase-app.js');
importScripts('https://www.gstatic.com/firebasejs/8.10.1/firebase-messaging.js');

// Конфиг ДОЛЖЕН совпадать с FirebaseOptions.web из lib/firebase_options.dart
const firebaseConfig = {
  apiKey: "AIzaSyCDGD4aC0Swi2R304HPHyCHk0RWZI2YhzI",
  appId: "1:567481575985:web:13d88cb0d1c249f14a4310",
  messagingSenderId: "567481575985",
  projectId: "horoscope-app-1c4c0",
  authDomain: "horoscope-app-1c4c0.firebaseapp.com",
  storageBucket: "horoscope-app-1c4c0.firebasestorage.app",
  measurementId: "G-C0NVXX9HG4",
};

// Инициализация Firebase в сервис‑воркере
firebase.initializeApp(firebaseConfig);

// Инициализация messaging
const messaging = firebase.messaging();

// (опционально) Обработка фоновых уведомлений
// Здесь можно кастомизировать отображение уведомлений, если надо
messaging.setBackgroundMessageHandler(function (payload) {
  console.log('[firebase-messaging-sw.js] Received background message ', payload);

  const notificationTitle = payload.notification?.title || 'Horoscope';
  const notificationOptions = {
    body: payload.notification?.body || '',
    icon: '/icons/Icon-192.png', // подставь свой путь к иконке, если есть
  };

  return self.registration.showNotification(notificationTitle, notificationOptions);
});
