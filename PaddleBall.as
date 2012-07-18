package {
	import flash.display.*;/**/
	import flash.events.*;
	import flash.net.*
	import flash.utils.getTimer;
	import flash.utils.Timer;
	import flash.geom.Rectangle;
	import flash.geom.Matrix;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.system.Security;
	import mochi.as3.*
	
	public dynamic class PaddleBall extends MovieClip {
		// level data
		static const numLevels:Number = 5;
		static var levelData:Array = new Array(numLevels);
		
		levelData[1] = [1,1,1,1,1,1,1,1,
						1,1,1,1,1,1,1,1,
						1,1,1,3,3,1,1,1,
						1,1,1,3,3,1,1,1,
						1,1,1,1,1,1,1,1,
						1,1,1,1,1,1,1,1];
		
		levelData[2] = [1,1,1,1,1,1,1,1,
						1,1,1,1,1,1,1,1,
						1,1,1,1,1,1,1,1,
						2,2,2,2,2,2,2,2,
						4,1,1,1,1,1,1,4,
						4,4,5,1,1,5,4,4];
		
		levelData[3] = 	[1,1,1,1,1,1,1,1,
						 1,1,1,1,1,1,1,1,
						 1,1,1,1,1,1,1,1,
						 4,1,1,1,1,1,1,4,
						 4,1,1,1,1,1,1,4,
						 4,4,4,4,4,4,4,4];
		
		levelData[4] = 	[1,1,1,1,1,1,1,1,
						 1,1,6,1,1,6,1,1,
						 1,1,6,1,1,6,1,1,
						 5,1,6,6,6,6,1,5,
						 5,1,1,1,1,1,1,5,
						 5,5,5,5,5,5,5,5];
		
		levelData[5] = 	[6,1,6,6,6,6,1,6,
						 6,2,6,4,4,6,2,6,
						 6,1,6,4,4,6,1,6,
						 6,1,5,1,1,5,1,6,
						 6,1,1,1,1,1,1,6,
						 6,6,6,6,6,6,6,6];
		
		//levelData[5] = 	[5,5,3,1,2,3,4,5]
		
		// environment constants 
		static const wallTop:Number = 0;
		static const wallLeft:Number = 0;
		static const wallRight:Number = 550;
		static const paddleY:Number = 380;
		static const standardWidth:Number = 90;
		static const longWidth:Number = 145;
		static const shortWidth:Number = 60;
		private const defaultBallSpeed:Number = 5;
		static const paddleCurve:Number = .005;
		static const paddleHeight:Number = 18;
		static const screenWidth:Number = 550;
		static const screenHeight:Number = 450;
				
		// key objects
		public var kongregate:*
		//for Mochi
		var o:Object = { n: [5, 9, 14, 8, 15, 7, 14, 5, 14, 13, 2, 9, 7, 15, 4, 1], f: function (i:Number,s:String):String { if (s.length == 16) return s; return this.f(i+1,s + this.n[i].toString(16));}};
		var boardID:String = o.f(0,"");
		
		static var music1 = new coriolisEffectBGMusic();
		static var music2 = new lookToLaLunaBGMusic();
		static var music3 = new stopBlueMixBGMusic();
		static var music4 = new dittoBGMusic();
		static var music5 = new odeTo1ashlBGMusic();
		static var musicChannel;
		static var currentLevel:int = 0;
		static var currentBackground:Bitmap;
		static var paddle:Paddle;
		static var paddleWidth:Number = 90; 
		static var ballSpeed:Number;
		var ballsLeft:Number; 
		public var score:int;
		public var multiplier:int;
		public var bricksBroken:int;
		public var gameComplete:int;
		static var gameInitialized:Boolean = false;
		static const numJugglers:int = 6; 
		static var juggleTimer:Array = new Array(numJugglers);  //delay in ms
		static var longestJuggle:Array = new Array(numJugglers); //how long you've juggled x number of balls this level
		static var gameLongestJuggle:Array = new Array(numJugglers); //longest juggles all game
		static var mostBalls:int;
		private var ball:Ball;
		
		// bricks
		//static var bricks:Array;
		
		// animation timer
		private var lastTime:uint;
		
		// number of balls left
		
		public function onConnectError(status:String):void {
			// handle error here...
			if(!gameInitialized) {initializeGame();}
		}  
		
		//constructor
		function PaddleBall() {
			gotoAndStop("blank");
			loadAPI();  // for Kongregate
		}
		
		function initializeGame() {
			gameInitialized = true;
			gotoAndStop("intro");
		}
		
		public function loadAPI(){
		  //Kongregate
		  var paramObj:Object = LoaderInfo(root.loaderInfo).parameters;
		  var api_url:String = paramObj.kongregate_api_path ||  "http://www.kongregate.com/flash/API_AS3_Local.swf";
		  Security.allowDomain(api_url);
		  var request:URLRequest = new URLRequest ( api_url );
		  var loader:Loader = new Loader();
		  loader.contentLoaderInfo.addEventListener ( Event.COMPLETE, apiLoadComplete );
		  loader.load(request);
		  this.addChild(loader);
		  
		 }
		public function apiLoadComplete( event:Event ):void {
			kongregate = event.target.content;
			kongregate.services.connect();
			submitStats();
			//Mochi
		  var _mochiads_game_id:String = "df14db52ad5a7ce8";
		  mochi.as3.MochiServices.connect(_mochiads_game_id, root, onConnectError);  
		  MochiAd.showPreGameAd({clip:root, id: _mochiads_game_id, res:"550x450", ad_finished: initializeGame });
			//initializeGame(); // can initialize after mochi ad
		}
		
		function submitStats() {
			kongregate.stats.submit("score", score);
			kongregate.stats.submit("bricksBroken", bricksBroken);
			if(longestJuggle[2]) {
				kongregate.stats.submit("longestJuggle2", (longestJuggle[2]/10).toString()+' seconds');
			}
			if(longestJuggle[3]) {
				kongregate.stats.submit("longestJuggle3", longestJuggle[3]/10);
			}
			if(longestJuggle[4]) {
				kongregate.stats.submit("longestJuggle4", longestJuggle[4]/10);
			}
			if(longestJuggle[5]) {
				kongregate.stats.submit("longestJuggle5", longestJuggle[5]/10);
			}
			if(longestJuggle[6]) {
				kongregate.stats.submit("longestJuggle6", longestJuggle[6]/10);
			}
			
			if(gameLongestJuggle[2]) {
				kongregate.stats.submit("gameLongestJuggle2", gameLongestJuggle[2]/10);
			}
			if(gameLongestJuggle[3]) {
				kongregate.stats.submit("gameLongestJuggle3", gameLongestJuggle[3]/10);
			}if(gameLongestJuggle[4]) {
				kongregate.stats.submit("gameLongestJuggle4", gameLongestJuggle[4]/10);
			}if(gameLongestJuggle[5]) {
				kongregate.stats.submit("gameLongestJuggle5", gameLongestJuggle[5]/10);
			}if(gameLongestJuggle[6]) {
				kongregate.stats.submit("gameLongestJuggle6", gameLongestJuggle[6]/10);
			}
			kongregate.stats.submit("mostBalls", mostBalls);
			kongregate.stats.submit("currentLevel", currentLevel);
			kongregate.stats.submit("gameComplete", gameComplete);
		}
		
		public function newGame() {
			currentLevel = 1;
			ballsLeft = 3;
			for(var i=0; i<=numJugglers; i++){
				gameLongestJuggle[i] = 0;
			}
			score = 0;
			bricksBroken = 0;
			mostBalls = 0;
			gameComplete = 0;
		}
		public function startPaddleBall() {
			gameMessage.text = "Click To Start";		
			lives.text = "Lives: "+ballsLeft;
			juggleDisplay.text = "";
			scoreDisplay.text = "Score: "+score.toString();
			startLevel();
		}
		
		public function startLevel() {
			loadBG(currentLevel);
			for(var i=0; i<=numJugglers; i++){
				longestJuggle[i] = 0;
			}
									
			// create paddle
			paddle = new Paddle();
			paddle.y = paddleY;
			setPaddle("standard");
			stage.addChild(paddle);
						
			// create bricks
			makeBricks();
			gameMessage.text = "Click To Start Level " + currentLevel.toString();
			if(currentLevel == numLevels) {
				gameMessage.text = "Click to Start Final Level";
			}
			
			// set up animation
			lastTime = 0;
			stage.addEventListener(Event.ENTER_FRAME,moveObjects);
			stage.addEventListener(MouseEvent.CLICK,newBall);
			
			if (musicChannel) { musicChannel.stop();}
			if(currentLevel == 1) { musicChannel = music1.play(0,1000);}
			if(currentLevel == 2) { musicChannel = music2.play(0,1000);}
			if(currentLevel == 3) { musicChannel = music2.play(0,1000);}
			if(currentLevel == 4) { musicChannel = music3.play(0,1000);}
			if(currentLevel == 5) { musicChannel = music3.play(0,1000);}
		}
		
		public function loadBG(level:Number) {
			if (currentBackground) {
				stage.removeChild(currentBackground);
			}
			var bgImage:BitmapData = new BitmapData(screenWidth, screenHeight);
			var tile:DisplayObject;
			if (level == -1) {
				tile = new bgVictory();
			} else if (level == 1) {
				tile = new bg1();
			} else if (level == 2){
				tile = new bg2();
			} else if (level == 3){
				tile = new bg3();
			} else if (level == 4){
				tile = new bg4();
			} else if (level == 5){
				tile = new bg5();
			} else if (level == 6){
				tile = new bg6();
			} else if (level == 7){
				tile = new bg7();
			}  
		
			for (var offset:Matrix = new Matrix(); offset.ty < screenHeight; offset.ty += tile.height)
				for (offset.tx = 0; offset.tx < screenWidth; offset.tx += tile.width)
					bgImage.draw(tile, offset);
			var background:Bitmap = new Bitmap(bgImage);
			stage.addChildAt(background,0);
			currentBackground = background;
		}
		public function makeBricks() {
			Brick.list = [];
			for(var y:uint=0;y<6;y++) {
				for(var x:uint=0;x<8;x++) {
					if(levelData[currentLevel][x+8*y]) {
						var newBrick:Brick = new Brick(this, int(levelData[currentLevel][x+8*y]));
					}
					// space them nicely
					newBrick.x = 60*x+65;
					newBrick.y = 22*y+50;
					stage.addChild(newBrick);
				}
			} 
		}
		
		public function newBall(event:Event) {
			// don't go here if there is already a ball
			if (ball != null) return;
			
			gameMessage.text = "";
			setPaddle("standard");

			// create ball, center it
			ball = new Ball(this);
			stage.addChild(ball);
			
			ballsLeft--;
			lives.text = "Lives: "+ballsLeft;
			
			// reset animation
			lastTime = 0;
		}
		
		public function moveObjects(event:Event) {
			movePaddle();
		}
		
		public function movePaddle() {
			// match horizontal value with the mouse
			var newX:Number = Math.min(wallRight-paddleWidth/2,
				Math.max(wallLeft+paddleWidth/2,
					mouseX));
			paddle.x = newX;
		}
		
		function nextBall() {
			if (ballsLeft > 0) {
				ball = null;
				lives.text = "Lives: "+ballsLeft;
				gameMessage.text = "Click For Next Ball";
			} else {
				ball = null;
				endGame();
			}
		}
		
		function gotoScores() {
			//clearStage();
			musicChannel = music5.play(0,1000);
			gotoAndStop("scores");
		}
		
		function endLevel() {
			updateScore(100000*currentLevel*currentLevel);
			clearStage();
			if(currentLevel >= numLevels){
				gameComplete = 1;
			}
			for (var i=1; i<=numJugglers; i++) {
				if(gameLongestJuggle[i]) {
					gameLongestJuggle[i] = Math.max(gameLongestJuggle[i], longestJuggle[i]);
				} else {
					gameLongestJuggle[i] = longestJuggle[i];
				}
			}
			submitStats();
			musicChannel.stop();
			gotoScores();
		}
		
		function nextLevel() {
			if(currentLevel <= numLevels){
				ballsLeft++;
				loadBG(currentLevel);
				startLevel();
			} else {
				loadBG(-1);
				victory();
			}
		}
		function displayScores() {
			levelCompletedMessage.text = "Level " + currentLevel.toString() + " Completed!";
			levelCompletedBonus.text = "Level Completion Bonus: " + (100000*currentLevel*currentLevel).toString();
			levelCompletionTime.text = "Time spent: " + longestJuggle[1]/10 + " seconds";
			if (longestJuggle[2]) {
				longestJuggle2.text = "2 Balls: " + longestJuggle[2]/10 + " seconds";
				juggleMultiplier2.text = longestJuggle[2]*100 + " x 4 = " + longestJuggle[2]*100*2*2;
				var lj2 = longestJuggle[2]*100;
				updateScore(lj2);
				trace(score);
			} else {
				longestJuggle2.text = "               none";
				juggleMultiplier2.text = "none";
			}
			if (longestJuggle[3]) {
				longestJuggle3.text = "3 Balls: " + longestJuggle[3]/10 + " seconds";
				juggleMultiplier3.text = longestJuggle[3]*100 + " x 9 = " + longestJuggle[3]*100*3*3;
				var lj3 = longestJuggle[3]*100;
				updateScore(lj3);
				trace(score);
			} else {
				longestJuggle3.text = "";
				juggleMultiplier3.text = "";
			}
			if (longestJuggle[4]) {
				longestJuggle4.text = "4 Balls: " + longestJuggle[4]/10 + " seconds";
				juggleMultiplier4.text = longestJuggle[4]*100 + " x 16 = " + longestJuggle[4]*100*4*4;
				var lj4 = longestJuggle[4]*100;
				updateScore(lj4);
				trace(score);
			} else {
				longestJuggle4.text = "";
				juggleMultiplier4.text = "";
			}
			if (longestJuggle[5]) {
				longestJuggle5.text = "5 Balls: " + longestJuggle[5]/10 + " seconds";
				juggleMultiplier5.text = longestJuggle[5]*100 + " x 25 = " + longestJuggle[5]*100*5*5;
				var lj5 = longestJuggle[5]*100;
				updateScore(lj5);
				trace(score);
			} else {
				longestJuggle5.text = "";
				juggleMultiplier5.text = "";
			}
			totalScoreDisplay.text = "Total Score: " + score;
			currentLevel++;
		}
		
		
		function clearStage() {
			stage.removeEventListener(Event.ENTER_FRAME,moveObjects);
			stage.removeEventListener(MouseEvent.CLICK,newBall);
			if (paddle) { stage.removeChild(paddle); }
			paddle = null;
			ballsLeft++;
			
			if (Brick.list) { Brick.clear(this); } // clear all bricks
			
			while (Ball.list.length > 0) {
				Ball.list[Ball.list.length-1].destroy();
			}
			ball = null;
			
			var len;
			while (PowerUp.list.length > 0) {
				len = PowerUp.list.length;
				if (PowerUp.list[len-1] is PowerUp) {
					PowerUp.list[len-1].destroy();
				} else {
					PowerUp.list.splice(len-1,1);
				}
			}
									
		}
		function victory() {
			clearStage();
			musicChannel.stop();
			musicChannel = music4.play(0,1000);
			gotoAndStop("victory");
		}
		
		function displayVictoryStuff() {
			longestJuggle3.text = "3 Balls:     ";
			longestJuggle4.text = "4 Balls:     ";
			longestJuggle5.text = "5 Balls:     ";
			longestJuggle6.text = "6 Balls:     ";
			if (gameLongestJuggle[3]) {
				juggleTime3.text = gameLongestJuggle[3]/10 + " seconds";
			} else {
				juggleTime3.text = "none";
			}
			if (gameLongestJuggle[4]) {
				juggleTime4.text = gameLongestJuggle[4]/10 + " seconds";
			} else {
				juggleTime4.text = "none";
			}
			if (gameLongestJuggle[5]) {
				juggleTime5.text = gameLongestJuggle[5]/10 + " seconds";
			} else {
				juggleTime5.text = "none";
			}
			if (gameLongestJuggle[6]) {
				juggleTime6.text = gameLongestJuggle[6]/10 + " seconds";
			} else {
				juggleTime6.text = "none";
			}
			mostBallsJuggled.text = mostBalls.toString();
			submitStats();
		}
		
		function endGame() {
			clearStage();
			submitStats();
			MochiScores.showLeaderboard({boardID: boardID, score: score, 
										onDisplay: function() {},
										onClose: function () {gotoAndStop("gameover");} });
			//gotoAndStop("gameover");
			
		}

		function updateScore(scr:int) {
			if (!multiplier) { multiplier = 1;} 
			score += scr*multiplier;
			if (scoreDisplay) { scoreDisplay.text = "Score: "+score.toString(); }

		}
		static function setPaddle(ilk:String){
			if (ilk == "standard") {
				paddleWidth = standardWidth;
				paddle.short.visible = false;
				paddle.long.visible = false;
				paddle.standard.visible = true;
			}
			else if (ilk == "short") {
				paddleWidth = shortWidth;
				paddle.short.visible = true;
				paddle.long.visible = false;
				paddle.standard.visible = false;
			}
			else if (ilk == "long") {
				paddleWidth = longWidth;
				paddle.short.visible = false;
				paddle.long.visible = true;
				paddle.standard.visible = false;
			}
			else {
				trace("Invalid paddle type");
			}
		}
	}
}