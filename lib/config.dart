// ======================================================================
//  CELEHub app settings  -  fill these in ONCE (3 lines), then push.
// ======================================================================
class Config {
  // Your website address, WITHOUT a slash at the end. Example: 'https://celehub.pages.dev'
  static const String siteUrl = 'https://celehub.pages.dev';

  // The PUBLIC Turnstile site key (the same one in TURNSTILE_SITE_KEY in js/app.js).
  static const String turnstileSiteKey = '0x4AAAAAAFpKqCM1A7KBd3mO';

  // Only if you use videos with an id like "lulu:CODE": your main host's embed address,
  // the same as MINITUBE_EMBED_BASE on the website. Leave '' if you don't have one.
  static const String embedBase = '';

  // Where under-18 visitors are sent (same as the website).
  static const String minorUrl = 'https://www.khanacademy.org/';

  // Support tab. Pictures are loaded from your website folder, e.g. 'img/qrph.png'.
  // Use PNG or JPG (not SVG). Leave '' to hide a picture.
  static const String accountName = 'OptiX ICT Solutions';
  static const String qrphImage = '';
  static const String instapayImage = '';
}
