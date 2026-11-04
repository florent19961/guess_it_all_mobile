import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../models/fiesta/modifier_catalog.dart';
import '../../models/fiesta/modifier_instance.dart';
import '../../models/fiesta/turn_effects.dart';
import '../../models/team.dart';
import '../../providers/game_provider.dart';
import '../../theme/app_theme.dart';
import 'modifier_badge.dart';

/// Écran avant le tour, Fiesta v2 (maquette `cartouches` B, variante a) :
/// zone « CE TOUR » (règles de manche, malus reçus, bonus allumés) puis
/// « RÉSERVE » (mes cartouches, bonus / malus). Toucher = activer ou
/// infliger ; appui long = explication. Sans défilement : la taille des
/// cercles s'adapte à la place ([_fit]).
class FiestaTurnZone extends StatefulWidget {
  final GameProvider provider;
  final GlobalKey thisTurnKey;
  final GlobalKey reserveKey;

  const FiestaTurnZone({
    required this.provider,
    required this.thisTurnKey,
    required this.reserveKey,
    super.key,
  });

  @override
  State<FiestaTurnZone> createState() => _FiestaTurnZoneState();
}

/// Ce que montre un cercle.
enum _Kind { rule, received, armed, reserve }

const _gap = 6.0;
const _maxSize = 50.0;
const _minSize = 36.0;

/// Entre deux rangées de « Ce tour » : place pour l'étiquette « manche ».
const _thisTurnRunSpacing = _gap + 6;
const _ink = AppColors.backgroundMain;

class _FiestaTurnZoneState extends State<FiestaTurnZone> {
  /// Clés des cercles « Ce tour » / « Réserve » d'un bonus, pour l'animation
  /// de passage d'une zone à l'autre.
  final _circleKeys = <String, GlobalKey>{};
  String? _flying;
  OverlayEntry? _snack;
  Timer? _snackTimer;

  GameProvider get _p => widget.provider;

  GlobalKey _keyOf(String slot) => _circleKeys.putIfAbsent(slot, GlobalKey.new);

  @override
  void dispose() {
    _snackTimer?.cancel();
    _snack?.remove();
    super.dispose();
  }

  // ---------- Actions ----------

  void _showSnack(String text) {
    _snackTimer?.cancel();
    _snack?.remove();
    final entry = OverlayEntry(
      builder: (context) => Positioned(
        left: 0,
        right: 0,
        bottom: 0,
        child: Material(
          color: AppColors.gray700,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Text(text,
                  style: AppTextStyles.bodySmall
                      .copyWith(fontSize: 14, color: Colors.white)),
            ),
          ),
        ),
      ),
    );
    _snack = entry;
    Overlay.of(context).insert(entry);
    _snackTimer = Timer(const Duration(seconds: 5), () {
      entry.remove();
      if (_snack == entry) _snack = null;
    });
  }

  String _name(String id) => modifierById(id)?.name ?? id;

  /// Toucher un cercle de la réserve.
  Future<void> _useReserve(Cartridge c, BuildContext circle) async {
    final name = _name(c.catalogId);
    if (c.blockedReason != null) {
      return _showSnack('$name : ${c.blockedReason}.');
    }
    if (c.left <= 0) return _showSnack('Plus de cartouche « $name ».');
    if (c.nature == ModifierNature.bonus) {
      return _moveBonus(c.catalogId, circle, to: 'on');
    }
    final targets = _p.targetsFor(c.catalogId);
    final target = _p.teams.length == 2
        ? targets.firstOrNull
        : await _pickTarget(c.catalogId, targets);
    if (target == null || !mounted) return;
    final refused = _p.inflictMalus(c.catalogId, target.id);
    if (refused != null) _showSnack(refused);
  }

  /// Allume / éteint un bonus, et le fait voler d'une zone à l'autre
  /// (~250 ms, sauf animations réduites).
  void _moveBonus(String id, BuildContext from, {required String to}) {
    final box = from.findRenderObject() as RenderBox?;
    final start = box?.localToGlobal(Offset.zero);
    _p.toggleBonus(id);
    if (start == null || MediaQuery.disableAnimationsOf(context)) return;
    setState(() => _flying = id);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final dest =
          _keyOf('$to-$id').currentContext?.findRenderObject() as RenderBox?;
      if (!mounted || dest == null || !dest.attached) {
        if (mounted) setState(() => _flying = null);
        return;
      }
      final end = dest.localToGlobal(Offset.zero);
      final size = dest.size.width;
      final c = Cartridge(id, left: 1);
      late OverlayEntry entry;
      entry = OverlayEntry(
        builder: (_) => TweenAnimationBuilder<Offset>(
          tween: Tween(begin: start, end: end),
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          onEnd: () {
            entry.remove();
            if (mounted) setState(() => _flying = null);
          },
          builder: (_, offset, child) =>
              Positioned(left: offset.dx, top: offset.dy, child: child!),
          child: IgnorePointer(
            child: _Circle(
                id: id,
                kind: to == 'on' ? _Kind.armed : _Kind.reserve,
                size: size,
                cartridge: c),
          ),
        ),
      );
      Overlay.of(context).insert(entry);
    });
  }

  Future<Team?> _pickTarget(String id, List<Team> targets) {
    final def = modifierById(id)!;
    return showModalBottomSheet<Team>(
      context: context,
      backgroundColor: AppColors.backgroundMain,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: AppColors.malus, width: 2),
      ),
      builder: (sheet) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Contre quelle équipe ?',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.subtitle(fontSize: 26)
                      .copyWith(shadows: const [])),
              const SizedBox(height: 4),
              Text('${modifierIcon(id)} ${def.name}',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.gray400)),
              const SizedBox(height: 14),
              for (final team in targets) ...[
                _TeamButton(
                  team: team,
                  color: AppColors.getTeamColor(_p.teams.indexOf(team)),
                  onTap: () => Navigator.of(sheet).pop(team),
                ),
                const SizedBox(height: 10),
              ],
              TextButton(
                onPressed: () => Navigator.of(sheet).pop(),
                child: Text('Annuler',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.gray400)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Appui long : la feuille « nom + explication », sans action.
  void _explain(String id, _Kind kind,
      {String? from, String? blockedReason, bool noSender = false}) {
    final def = modifierById(id)!;
    final color = kind == _Kind.rule ? Colors.white : modifierColor(def.nature);
    final hint = AppTextStyles.bodySmall.copyWith(color: AppColors.gray400);
    String capitalized(String s) => s[0].toUpperCase() + s.substring(1);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.backgroundMain,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: color, width: 2),
      ),
      builder: (sheet) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${modifierIcon(id)} ${def.name}',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.subtitle(fontSize: 26)
                      .copyWith(color: color)),
              if (from != null)
                Text('Reçu de l\'équipe $from', style: hint)
              else if (noSender)
                Text('Coup de pouce de l\'app', style: hint),
              if (kind == _Kind.rule)
                Text('Toute la manche, pour toutes les équipes', style: hint),
              if (blockedReason != null)
                Text(capitalized(blockedReason),
                    textAlign: TextAlign.center,
                    style: hint.copyWith(color: AppColors.warning)),
              const SizedBox(height: 10),
              Text(def.description,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySmall.copyWith(color: Colors.white)),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.of(sheet).pop(),
                child: Text('Compris',
                    style: AppTextStyles.bodySmall.copyWith(color: color)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- Mise en page ----------

  @override
  Widget build(BuildContext context) {
    final rules = _p.roundRulesThisTurn;
    final received = _p.receivedThisTurn;
    final armed = _p.bonusesThisTurn;
    final reserve = _p.reserve;
    final sent = _p.sentThisTurn;
    final bonus =
        reserve.where((c) => c.nature == ModifierNature.bonus).toList();
    final malus =
        reserve.where((c) => c.nature == ModifierNature.malus).toList();
    final me = _p.getCurrentTeam()?.id;
    final others = _p.teams.where((t) => t.id != me).toList();

    return LayoutBuilder(builder: (context, box) {
      final thisTurnCount = rules.length + received.length + armed.length;
      final (:size, :bonusWidth) = _fit(
        width: box.maxWidth,
        height: box.maxHeight,
        bonus: bonus.length,
        malus: malus.length,
        sent: sent.length,
        thisTurn: thisTurnCount,
      );

      final thisTurn = Container(
        key: widget.thisTurnKey,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _ink.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.gray700),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _ZoneTitle('CE TOUR'),
            const SizedBox(height: 10),
            if (thisTurnCount == 0)
              SizedBox(
                height: size,
                child: Center(
                  child: Text('Rien ce tour',
                      style: AppTextStyles.bodySmall
                          .copyWith(fontSize: 12, color: AppColors.gray500)),
                ),
              )
            else
              Wrap(
                spacing: _gap,
                runSpacing: _thisTurnRunSpacing,
                children: [
                  for (final m in rules)
                    _slot(
                        _Circle(id: m.catalogId, kind: _Kind.rule, size: size),
                        onLongPress: () => _explain(m.catalogId, _Kind.rule)),
                  for (final m in received)
                    _slot(
                        _Circle(
                            id: m.catalogId, kind: _Kind.received, size: size),
                        onLongPress: () => _explain(m.catalogId, _Kind.received,
                            from: m.fromTeamId == null
                                ? null
                                : _p.getTeamById(m.fromTeamId!)?.name,
                            noSender: m.fromTeamId == null)),
                  for (final id in armed)
                    _slot(
                      KeyedSubtree(
                        key: _keyOf('on-$id'),
                        child: Opacity(
                          opacity: _flying == id ? 0 : 1,
                          child: _Circle(id: id, kind: _Kind.armed, size: size),
                        ),
                      ),
                      onTap: (circle) =>
                          _p.reserve.any((c) => c.catalogId == id)
                              ? _moveBonus(id, circle, to: 'res')
                              : null,
                      onLongPress: () => _explain(id, _Kind.armed),
                    ),
                ],
              ),
          ],
        ),
      );

      if (reserve.isEmpty) {
        return Align(alignment: Alignment.topCenter, child: thisTurn);
      }

      Widget column(String title, List<Cartridge> items, Color color,
              {String? note}) =>
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text.rich(
                TextSpan(text: title, children: [
                  if (note != null)
                    TextSpan(
                        text: ' · $note',
                        style: const TextStyle(
                            letterSpacing: 0, fontWeight: FontWeight.w500)),
                ]),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                  color: color,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: _gap,
                runSpacing: _gap,
                children: [
                  for (final c in items)
                    _slot(
                      KeyedSubtree(
                        key: _keyOf('res-${c.catalogId}'),
                        child: Opacity(
                          opacity: _flying == c.catalogId ? 0 : 1,
                          child: _Circle(
                              id: c.catalogId,
                              kind: _Kind.reserve,
                              size: size,
                              cartridge: c),
                        ),
                      ),
                      onTap: (circle) => _useReserve(c, circle),
                      onLongPress: () => _explain(c.catalogId, _Kind.reserve,
                          blockedReason: c.blockedReason),
                    ),
                ],
              ),
            ],
          );

      final content = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          thisTurn,
          const SizedBox(height: 16),
          Column(
            key: widget.reserveKey,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _ZoneTitle('RÉSERVE'),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                      width: bonusWidth,
                      child: column('BONUS', bonus, AppColors.success)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: column('MALUS', malus, AppColors.malus,
                        note: others.length == 1 && malus.isNotEmpty
                            ? 'contre ${others.single.name}'
                            : null),
                  ),
                ],
              ),
            ],
          ),
          for (final m in sent) _sentLine(m),
          const SizedBox(height: 8),
          Text('Touche : activer · Appui long : explication',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall
                  .copyWith(fontSize: 11, color: AppColors.gray500)),
        ],
      );
      // Pas de défilement (spec) : [_fit] choisit le diamètre qui tient.
      return Align(alignment: Alignment.topCenter, child: content);
    });
  }

  Widget _sentLine(ModifierInstance m) {
    final index = _p.teams.indexWhere((t) => t.id == m.teamId);
    final style = AppTextStyles.bodySmall
        .copyWith(fontSize: 12, color: AppColors.gray400);
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Text('Envoyé : ', style: style),
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.malus, width: 1.5),
            ),
            child: Text(modifierIcon(m.catalogId),
                style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.malus)),
          ),
          Text(' → ', style: style),
          Flexible(
            child: Text(
              _p.getTeamById(m.teamId!)?.name ?? '',
              overflow: TextOverflow.ellipsis,
              style: style.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.getTeamColor(index < 0 ? 0 : index)),
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => _p.cancelSent(m),
            child: Text('Annuler',
                style: style.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.secondaryCyan)),
          ),
        ],
      ),
    );
  }

  /// Un cercle de « Ce tour » (marge entre cercles) ou de la réserve.
  Widget _slot(Widget circle,
          {void Function(BuildContext circle)? onTap,
          required VoidCallback onLongPress}) =>
      Builder(
        builder: (circleContext) => Semantics(
          button: onTap != null,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap == null ? null : () => onTap(circleContext),
            onLongPress: onLongPress,
            child: circle,
          ),
        ),
      );

  /// Plus grand diamètre (50 au plus, [_minSize] au moins) qui fait tenir la
  /// zone dans [height] : « Ce tour » (repliée sur plusieurs rangées s'il le
  /// faut), « Réserve » (deux colonnes repliées), lignes « Envoyé », aide.
  /// La colonne Bonus (3 cartouches au plus) prend la largeur qui minimise le
  /// nombre de rangées ; la colonne Malus, le reste.
  static ({double size, double bonusWidth}) _fit({
    required double width,
    required double height,
    required int bonus,
    required int malus,
    required int sent,
    required int thisTurn,
  }) {
    const minColumn = 64.0; // l'en-tête « BONUS » / « MALUS »
    int perRow(double space, double d) =>
        max(1, ((space + _gap) / (d + _gap)).floor());
    int rowsOf(int n, double space, double d) => (n / perRow(space, d)).ceil();
    ({int rows, double bonusWidth}) columns(double d) {
      var best = (rows: 1 << 30, bonusWidth: minColumn);
      for (var k = 1; k <= max(1, bonus); k++) {
        final w = max(minColumn, k * (d + _gap) - _gap);
        final rows = max(rowsOf(bonus, w, d), rowsOf(malus, width - 12 - w, d));
        if (rows < best.rows) best = (rows: rows, bonusWidth: w);
      }
      return best;
    }

    double needed(double d) {
      final thisTurnRows = max(1, rowsOf(thisTurn, width - 26, d));
      const thisTurnFixed = 12 + 18 + 10 + 12 + 2;
      const reserveTitle = 16 + 18 + 8;
      const columnTitle = 18 + 6;
      const help = 8 + 18;
      return thisTurnFixed +
          thisTurnRows * (d + _thisTurnRunSpacing) -
          _thisTurnRunSpacing +
          reserveTitle +
          columnTitle +
          columns(d).rows * (d + _gap) -
          _gap +
          sent * 30 +
          help;
    }

    var d = _maxSize;
    while (d > _minSize && needed(d) > height) {
      d -= 2;
    }
    return (size: d, bonusWidth: columns(d).bonusWidth);
  }
}

class _ZoneTitle extends StatelessWidget {
  final String text;

  const _ZoneTitle(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
          color: AppColors.gray400,
        ),
      );
}

/// Cercle d'icône (maquette `.circ`) : règle de manche (neutre, « manche »),
/// malus reçu (rouge plein, ↓), bonus allumé (vert plein, ✓), cartouche en
/// réserve (sombre à liseré, pastille du nombre restant ; grisé si épuisé ou
/// incompatible).
class _Circle extends StatelessWidget {
  final String id;
  final _Kind kind;
  final double size;
  final Cartridge? cartridge;

  const _Circle({
    required this.id,
    required this.kind,
    required this.size,
    this.cartridge,
  });

  @override
  Widget build(BuildContext context) {
    final nature = modifierById(id)?.nature ?? ModifierNature.malus;
    final rule = kind == _Kind.rule;
    final color = rule ? Colors.white : modifierColor(nature);
    final filled = kind == _Kind.armed || kind == _Kind.received;
    final c = cartridge;
    final dimmed = kind == _Kind.reserve && c != null && !c.usable;
    final ring = dimmed ? AppColors.gray600 : color;
    final scale = size / _maxSize;

    final Widget? corner = switch (kind) {
      // L'étiquette déborde du cercle quand il rapetisse.
      _Kind.rule => Positioned(
          bottom: -7,
          left: -12,
          right: -12,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: _ink,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.white),
              ),
              child: const Text('manche',
                  style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 9,
                      height: 1.33,
                      fontWeight: FontWeight.w600,
                      color: Colors.white)),
            ),
          ),
        ),
      _Kind.reserve when c != null => Positioned(
          top: -4,
          right: -4,
          child: Container(
            constraints: const BoxConstraints(minWidth: 18),
            height: 18,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: dimmed ? AppColors.gray600 : color,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Text(
              c.blockedReason != null ? '⊘' : '${max(0, c.left)}',
              style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  height: 1,
                  fontWeight: FontWeight.w700,
                  color: dimmed ? Colors.white : _ink),
            ),
          ),
        ),
      _Kind.armed || _Kind.received => Positioned(
          bottom: -4,
          right: -4,
          child: Container(
            width: 20,
            height: 20,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _ink,
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 2),
            ),
            child: Text(kind == _Kind.armed ? '✓' : '↓',
                style: TextStyle(
                    fontSize: 11,
                    height: 1,
                    fontWeight: FontWeight.w700,
                    color: color)),
          ),
        ),
      _ => null,
    };

    return Opacity(
      opacity: dimmed ? 0.35 : 1,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: filled
                    ? color
                    : rule
                        ? Colors.white.withValues(alpha: 0.08)
                        : _ink,
                border: Border.all(color: ring, width: 2),
              ),
              child: Text(
                modifierIcon(id),
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 17 * scale,
                  height: 1,
                  fontWeight: FontWeight.w700,
                  color: filled
                      ? _ink
                      : dimmed
                          ? AppColors.gray500
                          : color,
                ),
              ),
            ),
            if (corner != null) corner,
          ],
        ),
      ),
    );
  }
}

/// Carte d'équipe de la feuille « Contre quelle équipe ? » (style habituel
/// des cartes d'équipe : fond teinté, bordure, nom lisible sans ombre).
class _TeamButton extends StatelessWidget {
  final Team team;
  final Color color;
  final VoidCallback onTap;

  const _TeamButton(
      {required this.team, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color, width: 2),
          ),
          child: Text(
            team.name,
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'Bangers', fontSize: 24, color: color),
          ),
        ),
      );
}
