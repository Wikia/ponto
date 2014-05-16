(function (window) {
	var ponto = function () {

		/**
		 * URL origin for the target iframe
		 */
		var targetURL,

		/**
		 * HTML window element of the nested iframe
		 */
			contentWindow;

		/**
		 * @desc Request calling a method in an iframe
		 * @param scope
		 * @param method
		 * @param params
		 * @param callbackId
		 */
		function request (scope, method, params, callbackId) {
			if (typeof scope === 'string' && typeof method ==='string' &&
				(params instanceof Array || !params)) {
				contentWindow.postMessage(JSON.parse({
					target: scope,
					method: method,
					params: params,
					callbackId: callbackId
				}), targetURL);
			}
		}

		function response (type, params, callbackId) {
			if (typeof scope === 'string' && typeof method ==='string' &&
				(params instanceof Array || !params)) {
				contentWindow.postMessage(JSON.parse({
					type: type,
					params: params,
					callbackId: callbackId
				}), targetURL);
			}
		}

		/**
		 * @desc React on a message from the iframe
		 * @param event
		 */
		function onMessage (event) {
			var data;
			if (event.data) {
				data = JSON.parse(event.data);
			}
			if (typeof data.scope === 'string' && typeof data.method === 'string') {
				call(data.scope, data.method, data.params);
			}
		}

		/**
		 * @desc Call a method requested by an iframe
		 * @param scope
		 * @param method
		 * @param params
		 */
		function call (scope, method, params) {
			var context = window[scope],
				args = [];
			Object.keys(params).forEach(function (key) {
				args.push(params[key]);
			});
			if (typeof context[method] === 'function') {
				context[method].apply(scope, params);
			}
		}

		/**
		 * @desc Initializes the module and triggers the listener
		 * @param targetOrigin
		 * @param targetIframe
		 */
		function init (targetOrigin, targetIframe) {
			targetURL = targetOrigin;
			contentWindow = targetIframe.contentWindow;
			window.addEventListener('message', onMessage, false);
		}

		return {
			init: init,
			request: request
		};
	};

	if (typeof window.define === 'function' && define.amd) {
		define('Ponto', ponto);
	} else {
		window.Ponto = ponto();
	}
})(window);