package com.github.rmtmckenzie.native_device_orientation;

import android.app.Activity;
import android.content.res.Configuration;
import android.hardware.SensorManager;
import android.os.Build;
import android.view.OrientationEventListener;
import android.view.Surface;

import java.util.Objects;


public class SensorOrientationListener implements IOrientationListener {
    private final Activity activity;
    private final OrientationCallback callback;
    private final Rate rate;
    private OrientationEventListener orientationEventListener;
    private NativeOrientation lastOrientation = null;
    private int angleOffset = 0;

    public SensorOrientationListener(Activity activity, OrientationCallback callback, Rate rate) {
        this.activity = activity;
        this.callback = callback;
        this.rate = rate;
        // orientation is 0 in the default orientation mode. This is portait-mode for phones
        // and landscape for tablets. We have to compensate this by calculating the default orientation,
        // and applying an offset.
        int defaultDeviceOrientation = getDeviceDefaultOrientation();
        if (defaultDeviceOrientation == Configuration.ORIENTATION_LANDSCAPE) {
            // add offset to landscape
            angleOffset = 270;
        }
    }

    public SensorOrientationListener(Activity activity, OrientationCallback callback) {
        this(activity, callback, Rate.ui);
    }

    @Override
    public void startOrientationListener() {
        if (orientationEventListener != null) {
            callback.receive(lastOrientation);
            return;
        }

        orientationEventListener = new OrientationEventListener(activity, rate.nativeValue) {
            @Override
            public void onOrientationChanged(int angle) {
                NativeOrientation newOrientation = calculateSensorOrientation(angle);

                if (newOrientation != null && !newOrientation.equals(lastOrientation)) {
                    lastOrientation = newOrientation;
                    callback.receive(newOrientation);
                }
            }
        };
        if (orientationEventListener.canDetectOrientation()) {
            orientationEventListener.enable();
        }
    }

    @Override
    public void stopOrientationListener() {
        if (orientationEventListener == null) return;
        orientationEventListener.disable();
        orientationEventListener = null;
    }

    public NativeOrientation calculateSensorOrientation(int angle) {
        if (angle == OrientationEventListener.ORIENTATION_UNKNOWN) {
            // return NativeOrientation.Unknown;
            return null;
        }
        NativeOrientation returnOrientation = null;

        angle += angleOffset;
        angle = angle % 360;

        if (angle < 10 || angle > 350) {
            returnOrientation = NativeOrientation.PortraitUp;
        } else if (angle > 80 && angle < 100) {
            returnOrientation = NativeOrientation.LandscapeRight;
        } else if (angle > 170 && angle < 190) {
            returnOrientation = NativeOrientation.PortraitDown;
        } else if (angle > 260 && angle < 280) {
            returnOrientation = NativeOrientation.LandscapeLeft;
        }

        return returnOrientation;
    }

    public int getDeviceDefaultOrientation() {
        Configuration config = activity.getResources().getConfiguration();

        int rotation;
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            rotation = Objects.requireNonNull(activity.getDisplay()).getRotation();
        } else {
            rotation = OrientationReader.getRotationOld(activity);
        }

        if (((rotation == Surface.ROTATION_0 || rotation == Surface.ROTATION_180) &&
                config.orientation == Configuration.ORIENTATION_LANDSCAPE)
                || ((rotation == Surface.ROTATION_90 || rotation == Surface.ROTATION_270) &&
                config.orientation == Configuration.ORIENTATION_PORTRAIT)) {
            return Configuration.ORIENTATION_LANDSCAPE;
        } else {
            return Configuration.ORIENTATION_PORTRAIT;
        }
    }

    enum Rate {
        normal(SensorManager.SENSOR_DELAY_NORMAL),
        ui(SensorManager.SENSOR_DELAY_UI),
        game(SensorManager.SENSOR_DELAY_GAME),
        fastest(SensorManager.SENSOR_DELAY_FASTEST);

        final int nativeValue;

        Rate(int nativeValue) {
            this.nativeValue = nativeValue;
        }
    }
}
