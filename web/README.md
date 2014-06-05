Ponto, WebView implementation [![Code Climate](https://codeclimate.com/github/Wikia/ponto.png)](https://codeclimate.com/github/Wikia/ponto)
=============================

This is the root folder for the WebView (JavaScript) implementation.


Examples
--------

**To invoke a method in the native layer** from the WebView use:

```javascript
Ponto.invoke('ClassName', 'methodName', {param1:1, param2:2}, function(d){/*completed*/}, function(e){/*error*/});
```

The last three parameters (parameters, success/failure callbacks) are optional.

**To invoke a method in the WebView from the native layer**  use:

```java
mWebView.loadUrl("javascript:Ponto.request(\"{\\\"target\\\": \\\"TypeOrModuleName\\\", \\\"method\\\": \\\"methodName\\\", \\\"params\\\":{\\\"a\\\":1}, \\\"callbackId\\\": \\\"callbackId\\\"}\")");
```

```objective-c
[mWebView stringByEvaluatingJavaScriptFromString:@"Ponto.request(\"{\\\"target\\\": \\\"TypeOrModuleName\\\", \\\"method\\\": \\\"methodName\\\", \\\"params\\\":{\\\"a\\\":1}, \\\"callbackId\\\": \\\"callbackId\\\"}\";"];
```

Ponto.request accept a JSON-encoded string of an hash/dictionary containing the required data; *params* and *callbackId* are optional.

**To invoke a callback in the WebView from the native layer** after the method invoked by the WebView has completed or resulted in an error use:

```java
mWebView.loadUrl("javascript:Ponto.response(\"{\\\"type\\\": 0, \\\"params\\\":{\\\"a\\\":1}, \\\"callbackId\\\": \\\"callbackId\\\"}\");");
```

```objective-c
[mWebView stringByEvaluatingJavaScriptFromString:@"Ponto.response(\"{\\\"type\\\": 0, \\\"params\\\":{\\\"a\\\":1}, \\\"callbackId\\\": \\\"callbackId\\\"}\");"];
```

Ponto.response accept a JSON-encoded string of an hash/dictionary containing the required data; *params* is optional and *type* is either 0 (completed successfully) or 1 (error occurred).

Iframe communication
--------
Ponto can be used as a message transport protocol between a parent HTML window and an iframe - to enable this mode it is required to explicitly override the default, native protocol, uing setTarget method.

For parent window, this method gets two params, target indicator and targeted iframe's content window.
```javascript
Ponto.setTarget(Ponto.TARGET_IFRAME, document.querySelector('iframe').contentWindow);
```
In the iframe, it's just enough to set the target indicator as the iframe's parent.
```javascript
Ponto.setTarget(Ponto.TARGET_IFRAME_PARENT);
```

Ponto by default performs a synchronous operation and immediately responds with a result. If there is a need to perform an asynchronous operation on the second javascript side, it needs to be indicated by using 'async' flag in the invoke method:
For parent window, this method gets two params, target indicator and targeted iframe's content window.
```javascript
Ponto.invoke(scope, method, params, successCallback, errorCallback, async);
```

After such invocation, the targeted method is triggered with two arguments: params object and callbackId, and is able to respond to the invocation by using the respond method:
For parent window, this method gets two params, target indicator and targeted iframe's content window.
```javascript
function targetedFunction(params, callbackId) {
	Ponto.respond(params, callbackId);
}
```
