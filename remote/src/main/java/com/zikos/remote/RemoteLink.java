package com.zikos.remote;

import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothDevice;
import android.bluetooth.BluetoothSocket;
import android.content.Context;
import android.os.Handler;
import android.os.Looper;
import java.io.OutputStream;
import java.net.DatagramPacket;
import java.net.DatagramSocket;
import java.net.InetAddress;
import java.net.InetSocketAddress;
import java.net.NetworkInterface;
import java.net.Socket;
import java.util.Enumeration;
import java.util.UUID;
import java.util.concurrent.LinkedBlockingQueue;

public class RemoteLink {
    public static final String SVC = "7d1a4f2e-8c9b-4e5a-9f30-6b1c2d3e4f50";
    public static final int TCP_PORT = 49998;
    public static final int UDP_PORT = 49999;
    private static Socket tcpSock = null;
    private static BluetoothSocket btSock = null;
    private static volatile OutputStream os = null;
    private static volatile boolean alive = false;
    private static final LinkedBlockingQueue<String> q = new LinkedBlockingQueue<>();

    public interface CB { void state(String s); }

    private static void post(final CB cb, final String s) {
        new Handler(Looper.getMainLooper()).post(new Runnable() {
            @Override public void run() { cb.state(s); }
        });
    }

    public static String myIp() {
        try {
            Enumeration<NetworkInterface> es = NetworkInterface.getNetworkInterfaces();
            while (es.hasMoreElements()) {
                NetworkInterface n = es.nextElement();
                if (!n.isUp() || n.isLoopback()) continue;
                Enumeration<InetAddress> as = n.getInetAddresses();
                while (as.hasMoreElements()) {
                    InetAddress a = as.nextElement();
                    if (!a.isLoopbackAddress() && a.getAddress().length == 4) return a.getHostAddress();
                }
            }
        } catch (Exception e) {}
        return "";
    }

    public static String discover(long timeoutMs) {
        DatagramSocket ds = null;
        try {
            ds = new DatagramSocket();
            ds.setBroadcast(true);
            ds.setSoTimeout(500);
            byte[] qmsg = "HIKARI_DISCOVER".getBytes("UTF-8");
            long end = System.currentTimeMillis() + timeoutMs;
            while (System.currentTimeMillis() < end) {
                try {
                    DatagramPacket qp = new DatagramPacket(qmsg, qmsg.length, InetAddress.getByName("255.255.255.255"), UDP_PORT);
                    ds.send(qp);
                    String ip = myIp();
                    if (!ip.isEmpty()) {
                        int li = ip.lastIndexOf('.');
                        if (li > 0) {
                            String sub = ip.substring(0, li) + ".255";
                            DatagramPacket qp2 = new DatagramPacket(qmsg, qmsg.length, InetAddress.getByName(sub), UDP_PORT);
                            ds.send(qp2);
                        }
                    }
                } catch (Exception e) {}
                byte[] buf = new byte[256];
                DatagramPacket rp = new DatagramPacket(buf, buf.length);
                try {
                    ds.receive(rp);
                    String msg = new String(rp.getData(), 0, rp.getLength(), "UTF-8");
                    if (msg.startsWith("HIKARI:")) {
                        String[] parts = msg.split(":");
                        if (parts.length >= 3 && parts[2].length() > 6) return parts[2];
                    }
                } catch (Exception e) {}
            }
        } catch (Exception e) {}
        finally { try { if (ds != null) ds.close(); } catch (Exception e) {} }
        return "";
    }

    public static void connect(final Context ctx, final CB cb) {
        new Thread(new Runnable() {
            @Override public void run() {
                close();
                String ip = discover(2500);
                if (ip.isEmpty()) ip = ctx.getSharedPreferences("hikari", 0).getString("ip", "");
                if (!ip.isEmpty() && tryTcp(ip)) { post(cb, "ok"); return; }
                String mac = ctx.getSharedPreferences("hikari", 0).getString("mac", "");
                if (!mac.isEmpty() && tryBt(mac)) { post(cb, "ok"); return; }
                post(cb, ip.isEmpty() && mac.isEmpty() ? "noip" : "err");
            }
        }).start();
    }

    private static boolean tryTcp(String ip) {
        try {
            Socket s = new Socket();
            s.connect(new InetSocketAddress(ip, TCP_PORT), 2500);
            tcpSock = s;
            os = s.getOutputStream();
            alive = true;
            startWriter();
            return true;
        } catch (Exception e) { return false; }
    }

    private static boolean tryBt(String mac) {
        try {
            BluetoothAdapter ad = BluetoothAdapter.getDefaultAdapter();
            if (ad == null || !ad.isEnabled()) return false;
            BluetoothDevice d = ad.getRemoteDevice(mac);
            BluetoothSocket s = d.createRfcommSocketToServiceRecord(UUID.fromString(SVC));
            s.connect();
            btSock = s;
            os = s.getOutputStream();
            alive = true;
            startWriter();
            return true;
        } catch (Exception e) { return false; }
    }

    private static void startWriter() {
        Thread w = new Thread(new Runnable() {
            @Override public void run() { writer(); }
        });
        w.setDaemon(true);
        w.start();
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
        try { if (tcpSock != null) tcpSock.close(); } catch (Exception e) {}
        try { if (btSock != null) btSock.close(); } catch (Exception e) {}
        tcpSock = null; btSock = null;
    }

    public static boolean send(String line) { if (!alive) return false; q.offer(line); return true; }

    public static void close() {
        alive = false; q.clear();
        try { if (os != null) os.close(); } catch (Exception e) {}
        os = null;
        try { if (tcpSock != null) tcpSock.close(); } catch (Exception e) {}
        try { if (btSock != null) btSock.close(); } catch (Exception e) {}
        tcpSock = null; btSock = null;
    }
}
