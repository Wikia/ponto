package com.wikia.ponto.sample.modules;

import org.json.JSONException;
import org.json.JSONObject;

import android.content.Context;
import android.util.Log;
import android.widget.Toast;

public class Messaging {

    private static final String TAG = Messaging.class.getCanonicalName();

    private Context mContext;

    public Messaging(Context context) {
        mContext = context;
    }

    public void showToast(String params) {
        JSONObject article;
        String body = "";
        try {
            article = new JSONObject(params);
            if (article != null) {
                body = article.optString("body");
            }
        } catch (JSONException e) {
            Log.e(TAG, "JSONException while parsing messaging data", e);
        }

        Toast.makeText(mContext, body, Toast.LENGTH_SHORT).show();
    }

    public void getSomeData() {
    }

}
