package EgyptianInvasion
{
	import assets.*;
	
	import flash.display.*;
	import flash.events.*;
	
	public class Main extends Sprite {

		private var building:Boolean;	// indicates if game is in the building phase
		
		private var tombNode:Node; // End Node
		private var enterNode:Node; // Start Node
		private var allNodes:Array;

		private var selectedNode:Node;	// existing node that is "selected"
		private var toggledNode:Node;	// new node being placed
		private var cantSet:Boolean;
		
		private var placeNodeButton:Button;
		private var beginInvasionButton:Button;
		
		public function Main () {
			// Start in building phase
			this.building = true;
			
			allNodes = new Array();
			var bg:MovieClip = new BackgroundTest();
			bg.scaleX = 0.7;
			bg.scaleY = 0.7;
			bg.x = 200;
			bg.y = 200;
			this.addChild(bg);
			
			placeNodeButton = new Button(new assets.ToggleButton(), 50,100, "Add Node",stage);
			placeNodeButton.setMouseDown(Node.addNodeHandler);
			this.addChild(placeNodeButton);
			
			var changeNodeButton:Button = new Button(new assets.ToggleButton(), 0,50, "Change Node",stage);
			this.addChild(changeNodeButton);
			
			beginInvasionButton = new Button(new assets.BeginInvasionButton(), 200, 400, "", stage);
			this.addChild(beginInvasionButton);
			
			stage.frameRate = 100;
			stage.addEventListener(MouseEvent.MOUSE_DOWN, mouseDownListener);
			stage.addEventListener(MouseEvent.MOUSE_UP, mouseUpListener);
			stage.addEventListener(KeyboardEvent.KEY_DOWN,aListener);
			
			var baseNode:Node = new Node(70,70,stage);
			allNodes.push(baseNode);
			selectedNode = baseNode;
			baseNode.setSelected(true);
			enterNode = baseNode;
			baseNode.setPlaced(true);
			
			var finalNode:Node = new Node(300,200,stage);
			tombNode = finalNode;
			allNodes.push(tombNode);
			this.addChild(baseNode);
			this.addChild(finalNode);
			tombNode.setPlaced(true);
			
			
			var enemy:Enemy = new Enemy(enterNode,stage);
			this.addChild(enemy);
		}
		
		public function setToggledNode(node:Node):void {
			this.toggledNode = node;
		}
		
		public function addNode(toggle:Node):void
		{
			toggledNode = toggle;
			toggledNode.addSibling(selectedNode);
			selectedNode.addSibling(toggledNode);
			toggledNode.setPlaced(false);
			this.addChild(toggledNode);
			cantSet = true;
		}
		
		private function mouseDownListener (e:MouseEvent):void {
			if(toggledNode == null || cantSet)
			{
				var count:Number;
				count = 0;
				while(count < allNodes.length)
				{
					if(Math.sqrt(Math.pow((e.stageX -(allNodes[count] as Node).x),2) +
						Math.pow((e.stageY -(allNodes[count] as Node).y),2)) < 10)
					{
						selectedNode.setSelected(false);
						selectedNode = allNodes[count];
						selectedNode.setSelected(true);
					}
					count++;
				}
			}
			else
			{
				var potentialNode:Node;
				count = 0;
				while(count < allNodes.length)
				{
					if(Math.sqrt(Math.pow((e.stageX -(allNodes[count] as Node).x),2) +
						Math.pow((e.stageY -(allNodes[count] as Node).y),2)) < 10)
						potentialNode = allNodes[count];
					count++;
				}
				if(potentialNode == null)
				{
					toggledNode.setPlaced(true);
					allNodes.push(toggledNode);
				}
				else
				{
					potentialNode.addSibling(selectedNode);
					selectedNode.addSibling(potentialNode);
					this.removeChild(toggledNode);
					selectedNode.removeSibling(toggledNode);
				}
				toggledNode = null;
				placeNodeButton.setDown(false);
			}
			
		}
		
		private function aListener(e:KeyboardEvent):void
		{
			if(e.charCode == 97)
			{
				toggledNode = new Node(0,0,stage);
				toggledNode.addSibling(selectedNode);
				selectedNode.addSibling(toggledNode);
				toggledNode.setPlaced(false);
				this.addChild(toggledNode);
			}
		}
		
		private function mouseUpListener (e:MouseEvent):void {
			cantSet = false;
		}
		
	}
}