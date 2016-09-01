package com.wikia.ponto.sample.modules;

import java.util.HashMap;
import java.util.Map;

import org.json.JSONException;
import org.json.JSONObject;

import android.content.Context;
import android.content.Intent;
import android.util.Log;
import android.widget.Toast;

public class Messaging {

    private static final String TAG = Messaging.class.getCanonicalName();

    private Context mContext;

    public Messaging(Context context) {
        mContext = context;
    }

    public void showToast(String params) {
        String body = "";
        try {
            JSONObject message = new JSONObject(params);
            if (message != null) {
                body = message.optString("body");
            }
        } catch (JSONException e) {
            Log.e(TAG, "JSONException while parsing messaging data", e);
        }

        Toast.makeText(mContext, body, Toast.LENGTH_SHORT).show();
    }

    public void sendEmail(String params) {
        String email = "";
        String subject = "";
        String body = "";
        try {
            JSONObject message = new JSONObject(params);
            if (message != null) {
                email = message.optString("email");
                subject = message.optString("subject");
                body = message.optString("body");
            }
        } catch (JSONException e) {
            Log.e(TAG, "JSONException while parsing email data", e);
        }

        Intent emailIntent = new Intent(Intent.ACTION_SEND);
        emailIntent.putExtra(Intent.EXTRA_EMAIL, new String[] {email});
        emailIntent.putExtra(Intent.EXTRA_SUBJECT, subject );
        emailIntent.putExtra(Intent.EXTRA_TEXT, body );
        emailIntent.setType("plain/text");
        mContext.startActivity(Intent.createChooser(emailIntent, subject));
    }

    public JSONObject getSomeData() {
        Log.i("TAG", new Object() {}.getClass().getEnclosingMethod().getName());
        Map<String, String> paramsMap = new HashMap<String, String>();
        paramsMap.put("msg", "this is some data");
        return new JSONObject(paramsMap);
    }

}
