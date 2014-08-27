//
// Flambe - Rapid game development
// https://github.com/aduros/flambe/blob/master/LICENSE.txt

package flambe.platform.flash;
import flash.geom.Point;
import flash.display.BitmapData;
import flash.geom.Rectangle;

class BitmapTexture extends BasicTexture<BitmapTextureRoot> {
	
	public var image:BitmapData;
	
    public function new(root:BitmapTextureRoot, width:Int, height:Int) {
        super(root, width, height);
		image = root.image;
    }
	
	public override function subTexture(x:Int, y:Int, width:Int, height:Int):BitmapTexture {
        var sub:BitmapTexture = root.createTexture(width, height);
        sub._parent = this;
        sub._x = x;
        sub._y = y;
        sub.rootX = rootX + x;
        sub.rootY = rootY + y;
		sub.image = new BitmapData(width, height, true, 0);
		sub.image.copyPixels(root.image, getRect(sub.rootX, sub.rootY, width, height), _zeroPoint, null, null, true);
        return sub;
    }
	
	private static var _tempRect:Rectangle = new Rectangle();
	private static var _zeroPoint:Point = new Point();
	
	private static inline function getRect(x:Int, y:Int, width:Int, height:Int):Rectangle {
		_tempRect.setTo(x, y, width, height);
		return _tempRect;
	}
	
}
