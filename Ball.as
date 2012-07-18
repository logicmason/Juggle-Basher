package  {
	
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.geom.Rectangle;
	import flash.utils.Timer;
	import flash.media.Sound;
	
	public class Ball extends MovieClip {
		static var list:Array = [];
		const radius:Number = 9;
		var dx:Number;
		var dy:Number;
		var angle:Number;
		var speed:Number;
		var oldRect:Rectangle;
		var newRect:Rectangle;
		var paddleRect:Rectangle;
		var pb:PaddleBall;
		
		public function Ball(paddle:PaddleBall) {
			pb = paddle;
			list.push(this);
			x = (PaddleBall.screenWidth/2) + ((Math.random()-.5) * PaddleBall.screenWidth/2);
			y = 200;
			dx = 0;
			dy = 5;
			addEventListener("enterFrame", enterFrame);
			if (!PaddleBall.juggleTimer[list.length]) {
				PaddleBall.juggleTimer[list.length] = new Timer(100);
				PaddleBall.longestJuggle[list.length] = new int;
				PaddleBall.longestJuggle[list.length] = 0;
			}
			if (list.length > PaddleBall.mostBalls) { PaddleBall.mostBalls = list.length;}
			PaddleBall.juggleTimer[list.length].start();
			
		}
		function enterFrame(e:Event){
			var newX:Number = x + dx;
			var newY:Number = y + dy;
			var hitTop:int = 0;
			var hitBottom:int = 0;
			var hitLeft:int = 0;
			var hitRight:int =0;
			var len:int = list.length; //shorthand
			var s:Sound;
			
			pb.multiplier = list.length * list.length; //quad points for 2 balls, 9x for 3, etc
			if (list.length < 2) {
				pb.juggleDisplay.text = "";
			}	else {
				pb.juggleDisplay.text = "Juggling "+len.toString()+" balls: "+PaddleBall.juggleTimer[len].currentCount.toString()/10+" seconds!";
			}			
			oldRect = new Rectangle(x-radius, y-radius, radius*2, radius*2);
			newRect = new Rectangle(newX-radius, newY-radius, radius*2, radius*2);
			paddleRect = new Rectangle(PaddleBall.paddle.x-PaddleBall.paddleWidth/2, PaddleBall.paddle.y-PaddleBall.paddleHeight/2, PaddleBall.paddleWidth, PaddleBall.paddleHeight);
			
			if (newRect.top > 400) { // lose a ball
				s = new dieSound();
				s.play();
				destroy();
				if (list.length == 0){
					for (var j in PowerUp.list) {
						PowerUp.list[j].destroy();
					}
					pb.nextBall();
				} else {
					trace(list.length+" balls left");
				}
				
				
				return;
			} // top > 400
			
			// collision with paddle
			if (newRect.bottom >= paddleRect.top) {
				if (newRect.right > paddleRect.left) {
					if (newRect.left < paddleRect.right) {
						if (oldRect.bottom < paddleRect.top) {
							// bounce back
							newY -= 2*(newRect.bottom - paddleRect.top);
							speed = Math.sqrt(dx*dx + dy*dy);
							speed *= -1.005;  // speed up each hit
							// decide new angle
							angle = (newX-PaddleBall.paddle.x)*2/(PaddleBall.paddleWidth+radius*2);
							dy = Math.sqrt((speed*speed)/(angle*angle+1))*-1;
							dx = angle * dy * -1;
							s = new hitPaddleSound();
							s.play();
						}
						else if(newRect.top < paddleRect.bottom) {
							dx = (newX-PaddleBall.paddle.x)*PaddleBall.paddleCurve;
							s = new hitPaddleSound();
							s.play();
						}
					}
				}
			}
			// collision with top wall
			if (newRect.top < PaddleBall.wallTop) {
				newY += 2*(PaddleBall.wallTop - newRect.top);
				dy *= -1;
			}
			
			// collision with left wall
			if (newRect.left < PaddleBall.wallLeft) {
				newX += 2*(PaddleBall.wallLeft - newRect.left);
				dx *= -1;
			}
			
			// collision with right wall
			if (newRect.right > PaddleBall.wallRight) {
				newX += 2*(PaddleBall.wallRight - newRect.right);
				dx *= -1;
			}
			
			// collision with bricks
			var bricks:Array = Brick.list;
			for(var i in bricks) {
				
				// get brick rectangle
				var brickRect:Rectangle = bricks[i].getRect(pb);
				
				// is there a brick collision
				if (brickRect.intersects(newRect)) {
									
					if (oldRect.top > brickRect.bottom) {
						hitBottom++;
					} 
					if (oldRect.bottom < brickRect.top) {
						hitTop++;
					}
					if (oldRect.right < brickRect.left) {
						hitLeft++;
					} 
					if (oldRect.left > brickRect.right) {
						hitRight++;
					}
					if (hitTop == hitBottom) {
						hitTop = hitBottom = 0;
					}
					if (hitLeft == hitRight) {
						hitLeft = hitRight = 0;
					}
					if (hitTop > Math.max(hitBottom, hitLeft, hitRight)) {
						dy = Math.abs(dy) * -1;
						newY = brickRect.top-radius;
					} else if (hitBottom > Math.max(hitTop, hitLeft, hitRight)) {
						dy = Math.abs(dy) * 1;
						newY = brickRect.bottom+radius;
						//newY += 2*(brickRect.top - newRect.bottom);
					} else if (hitRight > Math.max(hitTop, hitBottom, hitLeft)) {
						newX = brickRect.right+radius;
						dx = Math.abs(dx)*1;
					} else if (hitLeft > Math.max(hitTop, hitBottom, hitRight)) {
						newX = brickRect.left-radius;
						dx = Math.abs(dx)*-1;  
					}	else { // an equal number or collisions from multiple sides
						speed = Math.sqrt(dx*dx + dy*dy);
						dx = hitRight - hitLeft;
						dy = hitBottom - hitTop;
						if (dx == 0 && dy == 0) { 
							dy = Math.random();
							dx = 1/2 - Math.random();
						}
						setBallSpeed(speed);
					}
										
					// damage the brick & speed up ball
					if (dx<7) { dx *= 1.005;}
					if (dy<7) {dy *= 1.005;}
					bricks[i].takeDamage();
					if ((bricks.length - Brick.unbreakables) < 1) {  //last brick broken; go to next level
						pb.endLevel();
					}
					
				}
			}
			
			//update position
			x = newX;
			y = newY;
		}
		
		function setBallSpeed(newSpeed:Number){
			var factor:Number;
			speed = Math.sqrt(dx*dx+ dy*dy);
			factor = Math.abs(newSpeed/speed);
			dx *= factor;
			dy *= factor;
			
		}
		
		function destroy() {
			PaddleBall.longestJuggle[list.length] = Math.max(PaddleBall.longestJuggle[list.length], PaddleBall.juggleTimer[list.length].currentCount);
			PaddleBall.juggleTimer[list.length].reset();
			
			removeEventListener("enterFrame", enterFrame);
			for (var i in list) {
				if (this == list[i]) {
					delete list[i];
					list.splice(i,1);
				}
			}
			stage.removeChild(this);
		}
	}
}
