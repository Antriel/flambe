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

    //public var nativeTexture (default, null) :flash.display3D.textures.Texture;

    public function new (image:BitmapData)
    {
        super();
        this.image = image.clone();
        this.width = image.width;
        this.height = image.height;
    }

    /*public function init (context3D :Context3D, optimizeForRenderToTexture :Bool)
    {
        assertNotDisposed();

        nativeTexture = context3D.createTexture(width, height, BGRA, optimizeForRenderToTexture);
    }*/

    public function createTexture (width :Int, height :Int) :BitmapTexture
    {
        return new BitmapTexture(this, width, height);
    }

    /*public function uploadBitmapData (bitmapData :BitmapData)
    {
        assertNotDisposed();

        if (width != bitmapData.width || height != bitmapData.height) {
            // Resize up to the next power of two, padding with transparent black
            var resized = new BitmapData(width, height, true, 0x00000000);
            resized.copyPixels(bitmapData, bitmapData.rect, new Point(0, 0));
            drawBorder(resized, bitmapData.width, bitmapData.height);
            nativeTexture.uploadFromBitmapData(resized);
            resized.dispose();

        } else {
            nativeTexture.uploadFromBitmapData(bitmapData);
        }
    }*/

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

    /*private function drawTexture (source :Stage3DTexture, destX :Int, destY :Int,
        sourceX :Int, sourceY :Int, sourceW :Int, sourceH :Int)
    {
        var scratch = new Vector<Float>(12, true);
        var x1 = destX;
        var y1 = destY;
        var x2 = destX + sourceW;
        var y2 = destY + sourceH;

        scratch[0] = x1;
        scratch[1] = y1;
        // scratch[2] = 0;

        scratch[3] = x2;
        scratch[4] = y1;
        // scratch[5] = 0;

        scratch[6] = x2;
        scratch[7] = y2;
        // scratch[8] = 0;

        scratch[9] = x1;
        scratch[10] = y2;
        // scratch[11] = 0;

        var ortho = new Matrix3D(Vector.ofArray([
            2/width, 0, 0, 0,
            0, -2/height, 0, 0,
            0, 0, -1, 0,
            -1, 1, 0, 1,
        ]));
        ortho.transformVectors(scratch, scratch);

        var offset = _renderer.batcher.prepareDrawTexture(this, Copy, null, source);
        var data = _renderer.batcher.data;
        var u1 = (source.rootX+sourceX) / source.root.width;
        var v1 = (source.rootY+sourceY) / source.root.height;
        var u2 = u1 + sourceW/source.root.width;
        var v2 = v1 + sourceH/source.root.height;

        data[  offset] = scratch[0];
        data[++offset] = scratch[1];
        data[++offset] = u1;
        data[++offset] = v1;
        data[++offset] = 1;

        data[++offset] = scratch[3];
        data[++offset] = scratch[4];
        data[++offset] = u2;
        data[++offset] = v1;
        data[++offset] = 1;

        data[++offset] = scratch[6];
        data[++offset] = scratch[7];
        data[++offset] = u2;
        data[++offset] = v2;
        data[++offset] = 1;

        data[++offset] = scratch[9];
        data[++offset] = scratch[10];
        data[++offset] = u1;
        data[++offset] = v2;
        data[++offset] = 1;
    }*/

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
