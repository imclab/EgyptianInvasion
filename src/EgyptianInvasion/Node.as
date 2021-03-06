package EgyptianInvasion
{
	import assets.flashingNode;
	
	import flash.display.*;
	import flash.events.*;
	import flash.utils.Timer;
	
	//	import mx.*;
	
	public class Node extends Sprite {
		
		protected var canvas:Stage;
		protected var nodes:Array;
		protected var selected:Boolean;
		protected var currRad:Number;
		protected var radiusInc:Boolean;
		protected var time:Timer;
		protected var placed:Boolean;
		protected var isValid:Boolean;
		protected var size:Number;
		protected var validAngles:Array;
		protected var isConnectable:Boolean;
		protected var sup:NodeManager;
		protected var triggerNode:Node; //node that this one will trigger.
		protected var isTrigPlace:Boolean;//utility variable, so we can tell when the player wants to make a trigger connection
										//between nodes.
		protected var goldWithin:Number;
		protected var value:Number;
		protected var pathVal:Number;
		
		private var nodeImage:flashingNode; // normal, selected, placable, unplacable
		private var drawing:Boolean;
		
		// -- Reinforcement Learning --------------
		protected var qValuesNoGold:Array;	// Q values associated with taking a particular path.  must be same length as nodes array
		protected var qValuesWithGold:Array; // Q values associated with taking a particular path when the enemy has gold
		protected static var initialQ:Number = 5.0;	// The initial Q values
		protected static var lambda:Number = 0.9;	// Temporal Difference learning discount rate i.e. TD(λ)
		protected static var backupSteps:int = 20;	// Backup steps for TD(λ) learning
		protected var learningRate:Number = 0.8;		// alpha in the Q-learning equations
		// ----------------------------------------
		
		public function Node(nodex:Number, nodey:Number, canvas:Stage, refup:NodeManager) {
			//this.cacheAsBitmap = true;
			drawing = true;
			goldWithin = 0;
			nodeImage = new flashingNode();
			nodeImage.stop();
			addChild(nodeImage);
			nodeImage.gotoAndStop("normal");
			value = 0;
			pathVal = .02;
			this.isConnectable = true;
			isTrigPlace = false;
			sup = refup;
			this.blendMode = BlendMode.LAYER;
			this.canvas = canvas;
			x = nodex;
			y = nodey;
			size = 2;
			time = new Timer(100);
			currRad = size;
			radiusInc = false;
			//			canv.addEventListener(MouseEvent.MOUSE_DOWN, mouseDownListener);
			//			canv.addEventListener(MouseEvent.MOUSE_UP, mouseUpListener);
			canvas.addEventListener(MouseEvent.MOUSE_MOVE, mouseMoveListener);
			time.addEventListener(TimerEvent.TIMER,TimeListener);
			time.start();
			nodes = new Array();
			qValuesNoGold = new Array();
			qValuesWithGold = new Array();
		}
		
		// 	-- RL -- Updates the Q value of a path decision combining it with the previous acording to learning rate (alpha)
		public function updateQValue(enemyType:int, visitedNodes:Array, hasGold:Array, actionIndices:Array, value:Number):void {
			var newQ:Number;
			if(hasGold[hasGold.length-1]) {
				newQ = qValuesWithGold[actionIndices[actionIndices.length-1]][enemyType] * (1.0 - learningRate) + value * (learningRate);
			}
			else {
				newQ = qValuesNoGold[actionIndices[actionIndices.length-1]][enemyType] * (1.0 - learningRate) + value * (learningRate);
			}
			
			// Backup this update according to TD(lambda) starting with this Node (visitedNodes.length - 1 is current node)
			var numBackups:int = Math.min(Node.backupSteps,actionIndices.length);	// Determine number of TD(λ) backups to perform
			for(var i:int = 0; i < numBackups; i++) {
				var currentNode:Node = (visitedNodes[visitedNodes.length -1 -i] as Node);
				var prevQ:Number;
				var updateQ:Number;
				var iNum:Number = (i as Number);	// Cast to a Number so Math.pow doesn't return NaN
				if(hasGold[hasGold.length -1 -i]) {	// Has Gold Update
					prevQ = currentNode.qValuesWithGold[actionIndices[actionIndices.length -1 -i]][enemyType];
					updateQ = Math.pow(lambda,iNum) * newQ + (1.0 - Math.pow(lambda,iNum)) * prevQ;
					currentNode.qValuesWithGold[actionIndices[actionIndices.length -1 -i]][enemyType] = updateQ;
				}
				else {	// No gold update
					prevQ = currentNode.qValuesNoGold[actionIndices[actionIndices.length -1 -i]][enemyType];
					updateQ = Math.pow(lambda,iNum) * newQ + (1.0 - Math.pow(lambda,iNum)) * prevQ;
					currentNode.qValuesNoGold[actionIndices[actionIndices.length -1 -i]][enemyType] = updateQ;
				}
			}
		}
		
		public function getQValue(enemyType:int, hasGold:Boolean, actionIndex:int):Number {
			if(hasGold) {
				return qValuesWithGold[actionIndex][enemyType];
			}
			else {
				return qValuesNoGold[actionIndex][enemyType];
			}
		}
		// -------------------
		
		
		//returns the cost of placing paths, per unit length
		public function getPathCost():Number{
			return pathVal;
		}
		//returns the cost of this node to place
		public function getNodeCost():Number{
			return value;
		}
		//returns the total cost to place, both path and node cost
		public function getCostToPlace(fromX:Number, fromY:Number):Number{
			return ((pathVal*(Math.sqrt(Math.pow(x - fromX, 2) + Math.pow(y - fromY,2)))) + value);
		}
		//returns whether or not this node is allowed to be connected to
		public function connectable():Boolean {
			return isConnectable;
		}
		// returns where the path should hook to, in x
		public function drawToPointX():Number {
			return x;
		}
		// returns where the path should hook to, in y
		public function drawToPointY():Number {
			return y;	
		}
		
		// Determines if the enemy should be affected based on its current position (if it is within the range of the node)
		// Called by the Enemy class
		public function processEnemy(guy:Enemy):Boolean {
			
			if(Math.sqrt(Math.pow(guy.x - x,2) + Math.pow(guy.y - y, 2)) < size)
			{
				if(triggerNode != null && !guy.isDead())
				{
					triggerNode.trigger();
				}
				if(!guy.isDead() &&this.goldWithin > 0 )
					goldWithin = guy.giveGold(goldWithin);
				return true;
			}
			else
			{
				return false;
			}
		}
		
		public function setSelected( select:Boolean):void {
			selected = select;
			if(nodeImage != null)
			{
				if(select)
					nodeImage.gotoAndStop("selected");
				else
					nodeImage.gotoAndStop("normal");
			}
		}
		//places the node, and performs appropriate graphics operations
		public function setPlaced ( place:Boolean):void	{
			placed = place;
			if(nodeImage != null)
			{
				if(placed)
				{
					nodeImage.gotoAndStop("normal");
				}
				else
				{
					if(isValid)
						nodeImage.gotoAndStop("placable");
					else
						nodeImage.gotoAndStop("unplacable");
				}
			}
			
		}
		
		public function isPlaced () :Boolean
		{
			return placed;
		}
		public function getImpassible(): Boolean
		{
			return false;
		}
		//triggers the node, if there is anything to d
		public function trigger():void
		{
			
		}
		public function stopDraw():void
		{
			if(drawing)
			{
				this.removeChild(nodeImage);
				drawing = false;
			}
		}
		public function startDraw():void
		{
			if(drawing)
			{
				this.addChild(nodeImage);
				drawing = false;
			}
		}
		public function setValid ( val:Boolean):void
		{
			isValid = val;
			if(nodeImage != null)
			{
				if(val)
					nodeImage.gotoAndStop("placable");
				else
					nodeImage.gotoAndStop("unplacable");
			}
		}
		public function getSize():Number
		{
			return size;
		}
		public function addGold(gold:Number):void {
			this.goldWithin += gold;
		}
		
		public function onPlaced(sup:NodeManager):void {
			(parent as NodeManager).getSelected().setSelected(false);
			this.setSelected(true);
			(parent as NodeManager).setSelected(this);
		}
		
		public function getPossibleAngle(nodeIn:Node):Boolean {
			var relx0:Number = (nodeIn.x - x)/Math.sqrt(Math.pow(nodeIn.x - x,2) + Math.pow(nodeIn.y - y,2));
			var rely0:Number = (nodeIn.y - y)/Math.sqrt(Math.pow(nodeIn.x - x,2) + Math.pow(nodeIn.y - y,2));
			for(var i:Number = 0; i < nodes.length;i++)
			{
				var relx1:Number = ((nodes[i] as Node).x - x)/Math.sqrt(Math.pow((nodes[i] as Node).x - x,2) + Math.pow((nodes[i] as Node).y - y,2));
				var rely1:Number = ((nodes[i] as Node).y - y)/Math.sqrt(Math.pow((nodes[i] as Node).x - x,2) + Math.pow((nodes[i] as Node).y - y,2));
				if(Math.acos(relx0 * relx1 + rely0* rely1) < Math.PI/6
					&& !(nodeIn == nodes[i] as Node))
				{
					return true;
				}
			}
	/*		if(validAngles != null && validAngles.length >0)
			{
				var isValidAngle:Boolean = false;
				for(var j :Number = 0; j < validAngles.length; j +=2)
				{
					if(Math.acos(relx0) > validAngles[j] && Math.acos(relx0) < validAngles[j+1])
						isValidAngle = true;
				}
				if(isValidAngle)
					return false;
			}
			else
				return false;*/
			return false;
		}
		// displays the faded version of the node
		protected function displayFaded():void {
			graphics.clear();
			if(radiusInc)
				currRad+=.1;
			else
				currRad-=.1;
			if(currRad <size)
				radiusInc = true;
			else if (currRad >size+5)
				radiusInc = false;
			
			
			if(!isValid && !this.isTrigPlace)
				graphics.beginFill(0xFF0000,1);
			if(isValid && !this.isTrigPlace)
				graphics.beginFill(0x00FFEE,1);
			if(!this.isTrigPlace)
			{
				graphics.drawCircle(0,0,size);
				graphics.endFill();
				graphics.lineStyle(1,0xFF2000,1);
			}
			else if(isValid)
				graphics.lineStyle(1,0x00FF00,.8);
			else
				graphics.lineStyle(1, 0x0FF000,.8)
			if(selected)
				graphics.lineStyle(1.5, 0x00FF00,.5);
			graphics.drawCircle(0,0,currRad);
			if(this.triggerNode != null)
			{
				graphics.moveTo(0,0);
				graphics.lineStyle(1, 0x00FF00);
			
				graphics.lineTo(triggerNode.drawToPointX(),triggerNode.drawToPointY());
				graphics.moveTo(0,0);
			}
			blendMode = BlendMode.ADD;
		}	
		//displays the solid version of the node
		protected function displaySolid():void {
			graphics.clear();
			
			if(radiusInc)
				currRad+=.1;
			else
				currRad-=.1;
			if(currRad <size)
				radiusInc = true;
			else if (currRad >size+5)
				radiusInc = false;
			graphics.beginFill(0xFF0000);
			graphics.drawCircle(0,0,size);
			graphics.endFill();
			
			graphics.lineStyle(1,0xFF2000);
			if(selected)
				graphics.lineStyle(1.5, 0x00FF00);
			graphics.drawCircle(0,0,currRad);
			blendMode = BlendMode.NORMAL;
			if(this.triggerNode != null)
			{
				graphics.moveTo(0,0);
				graphics.lineStyle(1, 0x00FF00);
				
				graphics.lineTo(triggerNode.drawToPointX(),triggerNode.drawToPointY());
				graphics.moveTo(0,0);
			}
		}
		//set whether or not this node is to be a trigger
		public function setPlaceTrig(trig:Boolean):void {
			this.isTrigPlace = trig;
		}
		// sets this node's trigger node
		public function setTrigger(trig:Node):void {
			this.triggerNode = trig;
		}
		
		public function getTrigPlace():Boolean {
			return this.isTrigPlace;
		}
		
		protected function TimeListener(e:TimerEvent):void	{
		//	if(placed)
			//	displaySolid();
		//		else
			//	displayFaded();
		}
		
		public function removeSibling(nod:Node):void {
			var int:Number;
			int = nodes.indexOf(nod);
			if(int != -1)
			{
				nodes[int] = nodes[nodes.length -1];
				nodes.pop();
				
				qValuesNoGold[int] = qValuesNoGold[qValuesNoGold.length -1];	// Remove corresponding Q value
				qValuesNoGold.pop();
			}
		}
		
		public function addSibling(nod:Node):void {
			nodes.push(nod);
			
			// Add a corresponding initial Q value for new path and enemy type
			var qValues:Array = new Array();
			var qValuesGold:Array = new Array();
			for(var i:int = 0; i < EnemyManager.getNumEnemyTypes(); i++) {	// Add an initial Q for each enemy type
				qValues.push(Node.initialQ);
				qValuesGold.push(Node.initialQ);
			}
			
			qValuesNoGold.push(qValues);
			qValuesWithGold.push(qValuesGold);
		}
		
		// Determines whether a path exists between nodes
		public function pathExists(n:Node):Boolean {
			return pathExistsRecursive(n,new Array());
		}
		// Discovers whether a path exists between this node and node n
		public function pathExistsRecursive(n:Node, visited:Array):Boolean {
			if(n == this) {
				return true;
			}
			else if(visited.indexOf(n) >= 0) {
				return false;
			}
			else { // Not yet visited
				visited.push(n);
				var pathExists:Boolean = false;
				for(var i:int = 0; i < n.getNumSiblings(); i++) {
					var exists:Boolean = pathExistsRecursive(n.getSibling(i),visited);
					if(exists) {
						pathExists = true;
						break;
					}
				}
				return pathExists;
			}
			
		}
		
		public function getNumSiblings():int {
			return nodes.length;
		}
		
		public function getSibling(index:int):Node {
			return (nodes[index] as Node);
		}
		
		protected function mouseMoveListener(e:MouseEvent):void {
			if(!placed)
			{
				x = e.stageX;
				y = e.stageY;
			}
		}
	}
}