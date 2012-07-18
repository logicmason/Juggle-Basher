package  {
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.media.Sound;
	
	public class PowerUp extends MovieClip {
		var speed:Number;
		var ilk:Number;
		static var numIlks = 5;
		static var list:Array = [];
		var pb:PaddleBall;
		var s:Sound;
		
		public function PowerUp(paddle:PaddleBall) {
			pb = paddle;
			list.push(this);
			speed = 4;
			ilk = Math.floor(Math.random() * numIlks) + 1;
			setVisible();
			addEventListener("enterFrame", enterFrame);
		}
		function enterFrame(e:Event) {
			this.y += speed;
			if (this.y > PaddleBall.screenHeight) {
				destroy();
				return;
			}
			
			if(this.hitTestObject(PaddleBall.paddle)){
				if (ilk == 1) { //standard paddle
					PaddleBall.setPaddle("standard");
					pb.updateScore(100);
					var s = new powerUpSound();
					s.play();
				} else if (ilk == 2) { //short paddle
					PaddleBall.setPaddle("short");
					pb.updateScore(1000);
					s = new powerDownSound();
					s.play();
				} else if (ilk == 3) { //slow one ball
					Ball.list[0].setBallSpeed(4); 
					pb.updateScore(100);
					s = new slowSound();
					s.play();
				} else if (ilk == 4) { 
					PaddleBall.setPaddle("long");
					pb.updateScore(50);
					s = new powerUpSound();
					s.play();
				} else if (ilk == 5) { //extra ball
					var ball = new Ball(pb);
					stage.addChild(ball);
					s = new extraBallSound();
					s.play();
				} else {
					trace("Invalid power up type: " + ilk);
				}
				destroy();
			}
		}
		
		function setVisible() {
			if (ilk == 1) {
				standard.visible = true;
				short.visible = false;
				slow.visible = false;
				long.visible = false;
				balls.visible = false;
			} else if (ilk == 2) {
				standard.visible = false;
				short.visible = true;
				slow.visible = false;
				long.visible = false;
				balls.visible = false;
			} else if (ilk == 3) {
				standard.visible = false;
				short.visible = false;
				slow.visible = true;
				long.visible = false;
				balls.visible = false;
			} else if (ilk == 4) {
				standard.visible = false;
				short.visible = false;
				slow.visible = false;
				long.visible = true;
				balls.visible = false;
			} else if (ilk == 5) {
				standard.visible = false;
				short.visible = false;
				slow.visible = false;
				long.visible = false;
				balls.visible = true;
			} else if (ilk == 6) {
				//not implemented
			} else {trace("Invalid brick type: "+ilk);}
	}
		function destroy() {
			removeEventListener("enterFrame", enterFrame);
			for(var i in list){
				if(list[i] == this){
					delete list[i];
					list.splice(i,1);
				}
			}
			stage.removeChild(this);
		}
	}
	
}
