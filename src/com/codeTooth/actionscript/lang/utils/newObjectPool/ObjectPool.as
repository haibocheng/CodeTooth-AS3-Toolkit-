package com.codeTooth.actionscript.lang.utils.newObjectPool
{
	import com.codeTooth.actionscript.lang.utils.destroy.DestroyUtil;
	import com.codeTooth.actionscript.lang.utils.destroy.IDestroy;
	
	import flash.utils.Dictionary;
	import com.codeTooth.actionscript.lang.exceptions.NoSuchObjectException;
	import com.codeTooth.actionscript.lang.exceptions.IllegalOperationException;

	/**
	 * 对象池。
	 */
	public class ObjectPool implements IDestroy
	{
		// 各种对象池
		private var _pools:Dictionary/*key type, value Pool*/ = null;
		private var _poolsAlias:Dictionary/*key alias, value Pool*/ = null; 
		
		public function ObjectPool():void
		{
			_pools = new Dictionary();
			_poolsAlias = new Dictionary();
		}
			
		/**
		 * 创建一个对象池
		 * 
		 * @param type 对象池的类型
		 * @param alias 对象池的别名
		 * @param invokeAfterPut 在放入一个对象之后，对此对象调用的函数。原型func(obj:type):void
		 * @param invokeBeforeGet 在取出一个对象之前，对此对象调用的函数。原型func(obj:type):void
		 * @param invokeDisposeObject 销毁对象池时，对此对象调用的函数。原型func(obj:type):void
		 * 
		 * @return 返回是否成功创建了对象池。如果已经存在了返回false
		 */
		public function createPool(type:Class, alias:Object = null, invokeAfterPut:Function = null, invokeBeforeGet:Function = null, invokeDisposeObject:Function = null):void
		{
			if(containsPool(type))
			{
				throw new IllegalOperationException("Has contains the pool \"" + type + "\"");
			}
			
			var pool:Pool = new Pool(type, alias, invokeAfterPut, invokeBeforeGet, invokeDisposeObject);
			_pools[type] = pool;
			_poolsAlias[alias] = pool;
		}
		
		/**
		 * 向指定类型的对象池放入一个对象。
		 * 
		 * @param instance 
		 * @param type 
		 * @param alias 
		 */
		public function putObject(instance:Object, type:Class, alias:Object = null):void
		{
			(type == null ? getPoolByAlias(alias) : getPool(type)).putObject(instance);
		}
		
		/**
		 * 从指定类型的池中取出一个对象
		 * 
		 * @param type
		 * @param alias 
		 * 
		 * @return 返回取出的对象。如果池已空，那么会new一个新对象返回。
		 */
		public function getObject(type:Class, alias:Object = null):*
		{
			return (type == null ? getPoolByAlias(alias) : getPool(type)).getObject();
		}
		
		/**
		 * 从指定类型的池中取出一个对象。可以指定构造函数的参数。
		 * 
		 * @param type
		 * @param alias
		 * 
		 * @return 返回取出的对象。如果池已空，那么会new一个新对象返回。
		 */
		public function getObjectByArgs(type:Class, alias:Object = null, ...args):*
		{
			return (type == null ? getPoolByAlias(alias) : getPool(type)).getObject(args);
		}
		
		/**
		 * 判断是否存在指定类型的池
		 * 
		 * @param type
		 * @return 
		 */
		public function containsPool(type:Class):Boolean
		{
			return _pools[type] != null;
		}
		
		/**
		 * 判断是否包含指定别名的池
		 * 
		 * @param alias
		 * @return 
		 */
		public function containsPoolByAlias(alias:Object):Boolean
		{
			return _poolsAlias[alias] != null;
		}

		/**
		 * 重置指定对象池中的和释放对象相关的数据。
		 * 释放对象相关的数据将被重新开始计数。
		 * 所谓“释放对象相关的数据”就是“freePoolObjectsByInactiveTime”和“freePoolObjectsByUsedTimes”这两个方法中所指的“活跃度”和“使用次数”。
		 * 
		 * @param poolType
		 * @param alias
		 */
		public function resetPoolObjectsDataForFree(poolType:Class, alias:Object = null):void
		{
			(poolType == null ? getPoolByAlias(alias) : getPool(poolType)).resetObjectsDataForFree();
		}
		
		/**
		 * 释放指定对象池中的对象实例。
		 * 
		 * @param poolType
		 * @param inactiveTime 指定一个时间段（毫秒）。比如传入1000，就表示在过去的1000毫秒内，如果对象没有任何的活跃度，就将被从池中释放。
		 * 所谓活跃度，就是被put入池，或者，被从池中get。
		 * @param alias
		 */
		public function freePoolObjectsByInactiveTime(poolType:Class, inactiveTime:int, alias:Object = null):void
		{
			(poolType == null ? getPoolByAlias(alias) : getPool(poolType)).freeObjectsByInactiveTime(inactiveTime);
		}
		
		/**
		 * 释放指定对象池中的对象实例。
		 * 
		 * @param poolType
		 * @param usedTimes 指定一个使用次数。比如传入10，就表示如果一个对象被使用的次数不到10次，那就会被从池中释放。
		 * 所谓被使用的次数，就是被从池中get的次数。
		 * @param alias
		 */
		public function freePoolObjectsByUsedTimes(poolType:Class, usedTimes:int, alias:Object = null):void
		{
			(poolType == null ? getPoolByAlias(alias) : getPool(poolType)).freeObjectsByUsedTimes(usedTimes);
		}
		
		/**
		 * 获得指定池中一共有多少个对象实例（包括当前可使用的和正在被使用的）
		 * 
		 * @param poolType
		 * @param alias
		 * @return 
		 */
		public function getPoolSize(poolType:Class, alias:Object = null):int
		{
			return (poolType == null ? getPoolByAlias(alias) : getPool(poolType)).size;
		}
		
		/**
		 * 获得指定池中一共有多少个当前正在被使用的实例对象
		 * 
		 * @param poolType
		 * @param alias
		 * @return 
		 */
		public function getPoolSizeInUsing(poolType:Class, alias:Object = null):int
		{
			return (poolType == null ? getPoolByAlias(alias) : getPool(poolType)).sizeInUsing;
		}
		
		/**
		 * 获得指定池中一共有多少个当前可使用的实例对象
		 * 
		 * @param poolType
		 * @param alias
		 * @return 
		 */
		public function getPoolSizeFree(poolType:Class, alias:Object = null):int
		{
			return (poolType == null ? getPoolByAlias(alias) : getPool(poolType)).sizeFree;
		}
		
		/**
		 * 销毁指定类型的对象池
		 * 
		 * @param type
		 */
		public function destroyPool(type:Class):void
		{
			if(containsPool(type))
			{
				var pool:Pool = getPool(type);
				delete _pools[pool.getType()];
				delete _poolsAlias[pool.getAlias()];
				pool.destroy();
			}
		}
		
		/**
		 * 销毁指定别名的对象池
		 * 
		 * @param type
		 */
		public function destroyPoolByAlias(alias:Object):void
		{
			if(containsPoolByAlias(alias))
			{
				var pool:Pool = getPoolByAlias(alias);
				delete _pools[pool.getType()];
				delete _poolsAlias[pool.getAlias()];
				pool.destroy();
			}
		}
		
		/**
		 * @inheritDoc
		 */
		public function destroy():void
		{
			if(_pools != null)
			{
				DestroyUtil.destroyMap(_pools);
				_pools = null;
				DestroyUtil.breakMap(_poolsAlias);
				_poolsAlias = null;
			}
		}
		
		private function getPool(type:Class):Pool
		{
			var pool:Pool = _pools[type];
			if(pool == null)
			{
				throw new NoSuchObjectException("Cannot find the pool \"" + type + "\"");
			}
			return pool;
		}
		
		private function getPoolByAlias(alias:Object):Pool
		{
			var pool:Pool = _poolsAlias[alias];
			if(pool == null)
			{
				throw new NoSuchObjectException("Cannot find the pool, alias \"" + alias + "\"");
			}
			return pool;
		}
	}
}