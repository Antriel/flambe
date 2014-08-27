//
// Flambe - Rapid game development
// https://github.com/aduros/flambe/blob/master/LICENSE.txt

package flambe.platform.flash;

import flambe.util.Assert;
import flash.Vector;
import flash.display.BitmapData;
import flash.geom.Point;
import flash.geom.Rectangle;

import haxe.io.Bytes;

import flambe.math.FMath;

class BitmapTextureRoot extends BasicAsset<BitmapTextureRoot>
    implements TextureRoot
{
    
    public var image(default, null) :BitmapData;
    public var width (default, null) :Int;
    public var height (default, null) :Int;

    public function new (image:BitmapData)
    {
        super();
        this.image = image.clone();
        this.width = image.width;
        this.height = image.height;
    }

    public function createTexture (width :Int, height :Int) :BitmapTexture
    {
        return new BitmapTexture(this, width, height);
    }

    public function readPixels (x :Int, y :Int, width :Int, height :Int) :Bytes
    {
        assertNotDisposed();
		return Bytes.ofData(image.getPixels(new Rectangle(x, y, width, height)));
    }

    public function writePixels (pixels :Bytes, x :Int, y :Int, sourceW :Int, sourceH :Int)
    {
        assertNotDisposed();
		
        image.setPixels(new Rectangle(x, y, sourceW, sourceH), pixels.getData());
        drawBorder(image, sourceW, sourceH);
    }

    public function getGraphics () :BitmapGraphics
    {
        assertNotDisposed();

        if (_graphics == null) {
            _graphics = new BitmapGraphics(image);
            //_graphics.onResize(width, height);
        }
        return _graphics;
    }

    override private function copyFrom (that :BitmapTextureRoot)
    {
        this.image = that.image;
        this.width = that.width;
        this.height = that.height;
        this._graphics = that._graphics;
    }

    override private function onDisposed ()
    {
        image.dispose();
        _graphics = null;
    }

    /**
     * Extends the right and bottom edge pixels of a bitmap. This is to prevent artifacts caused by
     * sampling the outer transparency when the edge pixels are sampled.
     */
    private static function drawBorder (bitmapData :BitmapData, width :Int, height :Int)
    {
        // Right edge
        bitmapData.copyPixels(bitmapData,
            new Rectangle(width-1, 0, 1, height), new Point(width, 0));

        // Bottom edge
        bitmapData.copyPixels(bitmapData,
            new Rectangle(0, height-1, width, 1), new Point(0, height));

        // Is a one pixel border enough?
    }

    private var _graphics :BitmapGraphics;
}
