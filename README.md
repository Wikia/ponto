Ponto
=====

An iOS (Obj-C), Android (Java) and WebView (JavaScript) bridge for an easy
exchange of data across web/native contextes, equiped with a transport between iframe and parent window.


Rationale
---------

Some popular HTML5-based cross-platform frameworks for mobile application development, such as [Apache PhoneGap/Cordova](http://incubator.apache.org/cordova/)
and [Trigger.IO](http://trigger.io) (but also non-HTML5 frameworks as it happens for [Appcelerator Titanium](http://www.appcelerator.com/platform/titanium-sdk/)'s WebViews) are built on the
top of inter-context communication, i.e. the JavaScript code running in the WebView is able to interact with classes/methods hosted
in the native layer to access platform capabilities not accessible using the DOM API (e.g. the device's filesystem or
camera) while the native app code is able to send information back to the WebView (e.g. the list of images in the device's
media library).

Native Android/iOS applications that implement WebViews in their flow may need, at any given point to be able to do the
same.

The aforementioned existing implementations aren't abstract enough to be extracted and reused out of the box, most of the
times their code contains quirks that make sense in the context of the specific framework making the code not generic enough
to be embedded in another application easily or without refactoring it.

For those reasons we have developed **Ponto** (*"bridge"* in Esperanto), a generic library that can do all of the above and
it's ready to be embedded in any iOS/Android app using WebViews with a simple API.


Documentation
-------------

* [WebView/Javascript documentation](https://github.com/Wikia/ponto/blob/master/web/README.md)
* Android/Java: coming soon
* iOS/Objective-C: coming soon


Credits
-------

This project exists thanks to the efforts of:

* [Artur Klajnerok](https://github.com/ArturKlajnerok) (Android/Java)
* [Federico "Lox" Lucignano](https://github.com/federico-lox) (WebView/JavaScript)
* [Grzegorz Nowicki](https://github.com/wikia-gregor) (iOS/Objective-C)
* [Jakub Olek](https://github.com/hakubo) (planning support)
* all the [contributors](https://github.com/Wikia/ponto/graphs/contributors)
