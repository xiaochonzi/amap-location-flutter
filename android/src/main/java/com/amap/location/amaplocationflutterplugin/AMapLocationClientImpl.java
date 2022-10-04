package com.amap.location.amaplocationflutterplugin;

import android.content.Context;
import android.util.Log;

import com.amap.api.location.AMapLocation;
import com.amap.api.location.AMapLocationClient;
import com.amap.api.location.AMapLocationClientOption;
import com.amap.api.location.AMapLocationListener;

import java.util.Map;

import io.flutter.plugin.common.EventChannel;

/**
 * @author whm
 * @date 2020-04-16 15:49
 * @mail hongming.whm@alibaba-inc.com
 */
public class AMapLocationClientImpl implements AMapLocationListener {

    private static final String TAG = AMapLocationClientImpl.class.getName();
    private Context mContext;
    private AMapLocationClientOption locationOption = new AMapLocationClientOption();
    private AMapLocationClient locationClient = null;
    private EventChannel.EventSink mEventSink;

    private String mPluginKey;

    public AMapLocationClientImpl(Context context, String pluginKey, EventChannel.EventSink eventSink) {
        mContext = context;
        mPluginKey = pluginKey;
        mEventSink = eventSink;
        if (null == locationClient) {
            try {
                locationClient = new AMapLocationClient(context);
            } catch (Exception e) {
                e.printStackTrace();
            }
        }
    }

    /**
     * 开始定位
     */
    public void startLocation() {
        Log.d(TAG, "startLocation");
        if (null == locationClient) {
            try {
                locationClient = new AMapLocationClient(mContext);
            } catch (Exception e) {
                e.printStackTrace();
            }
        }
        if (null != locationOption) {
            locationClient.setLocationOption(locationOption);
        }
        locationClient.setLocationListener(this);
        locationClient.startLocation();
    }


    /**
     * 停止定位
     */
    public void stopLocation() {
        Log.d(TAG, "stopLocation");
        if (null != locationClient) {
            locationClient.stopLocation();
            locationClient.onDestroy();
            locationClient = null;
        }
    }

    public void destroy() {
        Log.d(TAG, "destroy");
        if (null != locationClient) {
            locationClient.onDestroy();
            locationClient = null;
        }
    }

    /**
     * 定位回调
     *
     * @param location
     */
    @Override
    public void onLocationChanged(AMapLocation location) {
        if (null == mEventSink) {
            return;
        }
        Map<String, Object> result = Utils.buildLocationResultMap(location);
        result.put("pluginKey", mPluginKey);
        mEventSink.success(result);
    }


    /**
     * 设置定位参数
     *
     * @param optionMap
     */
    public void setLocationOption(Map optionMap) {
        Log.d(TAG, "setLocationOption");
        if (null == locationOption) {
            locationOption = new AMapLocationClientOption();
        }
        if (optionMap.containsKey("locationInterval")) {
            locationOption.setInterval(((Integer) optionMap.get("locationInterval")).longValue());
        }
        if (optionMap.containsKey("needAddress")) {
            locationOption.setNeedAddress((boolean) optionMap.get("needAddress"));
        }
        if (optionMap.containsKey("locationMode")) {
            try {
                locationOption.setLocationMode(AMapLocationClientOption.AMapLocationMode.values()[(int) optionMap.get("locationMode")]);
            } catch (Throwable e) {
            }
        }
        if (optionMap.containsKey("geoLanguage")) {
            locationOption.setGeoLanguage(AMapLocationClientOption.GeoLanguage.values()[(int) optionMap.get("geoLanguage")]);
        }
        if (optionMap.containsKey("onceLocation")) {
            locationOption.setOnceLocation((boolean) optionMap.get("onceLocation"));
        }
        if (null != locationClient) {
            locationClient.setLocationOption(locationOption);
        }
    }
}
