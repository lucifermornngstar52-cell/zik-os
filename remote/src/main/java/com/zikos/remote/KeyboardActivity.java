package com.zikos.remote;

import android.app.Activity;
import android.graphics.Color;
import android.graphics.Typeface;
import android.graphics.drawable.GradientDrawable;
import android.os.Bundle;
import android.os.Handler;
import android.view.Gravity;
import android.view.MotionEvent;
import android.view.View;
import android.view.ViewGroup;
import android.view.WindowManager;
import android.widget.Button;
import android.widget.LinearLayout;
import android.widget.TextView;

public class KeyboardActivity extends Activity {
    private boolean ru = true;
    private boolean caps = false;
    private LinearLayout rows;
    private TextView status;
    private Handler rep = new Handler();

    private static final String[][] RU = {{"й","у","к","е","н","г","ш","щ","з","х","ъ"},{"ф","ы","в","а","п","р","о","л","д","ж"},{"я","ч","с","м","и","т","ь","б","ю"}};
    private static final String[][] EN = {{"q","w","e","r","t","y","u","i","o","p"},{"a","s","d","f","g","h","j","k","l"},{"z","x","c","v","b","n","m"}};

    private float dp(float v) { return v * getResources().getDisplayMetrics().density; }

    private void sendKey(String ch) { if (!RemoteLink.send("k:" + ch)) status.setText("нет связи — коснись"); }
    private void sendSp(String k) { if (!RemoteLink.send(k)) status.setText("нет связи — коснись"); }

    private Button keyBtn(String text, float size, float weight) {
        Button b = new Button(this);
        b.setText(text);
        b.setAllCaps(false);
        b.setTextColor(Color.WHITE);
        b.setTextSize(size);
        b.setTypeface(Typeface.DEFAULT, Typeface.NORMAL);
        b.setPadding(0, 0, 0, 0);
        GradientDrawable g = new GradientDrawable();
        g.setColor(0xFF151A26);
        g.setCornerRadius(dp(9));
        b.setBackground(g);
        b.setGravity(Gravity.CENTER);
        LinearLayout.LayoutParams lp = new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.MATCH_PARENT, weight);
        lp.leftMargin = (int) dp(2.5f);
        lp.rightMargin = (int) dp(2.5f);
        b.setLayoutParams(lp);
        return b;
    }

    private Button charKey(final String ch) {
        Button b = keyBtn(caps ? ch.toUpperCase() : ch, 22, 1);
        b.setOnClickListener(new View.OnClickListener() {
            @Override public void onClick(View v) {
                sendKey(caps ? ch.toUpperCase() : ch);
                if (caps) { caps = false; buildRows(); }
            }
        });
        return b;
    }

    private Button shiftKey() {
        final Button b = keyBtn("⇧", 20, 1.5f);
        if (caps) { GradientDrawable g = new GradientDrawable(); g.setColor(0xFF27476E); g.setCornerRadius(dp(9)); b.setBackground(g); }
        b.setOnClickListener(new View.OnClickListener() {
            @Override public void onClick(View v) { caps = !caps; buildRows(); }
        });
        return b;
    }

    private Button langKey() {
        Button b = keyBtn(ru ? "RU" : "EN", 16, 1.4f);
        b.setOnClickListener(new View.OnClickListener() {
            @Override public void onClick(View v) { ru = !ru; caps = false; buildRows(); }
        });
        return b;
    }

    private void buildRows() {
        rows.removeAllViews();
        String[][] lay = ru ? RU : EN;
        for (String[] row : lay) {
            LinearLayout r = new LinearLayout(this);
            r.setOrientation(LinearLayout.HORIZONTAL);
            LinearLayout.LayoutParams rlp = new LinearLayout.LayoutParams(-1, 0, 1);
            rlp.topMargin = (int) dp(2);
            rlp.bottomMargin = (int) dp(2);
            rows.addView(r, rlp);
            for (String ch : row) r.addView(charKey(ch));
            if (lay[2] == row) {
                r.addView(shiftKey());
                Button bs = keyBtn("⌫", 20, 1.6f);
                bs.setOnTouchListener(backspace());
                r.addView(bs);
            }
        }
        // нижний ряд
        LinearLayout r = new LinearLayout(this);
        r.setOrientation(LinearLayout.HORIZONTAL);
        LinearLayout.LayoutParams rlp = new LinearLayout.LayoutParams(-1, 0, 1);
        rlp.topMargin = (int) dp(2);
        rows.addView(r, rlp);
        r.addView(langKey());
        Button space = keyBtn("пробел", 16, 6);
        space.setOnClickListener(new View.OnClickListener() {
            @Override public void onClick(View v) { sendKey(" "); }
        });
        r.addView(space);
        Button enter = keyBtn("⏎", 20, 1.6f);
        enter.setOnClickListener(new View.OnClickListener() {
            @Override public void onClick(View v) { sendSp("kE"); }
        });
        r.addView(enter);
    }

    private View.OnTouchListener backspace() {
        return new View.OnTouchListener() {
            @Override public boolean onTouch(final View v, MotionEvent e) {
                if (e.getAction() == MotionEvent.ACTION_DOWN) {
                    sendSp("kB");
                    rep.postDelayed(new Runnable() {
                        @Override public void run() { sendSp("kB"); rep.postDelayed(this, 110); }
                    }, 380);
                    return true;
                }
                if (e.getAction() == MotionEvent.ACTION_UP || e.getAction() == MotionEvent.ACTION_CANCEL) {
                    rep.removeCallbacksAndMessages(null);
                    return true;
                }
                return false;
            }
        };
    }

    @Override
    protected void onCreate(Bundle b) {
        super.onCreate(b);
        getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
        LinearLayout root = new LinearLayout(this);
        root.setOrientation(LinearLayout.VERTICAL);
        root.setBackgroundColor(Color.parseColor("#0B0E14"));
        root.setPadding((int) dp(4), (int) dp(6), (int) dp(4), (int) dp(6));
        setContentView(root);

        status = new TextView(this);
        status.setTextColor(0xFF5AA9F5);
        status.setTextSize(12);
        status.setGravity(Gravity.CENTER);
        status.setText("подключение...");
        LinearLayout.LayoutParams slp = new LinearLayout.LayoutParams(-1, (int) dp(22));
        root.addView(status, slp);
        status.setOnClickListener(new View.OnClickListener() {
            @Override public void onClick(View v) { status.setText("подключение..."); RemoteLink.connect(KeyboardActivity.this, new RemoteLink.CB() {
                @Override public void state(String s) { status.setText(s.equals("ok") ? "● " + getSharedPreferences("hikari", 0).getString("name", "") : ("нет связи — коснись (" + s + ")")); }
            }); }
        });

        rows = new LinearLayout(this);
        rows.setOrientation(LinearLayout.VERTICAL);
        root.addView(rows, new LinearLayout.LayoutParams(-1, 0, 1));
        buildRows();

        RemoteLink.connect(this, new RemoteLink.CB() {
            @Override public void state(String s) {
                status.setText(s.equals("ok") ? "● " + getSharedPreferences("hikari", 0).getString("name", "") : "нет связи — коснись");
            }
        });
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        rep.removeCallbacksAndMessages(null);
        RemoteLink.close();
    }
}
