package com.zikos.remote;

import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothDevice;
import android.bluetooth.BluetoothSocket;
import android.content.Context;
import android.os.Handler;
import android.os.Looper;
import java.io.OutputStream;
import java.util.UUID;
import java.util.concurrent.LinkedBlockingQueue;

public class RemoteLink {
    public static final String SVC = "7d1a4f2e-8c9b-4e5a-9f30-6b1c2d3e4f50";
    private static BluetoothSocket sock = null;
    private static volatile OutputStream os = null;
    private static volatile boolean alive = false;
    private static final LinkedBlockingQueue<String> q = new LinkedBlockingQueue<>();

    public interface CB { void state(String s); }

    private static void post(final CB cb, final String s) {
        new Handler(Looper.getMainLooper()).post(new Runnable() {
            @Override public void run() { cb.state(s); }
        });
    }

    public static void connect(final Context ctx, final CB cb) {
        final String mac = ctx.getSharedPreferences("hikari", 0).getString("mac", "");
        if (mac.isEmpty()) { post(cb, "no"); return; }
        new Thread(new Runnable() {
            @Override public void run() {
                try {
                    BluetoothAdapter ad = BluetoothAdapter.getDefaultAdapter();
                    if (ad == null || !ad.isEnabled()) { post(cb, "off"); return; }
                    close();
                    BluetoothDevice d = ad.getRemoteDevice(mac);
                    sock = d.createRfcommSocketToServiceRecord(UUID.fromString(SVC));
                    sock.connect();
                    os = sock.getOutputStream();
                    alive = true;
                    post(cb, "ok");
                    Thread w = new Thread(new Runnable() {
                        @Override public void run() { writer(); }
                    });
                    w.setDaemon(true);
                    w.start();
                } catch (Exception e) { post(cb, "err"); }
            }
        }).start();
    }

    private static void writer() {
        try {
            while (alive) {
                String l = q.take();
                OutputStream o = os;
                if (o == null) break;
                try { o.write((l + "\n").getBytes("UTF-8")); o.flush(); }
                catch (Exception e) { break; }
            }
        } catch (Exception e) {}
        alive = false; os = null;
        try { if (sock != null) sock.close(); } catch (Exception e) {}
        sock = null;
    }

    public static boolean send(String line) { if (!alive) return false; q.offer(line); return true; }

    public static void close() {
        alive = false; q.clear();
        try { if (os != null) os.close(); } catch (Exception e) {}
        os = null;
        try { if (sock != null) sock.close(); } catch (Exception e) {}
        sock = null;
    }
}
