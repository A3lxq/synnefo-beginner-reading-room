<?php
// Generates three small, genuinely-valid placeholder JPEG cover images
// (no external assets needed) so steghide has real JPEG data to embed
// payload into for ledgers_of_dust.jpg.
$dir = '/var/www/html/images';
$covers = [
    'quiet_archivist.jpg' => [60, 60, 90],
    'ledgers_of_dust.jpg' => [90, 70, 40],
    'ferrymans_toll.jpg' => [30, 30, 40],
];
foreach ($covers as $file => [$r, $g, $b]) {
    $im = imagecreatetruecolor(400, 300);
    imagefill($im, 0, 0, imagecolorallocate($im, $r, $g, $b));
    for ($i = 0; $i < 12; $i++) {
        imagesetpixel($im, rand(0, 399), rand(0, 299), imagecolorallocate($im, rand(0,255), rand(0,255), rand(0,255)));
    }
    imagejpeg($im, "$dir/$file", 90);
    imagedestroy($im);
}
echo "Covers generated.\n";
