package com.zikos.webview;

import android.app.Activity;
import android.app.ActivityManager;
import android.content.Intent;
import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothServerSocket;
import android.bluetooth.BluetoothSocket;
import java.io.BufferedReader;
import java.io.InputStreamReader;
import android.content.IntentFilter;
import android.os.BatteryManager;
import android.os.Build;
import android.os.Bundle;
import android.os.Environment;
import android.os.StatFs;
import android.net.Uri;
import android.webkit.JavascriptInterface;
import android.webkit.WebView;
import android.view.View;
import android.util.Base64;
import android.content.ContentValues;
import android.provider.MediaStore;
import java.io.InputStream;
import java.io.ByteArrayOutputStream;
import java.io.OutputStream;
import org.json.JSONObject;
import org.json.JSONArray;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileWriter;
import java.util.List;
import java.util.ArrayList;
import android.content.pm.ResolveInfo;
import android.content.pm.PackageManager;
import android.Manifest;
import java.util.Collections;
import java.util.Comparator;

public class MainActivity extends Activity {

    private String pickedContent = null;
    private boolean fsMode = true;
    private WebView webView = null;
    private volatile boolean btInputOn = false;
    private BluetoothServerSocket btServer = null;
    private static final String BT_UUID = "7d1a4f2e-8c9b-4e5a-9f30-6b1c2d3e4f50";

    private void js(final String code) {
        runOnUiThread(new Runnable() {
            @Override
            public void run() { if (webView != null) webView.evaluateJavascript(code, null); }
        });
    }

    private void stopBtInput() {
        try { if (btServer != null) btServer.close(); } catch (Exception e) {}
        btServer = null;
        js("window.__remoteIn&&window.__remoteIn({t:'st',s:'off'})");
    }

    private void startBtInput() {
        new Thread(new Runnable() {
            @Override
            public void run() {
                try {
                    final BluetoothAdapter ad = BluetoothAdapter.getDefaultAdapter();
                    if (ad == null || !ad.isEnabled()) { js("window.__remoteIn&&window.__remoteIn({t:'st',s:'nobt'})"); return; }
                    btServer = ad.listenUsingRfcommWithServiceRecord("Hikari Input", java.util.UUID.fromString(BT_UUID));
                    while (btInputOn) {
                        BluetoothSocket s = btServer.accept();
                        if (!btInputOn) { try { s.close(); } catch (Exception e) {} break; }
                        serveBt(s);
                    }
                } catch (Exception e) {
                    if (btInputOn) js("window.__remoteIn&&window.__remoteIn({t:'st',s:'err'})");
                }
            }
        }).start();
    }

    private void serveBt(BluetoothSocket s) {
        String nm = "";
        try { nm = String.valueOf(s.getRemoteDevice().getName()).replace(String.valueOf((char)39), ""); } catch (Exception e) {}
        js("window.__remoteIn&&window.__remoteIn({t:'st',s:'on',n:'" + nm + "'})");
        try {
            BufferedReader r = new BufferedReader(new InputStreamReader(s.getInputStream(), "UTF-8"));
            String line;
            while (btInputOn && (line = r.readLine()) != null) {
                String msg = btParse(line);
                if (msg != null) js("window.__remoteIn&&window.__remoteIn(" + msg + ")");
            }
        } catch (Exception e) {}
        try { s.close(); } catch (Exception e) {}
        js("window.__remoteIn&&window.__remoteIn({t:'st',s:'lost'})");
    }

    private String btParse(String line) {
        try {
            if (line.startsWith("k:")) {
                JSONObject o = new JSONObject();
                o.put("t", "k");
                o.put("c", line.substring(2));
                return o.toString();
            }
            if (line.equals("kB") || line.equals("kE") || line.equals("kL") || line.equals("kR") || line.equals("kU") || line.equals("kD") || line.equals("kT")) {
                JSONObject o = new JSONObject();
                o.put("t", "e");
                String k = "back";
                if (line.equals("kE")) k = "enter";
                else if (line.equals("kL")) k = "left";
                else if (line.equals("kR")) k = "right";
                else if (line.equals("kU")) k = "up";
                else if (line.equals("kD")) k = "down";
                else if (line.equals("kT")) k = "tab";
                o.put("k", k);
                return o.toString();
            }
            if (line.startsWith("m:")) {
                String[] p = line.split(":");
                if (p.length >= 3) {
                    JSONObject o = new JSONObject();
                    o.put("t", "m");
                    o.put("dx", Long.parseLong(p[1].trim()));
                    o.put("dy", Long.parseLong(p[2].trim()));
                    return o.toString();
                }
            }
            if (line.equals("c:1") || line.equals("c:2")) {
                JSONObject o = new JSONObject();
                o.put("t", "c");
                o.put("b", line.endsWith("1") ? 1 : 2);
                return o.toString();
            }
            if (line.startsWith("s:")) {
                JSONObject o = new JSONObject();
                o.put("t", "s");
                o.put("d", Long.parseLong(line.substring(2).trim()));
                return o.toString();
            }
        } catch (Exception e) {}
        return null;
    }

    private void hideSystemUI() {
        View decor = getWindow().getDecorView();
        decor.setSystemUiVisibility(
            View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY
            | View.SYSTEM_UI_FLAG_FULLSCREEN
            | View.SYSTEM_UI_FLAG_HIDE_NAVIGATION
            | View.SYSTEM_UI_FLAG_LAYOUT_STABLE
            | View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
            | View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN);
    }

    @Override
    public void onWindowFocusChanged(boolean hasFocus) {
        super.onWindowFocusChanged(hasFocus);
        if (hasFocus && fsMode) hideSystemUI();
    }
    private static final int PICK_FILE = 4242;

    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        if (requestCode == PICK_FILE) {
            if (resultCode == RESULT_OK && data != null && data.getData() != null) {
                try {
                    InputStream is = getContentResolver().openInputStream(data.getData());
                    ByteArrayOutputStream bos = new ByteArrayOutputStream();
                    byte[] buf = new byte[8192];
                    int n;
                    while ((n = is.read(buf)) > 0 && bos.size() < 2 * 1024 * 1024) bos.write(buf, 0, n);
                    is.close();
                    pickedContent = bos.toString("UTF-8");
                } catch (Exception e) {
                    pickedContent = "__error__";
                }
            } else {
                pickedContent = "__cancel__";
            }
        }
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        webView = new WebView(this);
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
        public void saveDownload(String name, String mime, String b64) {
            try {
                byte[] data = Base64.decode(b64, Base64.DEFAULT);
                ContentValues cv = new ContentValues();
                cv.put(MediaStore.Downloads.DISPLAY_NAME, name);
                cv.put(MediaStore.Downloads.MIME_TYPE, mime);
                cv.put(MediaStore.Downloads.IS_PENDING, 1);
                android.net.Uri uri = getContentResolver().insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, cv);
                OutputStream os = getContentResolver().openOutputStream(uri);
                os.write(data);
                os.close();
                cv.clear();
                cv.put(MediaStore.Downloads.IS_PENDING, 0);
                getContentResolver().update(uri, cv, null, null);
            } catch (Exception e) {
            }
        }

        @JavascriptInterface
        public String importFile() {
            pickedContent = null;
            Intent i = new Intent(Intent.ACTION_OPEN_DOCUMENT);
            i.addCategory(Intent.CATEGORY_OPENABLE);
            i.setType("*/*");
            startActivityForResult(Intent.createChooser(i, "Выберите файл"), PICK_FILE);
            return "ok";
        }

        @JavascriptInterface
        public String getPicked() {
            return pickedContent;
        }

        @JavascriptInterface
        public void setFullscreen(final boolean on) {
            fsMode = on;
            runOnUiThread(new Runnable() {
                @Override
                public void run() {
                    if (on) hideSystemUI();
                    else getWindow().getDecorView().setSystemUiVisibility(View.SYSTEM_UI_FLAG_VISIBLE);
                }
            });
        }

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
        @JavascriptInterface
        public String listApps() {
            try {
                Intent main = new Intent(Intent.ACTION_MAIN);
                main.addCategory(Intent.CATEGORY_LAUNCHER);
                List<ResolveInfo> pkgs = getPackageManager().queryIntentActivities(main, 0);
                JSONArray arr = new JSONArray();
                for (ResolveInfo r : pkgs) {
                    JSONObject o = new JSONObject();
                    o.put("name", String.valueOf(r.loadLabel(getPackageManager())));
                    o.put("pkg", r.activityInfo.packageName);
                    arr.put(o);
                }
                return arr.toString();
            } catch (Exception e) {
                return "[]";
            }
        }

        @JavascriptInterface
        public String launchApp(String pkg) {
            try {
                Intent i = getPackageManager().getLaunchIntentForPackage(pkg);
                if (i != null) {
                    i.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
                    startActivity(i);
                    return "ok";
                }
                return "no";
            } catch (Exception e) {
                return "err";
            }
        }

        @JavascriptInterface
        public boolean hasPerm() {
            return checkSelfPermission(Manifest.permission.READ_EXTERNAL_STORAGE) == PackageManager.PERMISSION_GRANTED;
        }

        @JavascriptInterface
        public void askPerm() {
            runOnUiThread(new Runnable() {
                @Override
                public void run() {
                    requestPermissions(new String[]{Manifest.permission.READ_EXTERNAL_STORAGE, Manifest.permission.WRITE_EXTERNAL_STORAGE}, 7);
                }
            });
        }

        @JavascriptInterface
        public String listDir(String path) {
            try {
                File f = new File(path);
                JSONArray arr = new JSONArray();
                File[] files = f.listFiles();
                if (files == null) return "[]";
                List<File> lst = new ArrayList<File>();
                for (File c : files) lst.add(c);
                Collections.sort(lst, new Comparator<File>() {
                    @Override
                    public int compare(File a, File b) {
                        if (a.isDirectory() != b.isDirectory()) return a.isDirectory() ? -1 : 1;
                        return a.getName().toLowerCase().compareTo(b.getName().toLowerCase());
                    }
                });
                for (File c : lst) {
                    JSONObject o = new JSONObject();
                    o.put("name", c.getName());
                    o.put("path", c.getAbsolutePath());
                    o.put("dir", c.isDirectory());
                    o.put("size", c.length());
                    arr.put(o);
                }
                return arr.toString();
            } catch (Exception e) {
                return "[]";
            }
        }

        @JavascriptInterface
        public String readText(String path) {
            try {
                FileInputStream fis = new FileInputStream(path);
                ByteArrayOutputStream bos = new ByteArrayOutputStream();
                byte[] buf = new byte[8192];
                int n;
                while ((n = fis.read(buf)) > 0 && bos.size() < 4 * 1024 * 1024) bos.write(buf, 0, n);
                fis.close();
                return bos.toString("UTF-8");
            } catch (Exception e) {
                return "__error__";
            }
        }

        @JavascriptInterface
        public String saveText(String path, String data) {
            try {
                File f = new File(path);
                File dir = f.getParentFile();
                if (dir != null) dir.mkdirs();
                FileWriter w = new FileWriter(f);
                w.write(data);
                w.close();
                return "ok";
            } catch (Exception e) {
                return "err";
            }
        }

        @JavascriptInterface
        public void setBtInput(final boolean on) {
            btInputOn = on;
            if (on) startBtInput(); else stopBtInput();
        }

        @JavascriptInterface
        public void openUrl(String url) {
            try {
                startActivity(new Intent(Intent.ACTION_VIEW, Uri.parse(url)));
            } catch (Exception e) {
            }
        }
    }
}
