/**
 * @see  http://github.com/Wikia/ponto
 * @author Artur Klajnerok <arturk@wikia-inc.com>
 */

package com.wikia.ponto;

import java.lang.reflect.Constructor;
import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;
import java.util.HashMap;
import java.util.Map;
import java.util.UUID;

import org.json.JSONException;
import org.json.JSONObject;

import android.util.Log;
import android.webkit.JavascriptInterface;
import android.webkit.WebView;

/**
 * TODO description
 */
public class Ponto {

    public static final String TAG = "Ponto";

    /**
     * Package that contains classes which can be invoked by WebView JavaScript
     */
    private String mClassPackage;

    /**
     * WebView that will communicate with native code
     */
    private WebView mWebView;

    /**
     * Callbacks to get WebView response for a request from the native code
     */
    private Map<String, RequestCallback> mCallbacks;

    public Ponto(WebView webView, String classPackage) {
        mCallbacks = new HashMap<String, RequestCallback>();
        mClassPackage = classPackage;
        mWebView = webView;
        mWebView.getSettings().setJavaScriptEnabled(true);
        mWebView.addJavascriptInterface(new PontoProtocol(), PontoProtocol.TAG);
    }

    /**
     * Makes a request to the WebView JavaScript
     * 
     * @param className The class name to instantiate.
     * @param methodName The method name to invoke.
     * @param params The parameters that will be passed to invoked method.
     * @param callback The callback for this request
     */
    public void invoke(String className, String methodName, String params, RequestCallback callback) {
        String callbackId = UUID.randomUUID().toString();

        if (callbackId != null && callback != null) {
            mCallbacks.put(callbackId, callback);
        }

        StringBuilder requestString = new StringBuilder();
        requestString.append("javascript:Ponto.request('{")
                .append("\"target\": \"").append(className).append("\", ")
                .append("\"method\": \"").append(methodName).append("\", ")
                .append("\"params\": ").append(params).append(", ")
                .append("\"callbackId\": \"").append(callbackId).append("\"")
                .append("}');");
        mWebView.loadUrl(requestString.toString());
    }

    /**
     * Communication protocol that should be used as JavascriptInterface
     */
    private class PontoProtocol {

        public static final String TAG = "PontoProtocol";

        /**
         * Represents a completed request
         */
        private static final int RESPONSE_COMPLETE = 0;

        /**
         * Represents a failed request with errors
         */
        private static final int RESPONSE_ERROR = 1;

        /**
         * The value of String that is null
         */
        private static final String NULL_STRING = "null";

        /**
         * The value of String that is undefined
         */
        private static final String UNDEFINED_STRING = "undefined";

        /**
         * Key for message response parameter
         */
        private static final String KEY_MESSAGE = "message";

        /**
         * Called by the web layer to perform a request on native layer
         * 
         * @param execContext The JavaScript context.
         * @param className The class name to instantiate.
         * @param methodName The method name to invoke.
         * @param params The parameters that will be passed to invoked method.
         * @param callbackId The id of web callback.
         * @param async 
         */
        @JavascriptInterface
        public void request(String execContext, String className, String methodName, String params, 
                String callbackId, String async) {

            int responseType = RESPONSE_ERROR;
            JSONObject responseParams = new JSONObject();
            try {
                Class<?> cls = Class.forName(mClassPackage + className);
                Constructor<?> constructor = cls.getConstructor(android.content.Context.class);
                Object object = constructor.newInstance(mWebView.getContext());
                if (params != null && !params.equalsIgnoreCase(NULL_STRING)) {
                    Method method = cls.getDeclaredMethod(methodName, String.class);
                    method.invoke(object, params);
                } else {
                    Method method = cls.getDeclaredMethod(methodName);
                    method.invoke(object);
                }
                responseType = RESPONSE_COMPLETE;
            } catch (InstantiationException e) {
                Log.e(TAG, "InstantiationException while executing ponto request", e);
            } catch (IllegalAccessException e) {
                Log.e(TAG, "IllegalAccessException while executing ponto request", e);
            } catch (ClassNotFoundException e) {
                Log.e(TAG, "ClassNotFoundException while executing ponto request", e);
                responseParams = getClassNotFoundParams(className);
            } catch (NoSuchMethodException e) {
                Log.e(TAG, "NoSuchMethodException while executing ponto request", e);
                responseParams = getNoSuchMethodParams(methodName);
            } catch (IllegalArgumentException e) {
                Log.e(TAG, "IllegalArgumentException while executing ponto request", e);
            } catch (InvocationTargetException e) {
                Log.e(TAG, "InvocationTargetException while executing ponto request", e);
            }

            if (callbackId != null && !callbackId.equalsIgnoreCase(UNDEFINED_STRING)) {
                javascriptCallback(callbackId, responseType, responseParams.toString());
            }
        }

        /**
         * Called by the web layer when answering a request from native layer
         * 
         * @param execContext The JavaScript context.
         * @param callbackId The id of callback that should be executed.
         * @param params The parameters associated with the response.
         */
        @JavascriptInterface
        public void response(String execContext, String callbackId, String params) {

            int responseType = getResponeTypeFromParams(params);
            if (callbackId != null && !callbackId.equalsIgnoreCase(UNDEFINED_STRING) &&
                    mCallbacks.containsKey(callbackId)) {

                RequestCallback callback = mCallbacks.get(callbackId);

                switch (responseType) {
                case RESPONSE_COMPLETE:
                    callback.onSuccess();
                    break;
                case RESPONSE_ERROR:
                default:
                    callback.onError();
                    break;
                }
                mCallbacks.remove(callbackId);
            }
        }

        /**
         * Makes a response to web layer
         * 
         * @param callbackId The id of callback that should be executed.
         * @param type The response type complete/error
         * @param params The parameters associated with the response.
         */
        private void javascriptCallback(final String callbackId, final int type, final String params) {
            mWebView.post(new Runnable() {
                @Override
                public void run() {
                    StringBuilder responseString = new StringBuilder();
                    responseString.append("javascript:Ponto.response('{")
                            .append("\"type\": ").append(type).append(", ")
                            .append("\"params\": ").append(params).append(", ")
                            .append("\"callbackId\": \"").append(callbackId).append("\"")
                            .append("}');");
                    mWebView.loadUrl(responseString.toString());
                }
            });
        }

        private int getResponeTypeFromParams(String params) {
            JSONObject responseParams;
            int type = RESPONSE_COMPLETE;
            try {
                responseParams = new JSONObject(params);
                if (responseParams != null) {
                    type = responseParams.optInt("type");
                }
            } catch (JSONException e) {
                Log.e(TAG, "JSONException while parsing messaging data", e);
            }
            return type;
        }

        private JSONObject getClassNotFoundParams(String className) {
            Map<String, String> paramsMap = new HashMap<String, String>();
            paramsMap.put(KEY_MESSAGE, "Class not found");
            paramsMap.put("className", className);
            return new JSONObject(paramsMap);
        }

        private JSONObject getNoSuchMethodParams(String methodName) {
            Map<String, String> paramsMap = new HashMap<String, String>();
            paramsMap.put(KEY_MESSAGE, "Method not found");
            paramsMap.put("methodName", methodName);
            return new JSONObject(paramsMap);
        }
    }

    /**
     * Interface definition for a callbacks that are invoked 
     * when WebView responds for a request from the native code.
     */
    public interface RequestCallback {

        /**
         * Callback method to be invoked when request was successful
         */
        public void onSuccess();

        /**
         * Callback method to be invoked when request failed
         */
        public void onError();
    }
}