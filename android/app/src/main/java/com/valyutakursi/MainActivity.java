package com.valyutakursi;

import android.annotation.SuppressLint;
import android.app.Activity;
import android.os.Bundle;
import android.webkit.CookieManager;
import android.webkit.WebResourceRequest;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.webkit.WebChromeClient;
import android.webkit.JavascriptInterface;
import android.net.ConnectivityManager;
import android.net.NetworkInfo;
import android.content.Context;
import android.view.Window;
import android.view.WindowManager;
import android.os.Build;
import android.graphics.Color;
import android.view.View;
import android.os.Handler;
import android.os.Looper;
import org.json.JSONArray;
import org.json.JSONObject;
import java.io.BufferedReader;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.net.HttpURLConnection;
import java.net.URL;
import java.nio.charset.StandardCharsets;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

public class MainActivity extends Activity {

    private WebView webView;
    private final ExecutorService ratesExecutor = Executors.newSingleThreadExecutor();
    private final Handler mainHandler = new Handler(Looper.getMainLooper());

    @SuppressLint("SetJavaScriptEnabled")
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        // Full screen / edge-to-edge
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            Window window = getWindow();
            window.clearFlags(WindowManager.LayoutParams.FLAG_TRANSLUCENT_STATUS);
            window.addFlags(WindowManager.LayoutParams.FLAG_DRAWS_SYSTEM_BAR_BACKGROUNDS);
            window.setStatusBarColor(Color.parseColor("#0d47a1"));
        }

        setContentView(R.layout.activity_main);

        webView = findViewById(R.id.webview);

        // WebView settings
        WebSettings settings = webView.getSettings();
        settings.setJavaScriptEnabled(true);
        settings.setDomStorageEnabled(true);
        settings.setLoadWithOverviewMode(true);
        settings.setUseWideViewPort(true);
        settings.setBuiltInZoomControls(false);
        settings.setDisplayZoomControls(false);
        settings.setCacheMode(WebSettings.LOAD_DEFAULT);
        settings.setMixedContentMode(WebSettings.MIXED_CONTENT_ALWAYS_ALLOW);

        // Enable cookies
        CookieManager.getInstance().setAcceptCookie(true);
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            CookieManager.getInstance().setAcceptThirdPartyCookies(webView, true);
        }

        webView.setWebChromeClient(new WebChromeClient());
        webView.addJavascriptInterface(new RatesBridge(), "AndroidRates");

        webView.setWebViewClient(new WebViewClient() {
            @Override
            public boolean shouldOverrideUrlLoading(WebView view, WebResourceRequest request) {
                // Keep the JavaScript bridge limited to the bundled app page.
                return !request.getUrl().toString().startsWith("file:///android_asset/www/index.html");
            }

            @Override
            public void onPageFinished(WebView view, String url) {
                super.onPageFinished(view, url);
            }
        });

        // Local HTML ni yuklash — u o'zi CBU API ga so'rov yuboradi
        webView.loadUrl("file:///android_asset/www/index.html");
    }

    private final class RatesBridge {
        @JavascriptInterface
        public void fetchRates() {
            ratesExecutor.execute(() -> {
                HttpURLConnection connection = null;
                String callback;
                try {
                    URL url = new URL("https://cbu.uz/uz/arkhiv-kursov-valyut/json/");
                    connection = (HttpURLConnection) url.openConnection();
                    connection.setRequestMethod("GET");
                    connection.setConnectTimeout(8000);
                    connection.setReadTimeout(10000);
                    connection.setRequestProperty("Accept", "application/json");
                    connection.setRequestProperty("User-Agent", "ValyutaKurslari-Android");

                    int status = connection.getResponseCode();
                    if (status < 200 || status >= 300) {
                        throw new Exception("CBU HTTP " + status);
                    }
                    StringBuilder body = new StringBuilder();
                    try (InputStream stream = connection.getInputStream();
                         BufferedReader reader = new BufferedReader(new InputStreamReader(stream, StandardCharsets.UTF_8))) {
                        String line;
                        while ((line = reader.readLine()) != null) body.append(line);
                    }
                    JSONArray rates = new JSONArray(body.toString());
                    if (rates.length() == 0) throw new Exception("CBU kurslar ro‘yxatini bo‘sh qaytardi");
                    callback = "window.onNativeRatesSuccess&&window.onNativeRatesSuccess(" + JSONObject.quote(body.toString()) + ");";
                } catch (Exception e) {
                    String message = e.getMessage() == null ? "CBU serveriga ulanib bo‘lmadi" : e.getMessage();
                    callback = "window.onNativeRatesError&&window.onNativeRatesError(" + JSONObject.quote(message) + ");";
                } finally {
                    if (connection != null) connection.disconnect();
                }

                final String script = callback;
                mainHandler.post(() -> {
                    if (webView != null && !isFinishing()) webView.evaluateJavascript(script, null);
                });
            });
        }
    }

    private boolean isNetworkAvailable() {
        ConnectivityManager cm = (ConnectivityManager) getSystemService(Context.CONNECTIVITY_SERVICE);
        if (cm == null) return false;
        NetworkInfo info = cm.getActiveNetworkInfo();
        return info != null && info.isConnected();
    }

    @Override
    public void onBackPressed() {
        if (webView.canGoBack()) {
            webView.goBack();
        } else {
            super.onBackPressed();
        }
    }

    @Override
    protected void onResume() {
        super.onResume();
        webView.onResume();
    }

    @Override
    protected void onPause() {
        super.onPause();
        webView.onPause();
    }

    @Override
    protected void onDestroy() {
        ratesExecutor.shutdownNow();
        if (webView != null) {
            webView.destroy();
        }
        super.onDestroy();
    }
}
