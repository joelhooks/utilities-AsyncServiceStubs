package org.robotlegs.utilities.async
{
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.utils.Timer;

	public class AsyncStubService
	{
		protected const ONE_ONLY_MSG :String = 
			"AsyncStubProxy: Cannot have more than one async activity running per stub";
		
		public var maxDelayMSecs :int = 8000; // 15 secs
		public var probabilityOfFault :Number = 0.0;
		public var token :Object;
		
		private var clientResultFunction :Function;
		private var clientFaultFunction :Function;
		private var asyncInProgress :Boolean = false;
		
		public function AsyncStubService(  ) 
		{
		}
		
		public function asyncAction( resultFunction :Function, faultFunction :Function =null) :void {
			if (asyncInProgress)
				throw Error ( ONE_ONLY_MSG );
			
			asyncInProgress = true;
			clientResultFunction = resultFunction;
			clientFaultFunction = faultFunction;
			
			// 0 <= Math.random() < 1
			var onCompletion :Function = calcCompletionFunction();
			var msecsDelay :Number = Math.random() * maxDelayMSecs;
			var timer :Timer = new Timer( msecsDelay, 1 );
			timer.addEventListener( TimerEvent.TIMER, onCompletion );
			timer.start();
		}
		
		protected function calcCompletionFunction() :Function {
			if ( clientFaultFunction == null ) {
				return onResult;
			}
			else if ( probabilityOfFault <= .01 ) {
				return onResult;
			}
			else if ( probabilityOfFault >= .99 ) {
				return onFault;
			}
			else if ( Math.random() <= probabilityOfFault )
				return onFault;
			else
				return onResult;
		}
		
		protected function onResult( event :Event ) :void {
			asyncInProgress = false;
			if ( token != null )
				clientResultFunction( token );
			else
				clientResultFunction();
		}
		
		protected function onFault( event :Event ) :void {
			asyncInProgress = false;
			if ( token != null )
				clientFaultFunction( token );
			else
				clientFaultFunction();
		}      
		
	}
}