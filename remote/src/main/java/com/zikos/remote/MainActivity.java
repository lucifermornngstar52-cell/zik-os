package com.zikos.remote;

import android.app.Activity;
import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothDevice;
import android.content.Intent;
import android.graphics.Color;
import android.graphics.Typeface;
import android.graphics.drawable.GradientDrawable;
import android.os.Bundle;
import android.view.Gravity;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Button;
import android.widget.LinearLayout;
import android.widget.ScrollView;
import android.widget.TextView;
import java.util.Set;

public class MainActivity extends Activity {
    private TextView picked;
    private String mac = "";

    @Override
    protected void onCreate(Bundle b) {
        super.onCreate(b);
        getWindow().setStatusBarColor(Color.parseColor("#0B0E14"));
        mac = getSharedPreferences("hikari", 0).getString("mac", "");
        build();
        if (BluetoothAdapter.getDefaultAdapter() != null && !BluetoothAdapter.getDefaultAdapter().isEnabled()) {
            try { startActivityForResult(new Intent(BluetoothAdapter.ACTION_REQUEST_ENABLE), 1); } catch (Exception e) {}
        }
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

    private void build() {
        ScrollView sc = new ScrollView(this);
        sc.setBackgroundColor(Color.parseColor("#0B0E14"));
        sc.setFillViewport(true);
        LinearLayout root = new LinearLayout(this);
        root.setOrientation(LinearLayout.VERTICAL);
        root.setPadding((int) dp(20), (int) dp(34), (int) dp(20), (int) dp(24));
        sc.addView(root, new ViewGroup.LayoutParams(-1, -2));
        setContentView(sc);

        TextView t = new TextView(this);
        t.setText("Hikari Remote");
        t.setTextColor(Color.WHITE);
        t.setTextSize(30);
        t.setTypeface(Typeface.DEFAULT_BOLD);
        root.addView(t);
        TextView st = new TextView(this);
        st.setText("Клавиатура и мышь для HikariOS через Bluetooth");
        st.setTextColor(0xFF8B97A6);
        st.setTextSize(14);
        root.addView(st);
        ((LinearLayout.LayoutParams) st.getLayoutParams()).topMargin = (int) dp(4);

        TextView h1 = new TextView(this);
        h1.setText("1. Сопряги этот телефон с планшетом в настройках Bluetooth Android");
        h1.setTextColor(0xFF8B97A6);
        h1.setTextSize(13);
        LinearLayout.LayoutParams lp = new LinearLayout.LayoutParams(-1, -2);
        lp.topMargin = (int) dp(28);
        root.addView(h1, lp);

        TextView h2 = new TextView(this);
        h2.setText("2. Выбери планшет:");
        h2.setTextColor(0xFFB8C4D4);
        h2.setTextSize(15);
        LinearLayout.LayoutParams lp2 = new LinearLayout.LayoutParams(-1, -2);
        lp2.topMargin = (int) dp(12);
        root.addView(h2, lp2);

        LinearLayout devList = new LinearLayout(this);
        devList.setOrientation(LinearLayout.VERTICAL);
        root.addView(devList, new LinearLayout.LayoutParams(-1, -2));

        Set<BluetoothDevice> bonded = BluetoothAdapter.getDefaultAdapter() != null ? BluetoothAdapter.getDefaultAdapter().getBondedDevices() : null;
        if (bonded != null && !bonded.isEmpty()) {
            for (final BluetoothDevice d : bonded) {
                Button bt = mkBtn(String.valueOf(d.getName()), 0xFF151A26, Color.WHITE, 15);
                bt.setGravity(Gravity.LEFT | Gravity.CENTER_VERTICAL);
                bt.setPadding((int) dp(14), 0, 0, 0);
                LinearLayout.LayoutParams blp = new LinearLayout.LayoutParams(-1, (int) dp(52));
                blp.topMargin = (int) dp(8);
                devList.addView(bt, blp);
                bt.setOnClickListener(new View.OnClickListener() {
                    @Override public void onClick(View v) {
                        mac = d.getAddress();
                        getSharedPreferences("hikari", 0).edit().putString("mac", mac).putString("name", String.valueOf(d.getName())).apply();
                        picked.setText("Выбрано: " + d.getName());
                    }
                });
            }
        } else {
            TextView none = new TextView(this);
            none.setText("Нет сопряжённых устройств. Сопряги в настройках Bluetooth и вернись.");
            none.setTextColor(0xFF8B97A6);
            none.setTextSize(13);
            root.addView(none);
        }

        picked = new TextView(this);
        picked.setTextColor(0xFF5AA9F5);
        picked.setTextSize(14);
        LinearLayout.LayoutParams plp = new LinearLayout.LayoutParams(-1, -2);
        plp.topMargin = (int) dp(14);
        root.addView(picked, plp);
        String savedName = getSharedPreferences("hikari", 0).getString("name", "");
        if (!mac.isEmpty()) picked.setText("Выбрано: " + savedName);

        TextView h3 = new TextView(this);
        h3.setText("3. Выбери программу:");
        h3.setTextColor(0xFFB8C4D4);
        h3.setTextSize(15);
        LinearLayout.LayoutParams lp3 = new LinearLayout.LayoutParams(-1, -2);
        lp3.topMargin = (int) dp(26);
        root.addView(h3, lp3);

        Button kb = mkBtn("КЛАВИАТУРА  EN/RU", 0xFF1E3A5F, Color.WHITE, 20);
        LinearLayout.LayoutParams klp = new LinearLayout.LayoutParams(-1, (int) dp(64));
        klp.topMargin = (int) dp(10);
        root.addView(kb, klp);
        kb.setOnClickListener(new View.OnClickListener() {
            @Override public void onClick(View v) {
                if (mac.isEmpty()) { picked.setText("Сначала выбери планшет!"); return; }
                startActivity(new Intent(MainActivity.this, KeyboardActivity.class));
            }
        });

        Button ms = mkBtn("МЫШКА", 0xFF1E3A5F, Color.WHITE, 20);
        LinearLayout.LayoutParams mlp = new LinearLayout.LayoutParams(-1, (int) dp(64));
        mlp.topMargin = (int) dp(10);
        root.addView(ms, mlp);
        ms.setOnClickListener(new View.OnClickListener() {
            @Override public void onClick(View v) {
                if (mac.isEmpty()) { picked.setText("Сначала выбери планшет!"); return; }
                startActivity(new Intent(MainActivity.this, MouseActivity.class));
            }
        });

        TextView note = new TextView(this);
        note.setText("На планшете включи Bluetooth-вход: Настройки → «Bluetooth-клавиатура и мышь».");
        note.setTextColor(0xFF5B6472);
        note.setTextSize(12);
        LinearLayout.LayoutParams nlp = new LinearLayout.LayoutParams(-1, -2);
        nlp.topMargin = (int) dp(24);
        root.addView(note, nlp);
    }
}
