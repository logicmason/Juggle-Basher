package  {
	
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.geom.Rectangle;
	import flash.media.Sound;
	
	public class Brick extends MovieClip {
		var pb:PaddleBall;
		static var list:Array = [];
		static var unbreakables:Number = 0;
		var ilk:Number;
		static const numIlks:Number = 6;
		var hp:Number;
		static const height:int = 18;
		static const width:int = 54;
		
		public function Brick(paddle:PaddleBall, i:Number = 1) { 
			pb = paddle; // hook to instance of document class 
			ilk = i; // the type of brick
			hp = ilk;
			if (ilk == 6) {
				unbreakables++;
				hp = -1;
			}
			list.push(this);
			setVisible();
		}
		function destroy() {
			for (var i in list) {
				if (this == list[i]) {
					delete list[i];
					list.splice(i,1);
					pb.bricksBroken++;
				}
			}
			stage.removeChild(this);
		}
		static function clear(pb:PaddleBall) { // pb is a hook to instance of document class
			for (var i = list.length-1; i>=0; i--) {
				pb.stage.removeChild(list[i]);
				delete list[i];
				list.splice(i,1);
			}
			Brick.list = null;
			Brick.unbreakables = 0;
		}
		function setVisible() {
			if (ilk == 1) {
				type1.visible = true;
				type2.visible = false;
				type3.visible = false;
				type4.visible = false;
				type5.visible = false;
				type6.visible = false;
			} else if (ilk == 2) {
				type1.visible = false;
				type2.visible = true;
				type3.visible = false;
				type4.visible = false;
				type5.visible = false;
				type6.visible = false;
			} else if (ilk == 3) {
				type1.visible = false;
				type2.visible = false;
				type3.visible = true;
				type4.visible = false;
				type5.visible = false;
				type6.visible = false;
			} else if (ilk == 4) {
				type1.visible = false;
				type2.visible = false;
				type3.visible = false;
				type4.visible = true;
				type5.visible = false;
				type6.visible = false;
			} else if (ilk == 5) {
				type1.visible = false;
				type2.visible = false;
				type3.visible = false;
				type4.visible = false;
				type5.visible = true;
				type6.visible = false;
			} else if (ilk == 6) {
				type1.visible = false;
				type2.visible = false;
				type3.visible = false;
				type4.visible = false;
				type5.visible = false;
				type6.visible = true;
			} else {trace("Invalid brick type: "+ilk);}
	}
		function takeDamage() {
			var s:Sound;
			if (hp > 0) {
				hp -= 1;
				pb.updateScore(50);
				
				if (Math.random() > .65) {
					var pow = new PowerUp(pb);
					pow.x = this.x;
					pow.y = this.y;
					stage.addChild(pow);
				}
				if (hp < 1) {
					destroy();
					s = new breakSound();
					s.play();
				} 
				else {
					ilk = hp;
					setVisible();
					s = new hitSound();
					s.play();
				}
			}
			else {
				s = new unbreakableSound();
				s.play();
			}
		}
	}
}
