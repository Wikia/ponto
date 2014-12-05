package com.wikia.ponto.sample;

import com.wikia.ponto.Ponto;
import com.wikia.ponto.Ponto.RequestCallback;

import android.app.Activity;
import android.os.Bundle;
import android.view.Menu;
import android.view.MenuItem;
import android.webkit.WebChromeClient;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.widget.Toast;

public class WebActivity extends Activity {

    private static final String HTML_FILE_PATH = "file:///android_asset/ponto_sample.html"; 
    private static final String PONTO_MODULES_PACKAGE = "com.wikia.ponto.sample.modules";

    private static final String JS_ALERT_CLASS = "Alert";
    private static final String JS_ALERT_METHOD = "show";
    private static final String JS_ALERT_PARAM = "{\"text\": \"Hello WebView alert\"}";
    private static final String JS_ALERT_SUCCESS = "Alert.onSuccess()";
    private static final String JS_ALERT_ERROR = "Alert.onError()";

    private WebView mWebView;
    private Ponto mPonto;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_web);

        mWebView = (WebView) findViewById(R.id.webview);
        mWebView.setWebViewClient(new WebViewClient());
        mWebView.setWebChromeClient(new WebChromeClient());
        mWebView.getSettings().setBuiltInZoomControls(false);

        mPonto = new Ponto(mWebView, PONTO_MODULES_PACKAGE);

        mWebView.loadUrl(HTML_FILE_PATH);
    }

    @Override
    public boolean onCreateOptionsMenu(Menu menu) {
        getMenuInflater().inflate(R.menu.web, menu);
        return true;
    }

    @Override
    public boolean onOptionsItemSelected(MenuItem item) {
        int id = item.getItemId();
        if (id == R.id.action_alert) {
            openWebViewAlert();
            return true;
        }
        return super.onOptionsItemSelected(item);
    }

    private void openWebViewAlert() {
        RequestCallback callback = new Ponto.RequestCallback() {

            @Override
            public void onSuccess() {
                Toast.makeText(WebActivity.this, JS_ALERT_SUCCESS, Toast.LENGTH_SHORT).show();
            }

            @Override
            public void onError() {
                Toast.makeText(WebActivity.this, JS_ALERT_ERROR, Toast.LENGTH_SHORT).show();
            }
        };
        mPonto.invoke(JS_ALERT_CLASS, JS_ALERT_METHOD, JS_ALERT_PARAM, callback);
    }
}