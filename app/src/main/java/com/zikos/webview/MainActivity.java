package com.zikos.webview;

import android.app.Activity;
import android.app.ActivityManager;
import android.content.Intent;
import android.content.IntentFilter;
import android.os.BatteryManager;
import android.os.Build;
import android.os.Bundle;
import android.os.Environment;
import android.os.StatFs;
import android.webkit.JavascriptInterface;
import android.webkit.WebView;
import org.json.JSONObject;

public class MainActivity extends Activity {

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        WebView webView = new WebView(this);
        webView.getSettings().setJavaScriptEnabled(true);
        webView.getSettings().setDomStorageEnabled(true);
        webView.getSettings().setAllowFileAccess(true);
        webView.getSettings().setAllowFileAccessFromFileURLs(true);
        webView.getSettings().setAllowUniversalAccessFromFileURLs(true);
        webView.setBackgroundColor(0xFF000000);
        webView.addJavascriptInterface(new Bridge(), "zikBridge");
        setContentView(webView);
        webView.loadUrl("file:///android_asset/index.html");
    }

    public class Bridge {
        @JavascriptInterface
        public String sysinfo() {
            try {
                JSONObject o = new JSONObject();
                o.put("model", Build.MODEL);
                o.put("manufacturer", Build.MANUFACTURER);
                o.put("board", Build.BOARD);
                o.put("android", Build.VERSION.RELEASE);
                o.put("sdk", Build.VERSION.SDK_INT);
                o.put("cores", Runtime.getRuntime().availableProcessors());
                ActivityManager am = (ActivityManager) getSystemService(ACTIVITY_SERVICE);
                ActivityManager.MemoryInfo mi = new ActivityManager.MemoryInfo();
                am.getMemoryInfo(mi);
                o.put("ramTotal", mi.totalMem);
                o.put("ramAvail", mi.availMem);
                Intent b = registerReceiver(null, new IntentFilter(Intent.ACTION_BATTERY_CHANGED));
                int level = b.getIntExtra(BatteryManager.EXTRA_LEVEL, -1);
                int scale = b.getIntExtra(BatteryManager.EXTRA_SCALE, -1);
                int status = b.getIntExtra(BatteryManager.EXTRA_STATUS, -1);
                o.put("battery", (level >= 0 && scale > 0) ? level * 100 / scale : -1);
                o.put("charging", status == BatteryManager.BATTERY_STATUS_CHARGING || status == BatteryManager.BATTERY_STATUS_FULL);
                int temp = b.getIntExtra(BatteryManager.EXTRA_TEMPERATURE, -1);
                o.put("temp", temp >= 0 ? temp / 10.0 : -1);
                int volt = b.getIntExtra(BatteryManager.EXTRA_VOLTAGE, -1);
                o.put("voltage", volt >= 0 ? volt : -1);
                StatFs st = new StatFs(Environment.getDataDirectory().getAbsolutePath());
                o.put("storageTotal", st.getTotalBytes());
                o.put("storageAvail", st.getAvailableBytes());
                return o.toString();
            } catch (Exception e) {
                return "{}";
            }
        }
    }
}
