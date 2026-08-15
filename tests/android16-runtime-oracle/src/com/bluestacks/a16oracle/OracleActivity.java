package com.bluestacks.a16oracle;

import android.Manifest;
import android.app.Activity;
import android.app.BroadcastOptions;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.graphics.Bitmap;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.ImageFormat;
import android.graphics.Paint;
import android.hardware.camera2.CameraCaptureSession;
import android.hardware.camera2.CameraCharacteristics;
import android.hardware.camera2.CameraDevice;
import android.hardware.camera2.CameraManager;
import android.hardware.camera2.CaptureRequest;
import android.hardware.camera2.params.StreamConfigurationMap;
import android.media.AudioAttributes;
import android.media.AudioFormat;
import android.media.AudioTrack;
import android.media.Image;
import android.media.ImageReader;
import android.net.ConnectivityManager;
import android.net.DhcpInfo;
import android.net.Network;
import android.net.NetworkCapabilities;
import android.net.NetworkInfo;
import android.net.wifi.WifiInfo;
import android.net.wifi.WifiManager;
import android.os.Build;
import android.os.Bundle;
import android.os.Handler;
import android.os.HandlerThread;
import android.os.Process;
import android.util.Log;
import android.util.Size;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.net.NetworkInterface;
import java.nio.charset.StandardCharsets;
import java.util.Arrays;
import java.util.Locale;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.concurrent.atomic.AtomicReference;

public final class OracleActivity extends Activity {
    private static final String TAG = "A16RuntimeOracle";
    private static final String RETRY_DOWNLOADS =
            "android.provider.downloads.action.RETRY_DOWNLOADS";
    private static final String REDACTED_MAC_ADDRESS = "02:00:00:00:00:00";
    private static final int PERMISSION_REQUEST = 16;
    private boolean mStarted;

    private static native boolean hasSyntheticBoardPlatform();

    private interface CheckedTest {
        String run() throws Exception;
    }

    @Override
    protected void onCreate(Bundle state) {
        super.onCreate(state);
        if (hasRuntimePermissions()) {
            startOracle();
        } else {
            requestPermissions(runtimePermissions(), PERMISSION_REQUEST);
        }
    }

    @Override
    public void onRequestPermissionsResult(
            int requestCode, String[] permissions, int[] grantResults) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults);
        if (requestCode == PERMISSION_REQUEST && hasRuntimePermissions()) {
            startOracle();
        } else {
            fail("permissions", "required runtime permissions were denied");
            done();
        }
    }

    private String[] runtimePermissions() {
        if (Build.VERSION.SDK_INT >= 33) {
            return new String[] {
                    Manifest.permission.CAMERA,
                    Manifest.permission.ACCESS_FINE_LOCATION,
                    Manifest.permission.NEARBY_WIFI_DEVICES
            };
        }
        return new String[] {
                Manifest.permission.CAMERA,
                Manifest.permission.ACCESS_FINE_LOCATION
        };
    }

    private boolean hasRuntimePermissions() {
        for (String permission : runtimePermissions()) {
            if (checkSelfPermission(permission) != PackageManager.PERMISSION_GRANTED) {
                return false;
            }
        }
        return true;
    }

    private synchronized void startOracle() {
        if (mStarted) {
            return;
        }
        mStarted = true;
        new Thread(new Runnable() {
            @Override
            public void run() {
                runTest("wifi_identity", new CheckedTest() {
                    @Override
                    public String run() throws Exception {
                        return checkWifiIdentity();
                    }
                });
                runTest("network_presentation", new CheckedTest() {
                    @Override
                    public String run() {
                        return checkNetworkPresentation();
                    }
                });
                runTest("bionic_properties", new CheckedTest() {
                    @Override
                    public String run() throws Exception {
                        return checkBionicProperties();
                    }
                });
                runTest("skia_render", new CheckedTest() {
                    @Override
                    public String run() {
                        return checkSkiaRender();
                    }
                });
                runTest("audio_track", new CheckedTest() {
                    @Override
                    public String run() throws Exception {
                        return checkAudioTrack();
                    }
                });
                runTest("camera_frame", new CheckedTest() {
                    @Override
                    public String run() throws Exception {
                        return checkCameraFrame();
                    }
                });
                runTest("download_retry_sent", new CheckedTest() {
                    @Override
                    public String run() throws Exception {
                        return sendUnauthorizedDownloadRetry();
                    }
                });
                done();
            }
        }, "a16-runtime-oracle").start();
    }

    private void runTest(String name, CheckedTest test) {
        try {
            pass(name, test.run());
        } catch (Throwable error) {
            fail(name, error.getClass().getSimpleName() + ":" + error.getMessage());
        }
    }

    @SuppressWarnings("deprecation")
    private String checkWifiIdentity() throws Exception {
        WifiManager manager = getSystemService(WifiManager.class);
        require(manager != null, "WifiManager missing");
        WifiInfo info = manager.getConnectionInfo();
        require(info != null, "WifiInfo missing");
        require("\"BlueStacks\"".equals(info.getSSID())
                        || "BlueStacks".equals(info.getSSID()),
                "unexpected SSID " + info.getSSID());
        require(REDACTED_MAC_ADDRESS.equals(info.getMacAddress()),
                "unprivileged WifiInfo exposed MAC " + info.getMacAddress());
        require(isMac(info.getBSSID()), "invalid BSSID " + info.getBSSID());

        DhcpInfo dhcp = manager.getDhcpInfo();
        require(dhcp != null, "DhcpInfo missing");
        require(dhcp.ipAddress != 0, "guest IPv4 address missing");
        require(dhcp.gateway != 0, "gateway missing");
        require(dhcp.dns1 != 0, "primary DNS missing");

        NetworkInterface wlan = NetworkInterface.getByName("wlan0");
        require(wlan != null, "app-visible wlan0 missing");
        require(NetworkInterface.getByName("eth0") == null,
                "physical eth0 leaked to app UID");
        String interfaceMac = formatMac(wlan.getHardwareAddress());
        require(isMac(interfaceMac), "invalid app-visible wlan0 MAC " + interfaceMac);
        return "ssid=" + info.getSSID() + ",wifiInfoMac=redacted,wlan0Mac=" + interfaceMac;
    }

    @SuppressWarnings("deprecation")
    private String checkNetworkPresentation() {
        ConnectivityManager manager = getSystemService(ConnectivityManager.class);
        require(manager != null, "ConnectivityManager missing");
        Network active = manager.getActiveNetwork();
        require(active != null, "active network missing");
        NetworkCapabilities capabilities = manager.getNetworkCapabilities(active);
        require(capabilities != null, "active capabilities missing");
        boolean wifi = capabilities.hasTransport(NetworkCapabilities.TRANSPORT_WIFI);
        boolean ethernet = capabilities.hasTransport(NetworkCapabilities.TRANSPORT_ETHERNET);
        require(wifi ^ ethernet,
                "active network must expose exactly one configured transport: " + capabilities);
        NetworkInfo legacy = manager.getActiveNetworkInfo();
        require(legacy != null && legacy.isConnected(), "legacy active network is disconnected");
        require(legacy.getType() == ConnectivityManager.TYPE_WIFI
                        || legacy.getType() == ConnectivityManager.TYPE_ETHERNET,
                "unexpected legacy active network type " + legacy.getType());
        return "capability=" + (wifi ? "wifi" : "ethernet")
                + ",legacy=" + legacy.getTypeName();
    }

    private String checkSkiaRender() {
        Bitmap bitmap = Bitmap.createBitmap(16, 16, Bitmap.Config.ARGB_8888);
        try {
            Canvas canvas = new Canvas(bitmap);
            canvas.drawColor(Color.BLACK);
            Paint paint = new Paint();
            paint.setColor(Color.rgb(17, 203, 91));
            canvas.drawRect(4, 4, 12, 12, paint);
            require(bitmap.getPixel(8, 8) == Color.rgb(17, 203, 91),
                    "center pixel mismatch");
            require(bitmap.getPixel(0, 0) == Color.BLACK, "background pixel mismatch");
            return "software-canvas-pixels-ok";
        } finally {
            bitmap.recycle();
        }
    }

    private String checkBionicProperties() throws Exception {
        System.loadLibrary("a16propertyoracle");
        String debuggable = appGetprop("ro.debuggable");
        String secure = appGetprop("ro.secure");
        require(hasSyntheticBoardPlatform(),
                "direct bionic read did not synthesize ro.board.platform2");
        require("0".equals(debuggable), "ro.debuggable was not hidden: " + debuggable);
        require("1".equals(secure), "ro.secure was not hardened: " + secure);
        return "platform=ngg-client,debuggable=" + debuggable + ",secure=" + secure;
    }

    private static String appGetprop(String name) throws Exception {
        java.lang.Process child = new ProcessBuilder("/system/bin/getprop", name)
                .redirectErrorStream(true)
                .start();
        StringBuilder output = new StringBuilder();
        try (BufferedReader reader = new BufferedReader(new InputStreamReader(
                child.getInputStream(), StandardCharsets.UTF_8))) {
            String line;
            while ((line = reader.readLine()) != null) {
                if (output.length() > 0) {
                    output.append('\n');
                }
                output.append(line);
            }
        }
        require(child.waitFor(5, TimeUnit.SECONDS), "getprop timeout for " + name);
        require(child.exitValue() == 0, "getprop failed for " + name);
        return output.toString().trim();
    }

    private String checkAudioTrack() throws Exception {
        int sampleRate = 8000;
        short[] samples = new short[sampleRate / 4];
        for (int i = 0; i < samples.length; i++) {
            samples[i] = (short) (Math.sin(2.0 * Math.PI * 440.0 * i / sampleRate) * 800);
        }
        AudioTrack track = new AudioTrack.Builder()
                .setAudioAttributes(new AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_MEDIA)
                        .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                        .build())
                .setAudioFormat(new AudioFormat.Builder()
                        .setEncoding(AudioFormat.ENCODING_PCM_16BIT)
                        .setSampleRate(sampleRate)
                        .setChannelMask(AudioFormat.CHANNEL_OUT_MONO)
                        .build())
                .setTransferMode(AudioTrack.MODE_STATIC)
                .setBufferSizeInBytes(samples.length * 2)
                .build();
        try {
            require(track.getState() == AudioTrack.STATE_NO_STATIC_DATA,
                    "unexpected empty static AudioTrack state " + track.getState());
            int written = track.write(samples, 0, samples.length);
            require(written == samples.length, "short AudioTrack write " + written);
            require(track.getState() == AudioTrack.STATE_INITIALIZED,
                    "AudioTrack did not initialize after static data write");
            track.play();
            Thread.sleep(120);
            require(track.getPlayState() == AudioTrack.PLAYSTATE_PLAYING,
                    "AudioTrack did not enter PLAYING");
            return "samples=" + written;
        } finally {
            try {
                track.stop();
            } catch (IllegalStateException ignored) {
            }
            track.release();
        }
    }

    private String checkCameraFrame() throws Exception {
        CameraManager manager = getSystemService(CameraManager.class);
        require(manager != null, "CameraManager missing");
        String[] cameraIds = manager.getCameraIdList();
        require(cameraIds.length > 0, "camera ID list empty");
        String cameraId = cameraIds[0];
        CameraCharacteristics characteristics = manager.getCameraCharacteristics(cameraId);
        StreamConfigurationMap map = characteristics.get(
                CameraCharacteristics.SCALER_STREAM_CONFIGURATION_MAP);
        require(map != null, "camera stream map missing");
        Size[] sizes = map.getOutputSizes(ImageFormat.YUV_420_888);
        require(sizes != null && sizes.length > 0, "camera has no YUV output");
        Size size = sizes[0];
        for (Size candidate : sizes) {
            long candidateArea = (long) candidate.getWidth() * candidate.getHeight();
            long selectedArea = (long) size.getWidth() * size.getHeight();
            if (candidateArea < selectedArea) {
                size = candidate;
            }
        }

        HandlerThread callbackThread = new HandlerThread("a16-camera-oracle");
        callbackThread.start();
        Handler handler = new Handler(callbackThread.getLooper());
        ImageReader reader = ImageReader.newInstance(
                size.getWidth(), size.getHeight(), ImageFormat.YUV_420_888, 2);
        AtomicReference<CameraDevice> deviceRef = new AtomicReference<>();
        AtomicReference<CameraCaptureSession> sessionRef = new AtomicReference<>();
        AtomicReference<Throwable> failure = new AtomicReference<>();
        AtomicInteger imageBytes = new AtomicInteger();
        CountDownLatch opened = new CountDownLatch(1);
        CountDownLatch configured = new CountDownLatch(1);
        CountDownLatch frame = new CountDownLatch(1);
        reader.setOnImageAvailableListener(new ImageReader.OnImageAvailableListener() {
            @Override
            public void onImageAvailable(ImageReader source) {
                try (Image image = source.acquireNextImage()) {
                    if (image == null) {
                        failure.compareAndSet(
                                null, new IllegalStateException("null camera image"));
                    } else {
                        int bytes = 0;
                        for (Image.Plane plane : image.getPlanes()) {
                            bytes += plane.getBuffer().remaining();
                        }
                        imageBytes.set(bytes);
                    }
                } catch (Throwable error) {
                    failure.compareAndSet(null, error);
                } finally {
                    frame.countDown();
                }
            }
        }, handler);

        try {
            manager.openCamera(cameraId, new CameraDevice.StateCallback() {
                @Override
                public void onOpened(CameraDevice device) {
                    deviceRef.set(device);
                    opened.countDown();
                }

                @Override
                public void onDisconnected(CameraDevice device) {
                    failure.compareAndSet(null,
                            new IllegalStateException("camera disconnected"));
                    device.close();
                    opened.countDown();
                }

                @Override
                public void onError(CameraDevice device, int error) {
                    failure.compareAndSet(null,
                            new IllegalStateException("camera error " + error));
                    device.close();
                    opened.countDown();
                }
            }, handler);
            require(opened.await(8, TimeUnit.SECONDS), "camera open timeout");
            throwIfFailed(failure);
            CameraDevice device = deviceRef.get();
            require(device != null, "camera device missing after open");
            device.createCaptureSession(Arrays.asList(reader.getSurface()),
                    new CameraCaptureSession.StateCallback() {
                        @Override
                        public void onConfigured(CameraCaptureSession session) {
                            sessionRef.set(session);
                            configured.countDown();
                        }

                        @Override
                        public void onConfigureFailed(CameraCaptureSession session) {
                            failure.compareAndSet(null,
                                    new IllegalStateException("capture session rejected"));
                            configured.countDown();
                        }
                    }, handler);
            require(configured.await(8, TimeUnit.SECONDS), "camera configure timeout");
            throwIfFailed(failure);
            CameraCaptureSession session = sessionRef.get();
            require(session != null, "capture session missing");
            CaptureRequest.Builder request = device.createCaptureRequest(
                    CameraDevice.TEMPLATE_PREVIEW);
            request.addTarget(reader.getSurface());
            session.capture(request.build(), null, handler);
            require(frame.await(10, TimeUnit.SECONDS), "camera frame timeout");
            throwIfFailed(failure);
            require(imageBytes.get() > 0, "camera frame has no bytes");
            return "id=" + cameraId + ",size=" + size + ",bytes=" + imageBytes.get();
        } finally {
            CameraCaptureSession session = sessionRef.get();
            if (session != null) {
                session.close();
            }
            CameraDevice device = deviceRef.get();
            if (device != null) {
                device.close();
            }
            reader.close();
            callbackThread.quitSafely();
            callbackThread.join(2000);
        }
    }

    private String sendUnauthorizedDownloadRetry() throws Exception {
        Intent retry = new Intent(RETRY_DOWNLOADS)
                .setPackage("com.android.providers.downloads")
                .putExtra("a16_oracle_uid", Process.myUid());
        BroadcastOptions options = BroadcastOptions.makeBasic()
                .setShareIdentityEnabled(true);
        sendBroadcast(retry, null, options.toBundle());
        Thread.sleep(1500);
        return "uid=" + Process.myUid();
    }

    private static void throwIfFailed(AtomicReference<Throwable> failure) throws Exception {
        Throwable error = failure.get();
        if (error == null) {
            return;
        }
        if (error instanceof Exception) {
            throw (Exception) error;
        }
        throw new RuntimeException(error);
    }

    private static String formatMac(byte[] address) {
        require(address != null && address.length == 6, "invalid hardware address bytes");
        StringBuilder value = new StringBuilder(17);
        for (int index = 0; index < address.length; index++) {
            if (index > 0) {
                value.append(':');
            }
            value.append(String.format(Locale.US, "%02x", address[index] & 0xff));
        }
        return value.toString();
    }

    private static boolean isMac(String value) {
        return value != null && value.matches("(?i)(?:[0-9a-f]{2}:){5}[0-9a-f]{2}")
                && !"02:00:00:00:00:00".equalsIgnoreCase(value);
    }

    private static void require(boolean condition, String message) {
        if (!condition) {
            throw new IllegalStateException(message);
        }
    }

    private static String clean(String value) {
        return String.valueOf(value).replace('\n', ' ').replace('\r', ' ');
    }

    private static void pass(String name, String detail) {
        Log.i(TAG, "A16ORACLE:PASS:" + name + ":" + clean(detail));
    }

    private static void fail(String name, String detail) {
        Log.e(TAG, "A16ORACLE:FAIL:" + name + ":" + clean(detail));
    }

    private void done() {
        Log.i(TAG, "A16ORACLE:DONE:uid=" + Process.myUid());
        runOnUiThread(new Runnable() {
            @Override
            public void run() {
                finish();
            }
        });
    }
}
