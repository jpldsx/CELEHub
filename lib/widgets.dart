import 'package:flutter/material.dart';
import 'config.dart';
import 'theme.dart';

// the soft indigo / cyan glow behind every page (like the website background)
class AppBackdrop extends StatelessWidget {
  final Widget child;
  const AppBackdrop({super.key, required this.child});

  Widget _glow(Color color, double size) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, const Color(0x00FFFFFF)]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(child: ColoredBox(color: C.bg)),
        Positioned(top: -150, right: -130, child: _glow(const Color(0x244F46E5), 440)),
        Positioned(top: -130, left: -150, child: _glow(const Color(0x2406B6D4), 400)),
        Positioned.fill(child: child),
      ],
    );
  }
}

// the CELEHub logo tile + name
class BrandMark extends StatelessWidget {
  final double size;
  const BrandMark({super.key, this.size = 1});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36 * size,
          height: 36 * size,
          decoration: BoxDecoration(
            gradient: C.logo,
            borderRadius: BorderRadius.circular(11 * size),
            boxShadow: const [BoxShadow(color: Color(0x594F46E5), blurRadius: 12, offset: Offset(0, 4))],
          ),
          child: Icon(Icons.school_rounded, color: Colors.white, size: 22 * size),
        ),
        SizedBox(width: 9 * size),
        Text('CELE', style: TextStyle(color: C.text, fontSize: 21 * size, fontWeight: FontWeight.w500)),
        ShaderMask(
          shaderCallback: (rect) => const LinearGradient(colors: [C.accent, Color(0xFF0369A1)]).createShader(rect),
          child: Text('Hub', style: TextStyle(color: Colors.white, fontSize: 21 * size, fontWeight: FontWeight.w800)),
        ),
      ],
    );
  }
}

// the big gradient banner at the top of a page
class HeroBanner extends StatelessWidget {
  final String title;
  final String subtitle;
  final String pill;
  const HeroBanner({super.key, required this.title, required this.subtitle, this.pill = ''});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.fromLTRB(18, 16, 14, 16),
      decoration: BoxDecoration(gradient: C.hero, borderRadius: BorderRadius.circular(C.radius), boxShadow: C.shadowMd),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                const SizedBox(height: 3),
                Text(subtitle, style: const TextStyle(color: Color(0xD9FFFFFF), fontSize: 13)),
              ],
            ),
          ),
          if (pill.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0x33FFFFFF),
                border: Border.all(color: const Color(0x59FFFFFF)),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(pill, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
            ),
        ],
      ),
    );
  }
}

// a small rounded tag, like .vtag on the website
class TagPill extends StatelessWidget {
  final String label;
  final bool muted;
  const TagPill(this.label, {super.key, this.muted = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(color: muted ? C.surface2 : C.accentSoft, borderRadius: BorderRadius.circular(999)),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: muted ? C.muted : C.accent, fontSize: 11.5, fontWeight: FontWeight.w700),
      ),
    );
  }
}

// the filter pills above the video list
class FilterPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const FilterPill({super.key, required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            gradient: selected ? C.logo : null,
            color: selected ? null : Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: selected ? Colors.transparent : C.border),
            boxShadow: selected ? C.shadowSm : null,
          ),
          child: Text(label, style: TextStyle(color: selected ? Colors.white : C.text, fontWeight: FontWeight.w600, fontSize: 13)),
        ),
      ),
    );
  }
}

// a white card with the website's border and shadow
class SoftCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets margin;
  final EdgeInsets padding;
  const SoftCard({
    super.key,
    required this.child,
    this.margin = const EdgeInsets.fromLTRB(16, 6, 16, 6),
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: C.surface,
        borderRadius: BorderRadius.circular(C.radius),
        border: Border.all(color: C.border),
        boxShadow: C.shadowSm,
      ),
      child: child,
    );
  }
}

// the picture of a video (or a branded placeholder while it loads / when there is none)
class VideoThumb extends StatelessWidget {
  final String url;
  const VideoThumb({super.key, required this.url});

  Widget _placeholder() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE0E4FB), Color(0xFFD6F3F8)],
        ),
      ),
      child: const Center(child: Icon(Icons.school_rounded, size: 44, color: Color(0x884F46E5))),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) return _placeholder();
    return Image.network(
      url,
      fit: BoxFit.cover,
      headers: {'Referer': '${Config.siteUrl}/', 'User-Agent': 'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 Chrome/124.0 Mobile Safari/537.36'},
      loadingBuilder: (c, child, progress) => progress == null ? child : _placeholder(),
      errorBuilder: (c, e, s) => _placeholder(),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String text;
  final Widget? trailing;
  const SectionTitle(this.text, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 4),
      child: Row(
        children: [
          Expanded(child: Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: C.text))),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String text;
  const EmptyState({super.key, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(color: C.accentSoft, shape: BoxShape.circle),
              child: Icon(icon, size: 34, color: C.accent),
            ),
            const SizedBox(height: 14),
            Text(text, textAlign: TextAlign.center, style: const TextStyle(color: C.muted, fontSize: 14, height: 1.4)),
          ],
        ),
      ),
    );
  }
}
