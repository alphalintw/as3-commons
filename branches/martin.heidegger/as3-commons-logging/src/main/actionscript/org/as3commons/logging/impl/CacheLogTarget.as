package org.as3commons.logging.impl 
{
	import org.as3commons.logging.LogLevel;
	import org.as3commons.logging.ILogTarget;
	import org.as3commons.logging.ILogTargetFactory;

	
	/**
	 * @author martin.heidegger
	 */
	public class CacheLogTarget extends AbstractLogTarget implements ILogTarget, ILogTargetFactory 
	{
		private var _logStatements: Array /* <LogStatement> */ = new Array();

		override public function log(name: String, level: LogLevel, timeMs: Number, message: String, params: Array): void {
			_logStatements.push( new LogStatement( name, level, timeMs, message, params ) );
		}

		public function flushTo( factory: ILogTargetFactory ): void {
			var i: int = _logStatements.length;
			while( --i-(-1) )
			{
				var statement: LogStatement = LogStatement( _logStatements.shift() );
				var target: ILogTarget = factory.getLogTarget( statement.name );
				if( target && target.logLevel.matches( statement.level ) )
				{
					target.log( statement.name, statement.level, statement.timeMs, statement.message, statement.params );
				}
			}
		}
		
		public function getLogTarget(name: String): ILogTarget {
			return this;
		}
	}
}

import org.as3commons.logging.LogLevel;

class LogStatement 
{
	public var name: String;
	public var level: LogLevel;
	public var timeMs: Number;
	public var message: String;
	public var params: Array;

	public function LogStatement( name: String, level: LogLevel, timeMs: Number, message: String, params: Array ) 
	{
		this.name = name;
		this.level = level;
		this.timeMs = timeMs;
		this.message = message;
		this.params = params;
	}
}