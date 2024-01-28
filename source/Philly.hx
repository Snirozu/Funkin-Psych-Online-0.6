package;

import flixel.util.FlxColor;
import flixel.sound.FlxSound;
import flixel.FlxG;
import flixel.group.FlxGroup;

class Philly extends FlxGroup
{
	var bg:BGSprite;
	var city:BGSprite;
	var phillyLightsColors:Array<FlxColor>;
	var phillyWindow:BGSprite;
	var phillyStreet:BGSprite;
	var phillyTrain:PhillyTrain;
	var curLight:Int = -1;

	public function new()
	{
		super();

		if(!ClientPrefs.lowQuality) {
			bg = new BGSprite('philly/sky', -100, 0, 0.1, 0.1);
			add(bg);
		}

		city = new BGSprite('philly/city', -10, 0, 0.3, 0.3);
		city.setGraphicSize(Std.int(city.width * 0.85));
		city.updateHitbox();
		add(city);

		phillyLightsColors = [0xFF31A2FD, 0xFF31FD8C, 0xFFFB33F5, 0xFFFD4531, 0xFFFBA633];
		phillyWindow = new BGSprite('philly/window', city.x, city.y, 0.3, 0.3);
		phillyWindow.setGraphicSize(Std.int(phillyWindow.width * 0.85));
		phillyWindow.updateHitbox();
		add(phillyWindow);
		phillyWindow.alpha = 0;

		if(!ClientPrefs.lowQuality) {
			var streetBehind:BGSprite = new BGSprite('philly/behindTrain', -40, 50);
			add(streetBehind);
		}

		phillyTrain = new PhillyTrain(2000, 360);
		add(phillyTrain);

		phillyStreet = new BGSprite('philly/street', -40, 50);
		add(phillyStreet);
	}

	override function update(elapsed:Float)
	{
		phillyWindow.alpha -= (Conductor.crochet / 1000) * FlxG.elapsed * 1.5;
	}

	public function beatHit(curBeat)
	{
		phillyTrain.beatHit(curBeat);
		if (curBeat % 4 == 0)
		{
			curLight = FlxG.random.int(0, phillyLightsColors.length - 1, [curLight]);
			phillyWindow.color = phillyLightsColors[curLight];
			phillyWindow.alpha = 1;
		}
	}

	function doFlash()
	{
		var color:FlxColor = FlxColor.WHITE;
		if(!ClientPrefs.flashing) color.alphaFloat = 0.5;

		FlxG.camera.flash(color, 0.15, null, true);
	}
}

class PhillyTrain extends BGSprite {
	public var sound:FlxSound;

	public function new(x:Float = 0, y:Float = 0, image:String = 'philly/train', sound:String = 'train_passes') {
		super(image, x, y);
		active = true; // Allow update
		antialiasing = online.Wrapper.prefAntialiasing;

		this.sound = new FlxSound().loadEmbedded(Paths.sound(sound));
		FlxG.sound.list.add(this.sound);
	}

	public var moving:Bool = false;
	public var finishing:Bool = false;
	public var startedMoving:Bool = false;
	public var frameTiming:Float = 0; // Simulates 24fps cap

	public var cars:Int = 8;
	public var cooldown:Int = 0;

	override function update(elapsed:Float) {
		if (moving) {
			frameTiming += elapsed;
			if (frameTiming >= 1 / 24) {
				if (sound.time >= 4700) {
					startedMoving = true;
					if (PlayState.instance?.gf != null) {
						PlayState.instance.gf.playAnim('hairBlow');
						PlayState.instance.gf.specialAnim = true;
					}
				}

				if (startedMoving) {
					x -= 400;
					if (x < -2000 && !finishing) {
						x = -1150;
						cars -= 1;

						if (cars <= 0)
							finishing = true;
					}

					if (x < -4000 && finishing)
						restart();
				}
				frameTiming = 0;
			}
		}
		super.update(elapsed);
	}

	public function beatHit(curBeat:Int):Void {
		if (!moving)
			cooldown += 1;

		if (curBeat % 8 == 4 && FlxG.random.bool(30) && !moving && cooldown > 8) {
			cooldown = FlxG.random.int(-4, 0);
			start();
		}
	}

	public function start():Void {
		moving = true;
		if (!sound.playing)
			sound.play(true);
	}

	public function restart():Void {
		if (PlayState.instance?.gf != null) {
			PlayState.instance.gf.danced = false; // Makes she bop her head to the correct side once the animation ends
			PlayState.instance.gf.playAnim('hairFall');
			PlayState.instance.gf.specialAnim = true;
		}
		x = FlxG.width + 200;
		moving = false;
		cars = 8;
		finishing = false;
		startedMoving = false;
	}
}