/*
 * http://www.brianlegros.com/blog/2009/02/21/using-stubs-for-httpservice-and-remoteobject-in-flex/
 * this was taken from the above URL.
*/
package net.digitalprimates.fluint.stubs
{
	import flash.events.TimerEvent;
	import flash.utils.Dictionary;
	import flash.utils.Timer;
	
	import mx.rpc.AsyncToken;
	import mx.rpc.Fault;
	import mx.rpc.IResponder;
	import mx.rpc.events.AbstractEvent;
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	import mx.rpc.http.HTTPService;
	
	public class HTTPServiceStub extends HTTPService
	{
		private var _resultData : Dictionary;
		
		//default num of milliseconds to wait before dispatching events
		//don't put too low otherwise your token responders may not be registered
		public var delay : Number = 1000;
		
		private var token:AsyncToken;
		private var parameters:Object;
		
		public function HTTPServiceStub(rootURL : String = null, destination : String = null)
		{
			super(rootURL, destination);
			_resultData = new Dictionary();
		}
		
		public function result(parameters : Object, data : *) : void
		{
			_resultData[parameters] = data;
		}
		
		public function fault(parameters : Object, code : String, string : String, detail : String) : void
		{
			var fault : Fault = new Fault(code, string, detail);
			this.result(parameters, fault);
		}
		
		override public function send(parameters : Object = null) : AsyncToken
		{
			return configureResponseTimer(parameters);
		}
		
		private function configureResponseTimer(parameters : Object) : AsyncToken
		{
			token = new AsyncToken(null);
			this.parameters = parameters;
			
			//use a time to give time for the caller to map responders to the asyncToken
			var timer : Timer = new Timer(this.delay, 1);
			
			timer.addEventListener(	TimerEvent.TIMER_COMPLETE, handleTimer);
			
			timer.start();
			
			return token;
		}
		
		private function handleTimer(event:TimerEvent):void
		{
			event.target.removeEventListener(TimerEvent.TIMER_COMPLETE, handleTimer);
			//loop over all responders to emulate a successful call being made
			for each(var responder : IResponder in token.responders)
			{
				var response : Function = isFaultCall(parameters) ? responder.fault : responder.result;
				response.apply(null, [generateEvent(parameters)]);
			}
			
			//dispatch event to service just in case token wasn't used
			dispatchEvent(generateEvent(parameters));	
			
			this.token = null;
			this.parameters = null;
		}
		
		private function isFaultCall(parameters : Object) : Boolean
		{
			return (_resultData[parameters] is Fault);
		}
		
		private function generateEvent(parameters : Object) : AbstractEvent
		{
			if(isFaultCall(parameters))
			{
				return new FaultEvent(FaultEvent.FAULT, false, true, _resultData[parameters]);
			}
			else
			{
				return new ResultEvent(ResultEvent.RESULT, false, true, _resultData[parameters]);
			}
		}
	}
}