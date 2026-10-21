package com.zikos.remote;

import android.app.Activity;
import android.graphics.Color;
import android.os.Bundle;
import android.view.Gravity;
import android.view.MotionEvent;
import android.view.View;
import android.view.WindowManager;
import android.widget.FrameLayout;
import android.widget.TextView;

public class MouseActivity extends Activity {
    private TextView status;
    private float lastX = 0, lastY = 0, downX = 0, downY = 0, twoLastY = 0;
    private long downT = 0, twoT = 0;
    private boolean moved = false, twoMoved = false, two = false;
    private static final float SENS = 2.4f;

    @Override
    protected void onCreate(Bundle b) {
        super.onCreate(b);
        getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);

        FrameLayout root = new FrameLayout(this);
        root.setBackgroundColor(Color.BLACK);
        setContentView(root);

        TextView hint = new TextView(this);
        hint.setText("проведи пальцем — курсор движется\ntап — клик · два пальца тап — правая кнопка\nдва пальца вверх/вниз — колесо");
        hint.setTextColor(0xFF3A4048);
        hint.setTextSize(13);
        hint.setGravity(Gravity.CENTER);
        root.addView(hint, new FrameLayout.LayoutParams(-1, -1));

        View pad = new View(this);
        pad.setOnTouchListener(new View.OnTouchListener() {
            @Override public boolean onTouch(View v, MotionEvent e) {
                switch (e.getActionMasked()) {
                    case MotionEvent.ACTION_DOWN:
                        lastX = e.getX(); lastY = e.getY();
                        downX = e.getX(); downY = e.getY();
                        downT = System.currentTimeMillis();
                        moved = false; two = false; twoMoved = false;
                        break;
                    case MotionEvent.ACTION_POINTER_DOWN:
                        two = true;
                        twoT = System.currentTimeMillis();
                        twoLastY = e.getY(1);
                        break;
                    case MotionEvent.ACTION_MOVE:
                        if (two && e.getPointerCount() >= 2) {
                            float dy = e.getY(1) - twoLastY;
                            twoLastY = e.getY(1);
                            if (Math.abs(dy) > 1) { RemoteLink.send("s:" + Math.round(dy * 2)); twoMoved = true; }
                        } else {
                            float dx = e.getX() - lastX, dy = e.getY() - lastY;
                            lastX = e.getX(); lastY = e.getY();
                            if (dx != 0 || dy != 0) RemoteLink.send("m:" + Math.round(dx * SENS) + ":" + Math.round(dy * SENS));
                            if (Math.abs(e.getX() - downX) + Math.abs(e.getY() - downY) > 14) moved = true;
                        }
                        break;
                    case MotionEvent.ACTION_POINTER_UP:
                        if (System.currentTimeMillis() - twoT < 260 && !twoMoved) RemoteLink.send("c:2");
                        break;
                    case MotionEvent.ACTION_UP:
                        if (!two && !moved && System.currentTimeMillis() - downT < 260) RemoteLink.send("c:1");
                        two = false;
                        break;
                }
                return true;
            }
        });
        root.addView(pad, new FrameLayout.LayoutParams(-1, -1));

        status = new TextView(this);
        status.setTextColor(0xFF5AA9F5);
        status.setTextSize(12);
        status.setPadding(24, 16, 24, 16);
        status.setText("подключение...");
        status.setOnClickListener(new View.OnClickListener() {
            @Override public void onClick(View v) {
                status.setText("подключение...");
                RemoteLink.connect(MouseActivity.this, new RemoteLink.CB() {
                    @Override public void state(String s) { status.setText(s.equals("ok") ? "● мышь активна" : (s.equals("noip") ? "планшет не найден — вернись в меню" : "нет связи — коснись")); }
                });
            }
        });
        root.addView(status, new FrameLayout.LayoutParams(-2, -2, Gravity.TOP | Gravity.LEFT));

        RemoteLink.connect(this, new RemoteLink.CB() {
            @Override public void state(String s) { status.setText(s.equals("ok") ? "● мышь активна" : (s.equals("noip") ? "планшет не найден — вернись в меню" : "нет связи — коснись")); }
        });
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        RemoteLink.close();
    }
}
