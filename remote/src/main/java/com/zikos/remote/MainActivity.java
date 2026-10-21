package com.zikos.remote;

import android.app.Activity;
import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothDevice;
import android.graphics.Color;
import android.graphics.Typeface;
import android.graphics.drawable.GradientDrawable;
import android.os.Bundle;
import android.content.Intent;
import android.text.InputType;
import android.view.Gravity;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Button;
import android.widget.EditText;
import android.widget.LinearLayout;
import android.widget.ScrollView;
import android.widget.TextView;
import java.util.Set;

public class MainActivity extends Activity {
    private TextView picked;
    private TextView found;
    private EditText ipEdit;
    private String mac = "";
    private boolean scanning = false;

    @Override
    protected void onCreate(Bundle b) {
        super.onCreate(b);
        mac = getSharedPreferences("hikari", 0).getString("mac", "");
        build();
    }

    private float dp(float v) { return v * getResources().getDisplayMetrics().density; }

    private Button mkBtn(String text, int bg, int fg, float size) {
        Button bt = new Button(this);
        bt.setText(text);
        bt.setAllCaps(false);
        bt.setTextColor(fg);
        bt.setTextSize(size);
        bt.setPadding(0, 0, 0, 0);
        GradientDrawable g = new GradientDrawable();
        g.setColor(bg);
        g.setCornerRadius(dp(10));
        bt.setBackground(g);
        bt.setGravity(Gravity.CENTER);
        return bt;
    }

    private TextView mkTxt(String text, int color, float size) {
        TextView t = new TextView(this);
        t.setText(text);
        t.setTextColor(color);
        t.setTextSize(size);
        return t;
    }

    private void build() {
        ScrollView sc = new ScrollView(this);
        sc.setBackgroundColor(Color.parseColor("#0B0E14"));
        sc.setFillViewport(true);
        LinearLayout root = new LinearLayout(this);
        root.setOrientation(LinearLayout.VERTICAL);
        root.setPadding((int) dp(20), (int) dp(34), (int) dp(20), (int) dp(24));
        sc.addView(root, new ViewGroup.LayoutParams(-1, -2));
        setContentView(sc);

        root.addView(mkTxt("Hikari Remote", Color.WHITE, 30)).getTypeface();
        TextView t0 = (TextView) root.getChildAt(root.getChildCount() - 1);
        t0.setTypeface(Typeface.DEFAULT_BOLD);
        root.addView(mkTxt("Клавиатура и мышь для HikariOS", 0xFF8B97A6, 14));
        ((LinearLayout.LayoutParams) root.getChildAt(root.getChildCount() - 1).getLayoutParams()).topMargin = (int) dp(4);

        root.addView(mkTxt("1. На планшете: Настройки → «Bluetooth-клавиатура и мышь» → включить", 0xFFB8C4D4, 13));
        ((LinearLayout.LayoutParams) root.getChildAt(root.getChildCount() - 1).getLayoutParams()).topMargin = (int) dp(26);
        root.addView(mkTxt("2. Телефон и планшет — в одной Wi-Fi сети", 0xFFB8C4D4, 13));
        ((LinearLayout.LayoutParams) root.getChildAt(root.getChildCount() - 1).getLayoutParams()).topMargin = (int) dp(8);

        Button scan = mkBtn("НАЙТИ ПЛАНШЕТ", 0xFF1E3A5F, Color.WHITE, 18);
        LinearLayout.LayoutParams slp = new LinearLayout.LayoutParams(-1, (int) dp(56));
        slp.topMargin = (int) dp(18);
        root.addView(scan, slp);
        scan.setOnClickListener(new View.OnClickListener() {
            @Override public void onClick(View v) {
                if (scanning) return;
                scanning = true;
                found.setText("ищу планшет в сети...");
                new Thread(new Runnable() {
                    @Override public void run() {
                        final String ip = RemoteLink.discover(4000);
                        runOnUiThread(new Runnable() {
                            @Override public void run() {
                                scanning = false;
                                if (!ip.isEmpty()) {
                                    getSharedPreferences("hikari", 0).edit().putString("ip", ip).apply();
                                    found.setText("Найдено: HikariOS (" + ip + ")");
                                } else found.setText("Не найдено. Включи приём на планшете, проверь Wi-Fi или введи IP вручную.");
                            }
                        });
                    }
                }).start();
            }
        });

        found = mkTxt("", 0xFF5AA9F5, 14);
        LinearLayout.LayoutParams flp = new LinearLayout.LayoutParams(-1, -2);
        flp.topMargin = (int) dp(10);
        root.addView(found, flp);
        String savedIp = getSharedPreferences("hikari", 0).getString("ip", "");
        if (!savedIp.isEmpty()) found.setText("Запомнено: " + savedIp);

        ipEdit = new EditText(this);
        ipEdit.setHint("IP планшета, например 192.168.1.5");
        ipEdit.setTextColor(Color.WHITE);
        ipEdit.setHintTextColor(0xFF5B6472);
        ipEdit.setTextSize(15);
        ipEdit.setInputType(InputType.TYPE_CLASS_PHONE);
        LinearLayout.LayoutParams elp = new LinearLayout.LayoutParams(-1, (int) dp(46));
        elp.topMargin = (int) dp(14);
        root.addView(ipEdit, elp);

        Button manual = mkBtn("Подключить по IP", 0xFF151A26, Color.WHITE, 15);
        LinearLayout.LayoutParams mlp = new LinearLayout.LayoutParams(-1, (int) dp(46));
        mlp.topMargin = (int) dp(8);
        root.addView(manual, mlp);
        manual.setOnClickListener(new View.OnClickListener() {
            @Override public void onClick(View v) {
                String ip = ipEdit.getText().toString().trim();
                if (ip.isEmpty()) { found.setText("Введи IP или нажми «Найти планшет»"); return; }
                getSharedPreferences("hikari", 0).edit().putString("ip", ip).apply();
                found.setText("Запомнено: " + ip);
            }
        });

        root.addView(mkTxt("Запасной вариант — Bluetooth (нужна сопряга):", 0xFF5B6472, 12));
        ((LinearLayout.LayoutParams) root.getChildAt(root.getChildCount() - 1).getLayoutParams()).topMargin = (int) dp(22);
        LinearLayout devList = new LinearLayout(this);
        devList.setOrientation(LinearLayout.VERTICAL);
        root.addView(devList, new LinearLayout.LayoutParams(-1, -2));
        BluetoothAdapter ad = BluetoothAdapter.getDefaultAdapter();
        Set<BluetoothDevice> bonded = (ad != null) ? ad.getBondedDevices() : null;
        if (bonded != null && !bonded.isEmpty()) {
            for (final BluetoothDevice d : bonded) {
                Button bt = mkBtn(String.valueOf(d.getName()), 0xFF151A26, Color.WHITE, 14);
                bt.setGravity(Gravity.LEFT | Gravity.CENTER_VERTICAL);
                bt.setPadding((int) dp(14), 0, 0, 0);
                LinearLayout.LayoutParams blp = new LinearLayout.LayoutParams(-1, (int) dp(46));
                blp.topMargin = (int) dp(6);
                devList.addView(bt, blp);
                bt.setOnClickListener(new View.OnClickListener() {
                    @Override public void onClick(View v) {
                        mac = d.getAddress();
                        getSharedPreferences("hikari", 0).edit().putString("mac", mac).apply();
                        picked.setText("Bluetooth: " + d.getName());
                    }
                });
            }
        }

        picked = mkTxt("", 0xFF5AA9F5, 13);
        LinearLayout.LayoutParams plp = new LinearLayout.LayoutParams(-1, -2);
        plp.topMargin = (int) dp(12);
        root.addView(picked, plp);

        Button kb = mkBtn("КЛАВИАТУРА  EN/RU", 0xFF1E3A5F, Color.WHITE, 20);
        LinearLayout.LayoutParams klp = new LinearLayout.LayoutParams(-1, (int) dp(64));
        klp.topMargin = (int) dp(26);
        root.addView(kb, klp);
        kb.setOnClickListener(new View.OnClickListener() {
            @Override public void onClick(View v) { startActivity(new Intent(MainActivity.this, KeyboardActivity.class)); }
        });

        Button ms = mkBtn("МЫШКА", 0xFF1E3A5F, Color.WHITE, 20);
        LinearLayout.LayoutParams mslp = new LinearLayout.LayoutParams(-1, (int) dp(64));
        mslp.topMargin = (int) dp(10);
        root.addView(ms, mslp);
        ms.setOnClickListener(new View.OnClickListener() {
            @Override public void onClick(View v) { startActivity(new Intent(MainActivity.this, MouseActivity.class)); }
        });

        root.addView(mkTxt("Соединение по Wi-Fi автоматически. Bluetooth — только если Wi-Fi не находит.", 0xFF5B6472, 12));
        ((LinearLayout.LayoutParams) root.getChildAt(root.getChildCount() - 1).getLayoutParams()).topMargin = (int) dp(20);
    }
}
