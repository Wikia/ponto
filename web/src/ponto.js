/**
 * Ponto JavaScript implementation for WebViews
 *
 * @see  http://github.com/wikia-apps/Ponto
 *
 * @author Federico "Lox" Lucignano <federico@wikia-inc.com>
 */

/*global define*/
(function (context) {
	'use strict';

	/**
	 * module constructor
	 *
	 * @private
	 *
	 * @return {Object} The module reference
	 */
	function ponto() {
		var
			/**
			 * [Constant] Represents a completed request
			 *
			 * @private
			 *
			 * @type {Number}
			 *
			 * @see  Ponto.ping
			 */
			RESPONSE_COMPLETE = 0,

			/**
			 * [Constant] Represents a failed request with errors
			 *
			 * @private
			 *
			 * @type {Number}
			 *
			 * @see  Ponto.ping
			 */
			RESPONSE_ERROR = 1,

			/**
			 * Registry for complete/error callbacks
			 *
			 * @private
			 *
			 * @type {Object}
			 */
			callbacks = {};

		/**
		 * Request constructor
		 *
		 * @public
		 *
		 * @param {String} target The target class name
		 * @param {String} method The method to call
		 * @param {Object} params [Optional] An hash of
		 * the parameters to pass to the method
		 */
		function Request(target, method, params) {
			this.target = target;
			this.method = method;
			this.params = (params) ? JSON.stringify(params) : undefined;
			this.completeCallback = null;
			this.errorCallback = null;
		}

		/**
		 * Runs a prepared request in the native layer
		 *
		 * @param {Function} completeCallback [Optional] A function to call on completion
		 * @param {Function} errorCallback [Optional] A function to call in case of error
		 */
		Request.prototype.send = function (completeCallback, errorCallback) {
			var registerCallbacks = false,
				callbackId = null;

			if (completeCallback instanceof Function) {
				registerCallbacks = true;
				this.completeCallback = completeCallback;
			}

			if (errorCallback instanceof Function) {
				registerCallbacks = true;
				this.errorCallback = errorCallback;
			}

			if (registerCallbacks) {
				callbackId = 'cbid_' + Math.random().toString().substr(2);
				callbacks[callbackId] = {complete: completeCallback, error: errorCallback};
			}

			//Platforms that can expose native mehtods in the
			//WebView context will provide this method (e.g. Android)
			if (context.PontoNativeTransfer) {
				context.PontoNativeTransfer(this.target, this.method, this.params, callbackId);
			} else {
				//the only other chance is for the native layer to register
				//a custom protocol for communicating with the webview (e.g. iOS)
				context.location.href = 'ponto:///request?target=' + encodeURIComponent(this.target) +
					'&method=' + encodeURIComponent(this.method) +
					((this.params) ? '&params=' + encodeURIComponent(this.params) : '') +
					((registerCallbacks) ? '&callbackId=' + encodeURIComponent(callbackId) : '');
			}
		};

		/**
		 * Simple method to prepare and send a request to the native layer
		 *
		 * @public
		 *
		 * @param {String} target The target class name
		 * @param {String} method The method to call
		 * @param {Object} params [Optional] An hash of
		 * the parameters to pass to the method
		 * @param {Function} completeCallback [Optional] A function to call on completion
		 * @param {Function} errorCallback [Optional] A function to call in case of error
		 *
		 * @see Request
		 */
		function sendRequest(target, method, params, completeCallback, errorCallback) {
			(new Request(target, method, params)).send(completeCallback, errorCallback);
		}

		/**
		 * Function called by the native layer when responding to a Request
		 *
		 * @public
		 *
		 * @param {String} callbackId The id stored in the callbacks registry by Request.send
		 * @param {Number} responseType The type of response,
		 * one of Ponto.RESPONSE_COMPLETE or Ponto.RESPONSE_ERROR
		 * @param {String} params A JSON-encoded string representing
		 * an hash with the parameters for the callback
		 */
		function ping(callbackId, responseType, params) {
			var cbGroup = callbacks[callbackId],
				callback;

			if (cbGroup) {
				params = (params) ? JSON.parse(params) : undefined;

				switch (responseType) {
				case RESPONSE_COMPLETE:
					callback = cbGroup.complete;
					break;
				case RESPONSE_ERROR:
					callback = cbGroup.error;
					break;
				}

				if (callback) {
					callback(params);
				}

				delete callbacks[callbackId];
			}
		}

		return {
			Request: Request,
			sendRequest: sendRequest,
			ping: ping
		};
	}

	//make module available in the global scope
	context.Ponto = ponto();

	//if AMD available then register also as a module
	//to allow easy usage in other AMD modules
	if (typeof define !== 'undefined' && define.amd) {
		define('ponto', context.Ponto);
	}
}(this));