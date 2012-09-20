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
			this.params = JSON.stringify(params);
			this.completeCallback = null;
			this.errorCallback = null;
		}

		/**
		 * Runs a prepared request in the native layer
		 *
		 * @param {Function} completeCallback [Optional] A function to call on completion
		 * @param {Function} errorCallback [Optional] A function to call in case of error
		 */
		Request.prototype.run = function (completeCallback, errorCallback) {
			if (completeCallback) {
				this.completeCallback = completeCallback;
			}

			if (errorCallback) {
				this.errorCallback = errorCallback;
			}

			//Platforms that can expose native mehtods in the
			//WebView context will provide this method (e.g. Android)
			if (context.PontoNativeTransfer) {
				context.PontoNativeTransfer(this.target, this.method, this.params);
			} else {
				//the only other chance is for the native layer to register
				//a custom protocol for communicating with the webview (e.g. iOS)
				context.location.href = encodeURI(
					'ponto:///target:' + this.target +
						'/method:' + this.method +
						'/params:' + this.params
				);
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
			(new Request(target, method, params)).run(completeCallback, errorCallback);
		}

		return {
			Request: Request,
			sendRequest: sendRequest
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